//
//  ShotClockView.swift
//  Shot Clock Cue Score
//
//  Created by Owner on 27/03/2025.
//

import Foundation
import SwiftUI
import AVFoundation
import Speech
import WebKit

struct ShotClockCuescoreView: View {
    
    @Environment(GameModel.self) private var gameModel
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @State private var opacity = 0.0
    
    @State private var webView: WKWebView = WKWebView()
    @StateObject private var apiManager = APIManager()
    @State private var JSONResponseSaved = ""
    
    @State private var player1ButtonUp = false
    @State private var player1ButtonDown = false
    @State private var player2ButtonUp = false
    @State private var player2ButtonDown = false
    @State private var closeGame = false
    @State private var gameOver = false
    @State private var multipleScoreChange = false
    @State private var integerInput: String = ""
    
    @State private var finishMatchBoolean = false
    @State private var nextSetBoolean = false
    @State private var deleteSetBoolean = false
    
    @State private var soundPlayer: AVAudioPlayer?
    @State private var soundPlayer2: AVAudioPlayer?
    @State private var soundPlayer3: AVAudioPlayer?
    
    @State private var showingScoreboard = true
    @State private var showReadyAlert = true
    @State private var firstShotAlert = true
    @State private var pauseTimer = true
    @State private var pauseMatchTimer = false
    @State private var invalidateTimer = true
    @State private var isFirstShot = true
    @State private var extension1Pressed = false
    @State private var extension2Pressed = false
    @State private var extensionPressedThisShot = false
    @State private var pushOutPressed = false
    @State private var timerAdded = false
    @State private var timeFoul = false
    @State private var shotClockTextColor = Color.black
    @State private var player1Selected = true
    
    @State private var isRecording = true
    @State private var detectedWords: [String] = []
    
    let buttonPadding = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 5)
    let framesPadding = EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
    let actionButtonPadding = EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 20)
    let playerSectionMulitiplier = 0.26
    let scoreButtonDiameterMulitplier = 0.08
    let showScoreBoardButtonDiameterDivisor = 16.0
    let timerInterval:Float = 1.0
    
    @State private var showLoading = false
    @State private var tableId = ""
    @State private var code = ""
    
    @State private var refreshDelay = 1.0
    @State private var refreshBounce = false
    @State private var rotate = false
    @State private var rotationAngle = 0.0
    
    @StateObject var networkMonitor = NetworkMonitor()
    let layoutProperties:LayoutProperties
    
    var body: some View {
        
        VStack {
            WebView(url: URL(string: "https://cuescore.com/scoreboard/?code=\(gameModel.tournamentCode)")!) { extractedTableId, extractedCode in
                withAnimation{
                    self.tableId = extractedTableId ?? ""
                    self.code = extractedCode ?? ""
                    loadWebPage()
                }
            }
            .frame(width: 0, height: 0)
            .opacity(0)
            .navigationBarBackButtonHidden(!(tableId.isEmpty || code.isEmpty || !networkMonitor.isConnected))
            
            if tableId.isEmpty || code.isEmpty || !networkMonitor.isConnected {
                shotClockSplashScreen()
            } else {
                
                let timer = Timer(timeInterval: TimeInterval(timerInterval), repeats: true, block: {
                    _ in
                    tickTimer()
                })
                
                HStack(spacing: 0) {
                    Color.black
                        .ignoresSafeArea()
                        .frame(width: layoutProperties.width/115, height: layoutProperties.height)
                    if (showingScoreboard) {
                        VStack(alignment: .center, spacing:0) {
                            ZStack {
                                Player1Background()
                                Player1Content()
                            }
                            
                            Color.black
                                .frame(height: layoutProperties.height/50)
                            
                            ZStack {
                                Player2Background()
                                Player2Content()
                            }
                            .frame(height: layoutProperties.height*49/100)
                            Color.black
                                .ignoresSafeArea()
                        }
                        .frame(width: layoutProperties.width*playerSectionMulitiplier)
                        
                    } else {
                        HideScoreboardView()
                            .background(.black)
                    }
                    
                    Color.black.ignoresSafeArea().frame(width: layoutProperties.width/115, height: layoutProperties.height)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            OptionsButton()
                            Spacer()
                            if showingScoreboard {
                                HideScoreBoardButton()
                                Spacer()
                            }
                            PushOutButton()
                        }
                        Spacer()
                        ZStack {
                            ShotClockCircle()
                            if gameModel.matchTimerEnabled {
                                MatchTimer()
                            }
                        }
                        Spacer()
                        VStack {
                            RefreshDataButton()
                            Spacer()
                            PauseButton()
                        }
                        .padding(20)
                    }
                }
                .ignoresSafeArea(edges: [.top, .bottom])
                .navigationBarBackButtonHidden(networkMonitor.isConnected)
                .onAppear {
                    UIApplication.shared.isIdleTimerDisabled = true
                    shotClockTextColor = .white
                    showReadyAlert = true
                    
                    if !timerAdded {
                        RunLoop.main.add(timer, forMode: .default)
                        timerAdded = true
                    }
                    
                    guard let soundURL = Bundle.main.url(forResource: "beep", withExtension: "mp3") else { return }
                    guard let soundURL2 = Bundle.main.url(forResource: "extensionsound", withExtension: "mp3") else { return }
                    guard let soundURL3 = Bundle.main.url(forResource: "warning10sec", withExtension: "mp3") else { return }
                    setUpSounds(soundURL, soundURL2, soundURL3)
                    
                }
                .onDisappear {
                    invalidateTimer = true
                    UIApplication.shared.isIdleTimerDisabled = false
                    AppDelegate.orientationLock = .all
                }
                .alert("Ready?", isPresented: $showReadyAlert, presenting: gameModel, actions: { _ in Button("OK") { showReadyAlert = false; invalidateTimer = false } }, message: { _ in })
                .alert("First Shot?", isPresented: $firstShotAlert, presenting: gameModel, actions: {
                    _ in
                    Button(gameModel.player1Name) {
                        player1Selected = true
                        firstShotAlert = false
                    }
                    Button(gameModel.player2Name) {
                        player1Selected = false
                        firstShotAlert = false
                    }
                }, message: {
                    _ in
                    Text("Who's turn is it after the break?")
                })
                .alert("Time Foul", isPresented: $timeFoul, presenting: gameModel, actions: {
                    _ in
                    Button("Continue") {
                        continueFromTimeFoul()
                    }
                }, message: { _ in Text("Press Continue to reset the shot clock") })
                .alert("Game Over!", isPresented: $gameOver, presenting: gameModel, actions: { _ in Button("Back to Match Details") {
                    resetGame()
                } }, message: { _ in })
            }
        }
        .background(.black)
//        .navigationBarBackButtonHidden()
    }
    
    func playExtensionSound() {
        soundPlayer2?.play()
    }
    
    func tickTimer() {
        if runTimerConditions() {
            withAnimation(.linear(duration:0.3)) {
                gameModel.currentTimer -= timerInterval
                timerSounds()
            }
        }
        
        if gameModel.matchTimerEnabled && !pauseMatchTimer && gameModel.matchTimeLeft > 0 && !invalidateTimer && !showReadyAlert {
            gameModel.matchTimeLeft -= 1
            if gameModel.matchTimeLeft == 0 {
                gameOver = true
            }
        }
    }
    
    func timerSounds() {
        
        if gameModel.currentTimer == 10 {
            soundPlayer3?.play()
        } else if gameModel.currentTimer == 0  {
            timeFoul = true
            soundPlayer?.play()
            player1Selected.toggle()
        } else if gameModel.currentTimer < 6 {
            soundPlayer?.stop()
            soundPlayer?.play()
        }
        
    }
    
    func continueFromTimeFoul() {
        shotClockPressed()
        timeFoul = false
        showReadyAlert = true
    }
    
    func runTimerConditions() -> Bool {
        return (gameModel.currentTimer > 0) && (!showReadyAlert) && (!pauseTimer) && (!invalidateTimer) && (!timeFoul)
        //                return (gameModel.currentTimer > 0) && (!showReadyAlert) && (!pauseTimer) && (!invalidateTimer) && (!timeFoul) && !cameraViewController.ballsMoving
    }
    
    func setShotClockColor(currentTimer:Float) -> Color {
        if currentTimer < 6 {
            return Color.red
        } else if currentTimer < 11 {
            return Color.yellow
        } else {
            return Color.green
        }
    }
    
    func shotClockPressed() {
        isFirstShot = false
        extensionPressedThisShot = false
        resetCurrentTimer()
        setShotTime()
    }
    
    func resetCurrentTimer() {
        gameModel.currentTimer = (isFirstShot && gameModel.doubleFirstShot) ? Float(gameModel.shotClockValue)*2.0:Float(gameModel.shotClockValue)
        pauseTimer = true
    }
    
    func setShotTime() {
        if (isFirstShot && gameModel.doubleFirstShot) {
            gameModel.shotTime = gameModel.shotClockValue * 2
        } else {
            gameModel.shotTime = gameModel.shotClockValue
        }
        if extensionPressedThisShot {
            gameModel.shotTime = Int(gameModel.currentTimer) + gameModel.extensionValue
        }
    }
    
    func addExtensionTime() {
        
        extensionPressedThisShot = true
        
        withAnimation(.smooth(duration: 0.7)) {
            invalidateTimer.toggle()
            shotClockTextColor = .green
            setShotTime()
            gameModel.currentTimer += Float(gameModel.extensionValue)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            invalidateTimer.toggle()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            shotClockTextColor = .white
        }
    }
    
    func framesChanged(_ playerFrames: inout Int, _ playerSets: inout Int, _ playerButton: inout Bool) {
        
        let adder = playerButton ? 1:-1
        playerFrames = max(playerFrames+adder, 0)
        
        if playerFrames < gameModel.matchFrames {
            resetFrame()
        } else {
            playerSets += 1
            resetFrame()
            gameModel.player1Frames = 0
            gameModel.player2Frames = 0
            playerFrames = 0
        }
        
        if playerSets == gameModel.matchSets {
            gameOver = true
        }
        
    }
    
    func resetFrame() {
        
        extension1Pressed = false
        extension2Pressed = false
        extensionPressedThisShot = false
        isFirstShot = true
        pushOutPressed = false
        
        resetCurrentTimer()
        setShotTime()
        firstShotAlert = true
        
    }
    
    func resetGame() {
        
        extension1Pressed = false
        extension2Pressed = false
        extensionPressedThisShot = false
        isFirstShot = true
        pushOutPressed = false
        invalidateTimer = true
        resetCurrentTimer()
        setShotTime()
        
        gameModel.player1Name = ""
        gameModel.player2Name = ""
        gameModel.player1Frames = 0
        gameModel.player2Frames = 0
        gameModel.player1Sets = 0
        gameModel.player2Sets = 0
        gameModel.matchTimeLeft = gameModel.matchTime
        
        self.presentationMode.wrappedValue.dismiss()
        
    }
    
    func Player1Background() -> some View {
        return Image("redBG")
            .resizable()
            .opacity(player1Selected ? 1:0.05)
            .onTapGesture {
                if !player1Selected {
                    shotClockPressed()
                }
                player1Selected = true
            }
    }
    
    func Player1SetsScoreAndLabel() -> VStack<TupleView<(Text, Text)>> {
        return VStack {
            Text(String(gameModel.player1Sets))
                .font(.title)
                .foregroundStyle(.yellow)
                .bold()
            Text("Sets")
                .font(.body)
                .foregroundStyle(.yellow)
        }
    }
    
    func Player1Name() -> some View {
        return Text(gameModel.player1Name)
            .font(.largeTitle)
            .foregroundStyle(.white)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
    }
    
    func Player1FramesScoreAndLabel() -> some View {
        
        let textWidth:CGFloat = layoutProperties.width/17
        
        return VStack {
            Text(String(gameModel.player1Frames))
                .font(.system(size: textWidth))
                .foregroundStyle(.white)
                .bold()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            
            Text("Frames")
                .font(.body)
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .padding(framesPadding)
    }
    
    func Player1ExtensionButton() -> some View {
        return Button(action: {
            
            playExtensionSound()
            addExtensionTime()
            extension1Pressed = true
        }, label: {
            Text("EXT")
                .foregroundStyle(extension1Pressed ? .gray:.green)
                .font(.title3)
                .fontWeight(.heavy)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .symbolEffect(.bounce.up, value: extension1Pressed)
        })
        .disabled(extension1Pressed || extensionPressedThisShot || pauseTimer || !player1Selected)
    }
    
    func Player1UpButton() -> some View {
        return Image.init(systemName: "chevron.up.circle.fill")
            .resizable()
            .disabled(!player1Selected)
            .frame(width:layoutProperties.height*scoreButtonDiameterMulitplier, height: layoutProperties.height*scoreButtonDiameterMulitplier)
            .scaledToFit()
            .symbolEffect(.bounce.up, value: player1ButtonUp)
            .onTapGesture {
                if player1Selected {
                    player1ButtonUp.toggle()
                }
            }
            .onLongPressGesture(perform: {
                    if player1Selected {
                        multipleScoreChange = true
                    }
            })
            .foregroundStyle(.cyan)
            .alert("Increase "+gameModel.player1Name+"'s Score?", isPresented: $player1ButtonUp, presenting: gameModel) { gameModel in
                Button("Yes") {
                    scoreChange(forPlayer: "playerA", changeBy: 1)
                    resetFrame()
                    player1ButtonUp.toggle()
                }
                
                Button("Cancel") {
                    player1ButtonUp.toggle()
                }
            } message: {_ in }
            .alert("Enter an Integer", isPresented: $multipleScoreChange) {
                TextField("How much do you want to change the score by?", text: $integerInput)
                    .keyboardType(.numberPad)
                    .onChange(of: integerInput) { _,newValue in
                        // Filter non-numeric characters
                        integerInput = newValue.filter { $0.isNumber }
                    }
                Button("OK") {
                    scoreChange(forPlayer: "playerA", changeBy: Int(integerInput) ?? 0)
                    multipleScoreChange = false
                }
                Button("Cancel", role: .cancel) {
                    multipleScoreChange = false}
            } message: {
                Text("Integer only")
            }
            .alert("Finish Match?", isPresented: $finishMatchBoolean, presenting: gameModel) { gameModel in
                Button("Yes") {
                    finishMatch()
                    finishMatchBoolean = false
                }
                
                Button("Cancel") {
                    finishMatchBoolean = false
                }
            } message: {_ in }
            .alert("Finish Set?", isPresented: $nextSetBoolean, presenting: gameModel) { gameModel in
                Button("Yes") {
                    nextSet()
                    resetFrame()
                    nextSetBoolean = false
                }
                
                Button("Cancel") {
                    nextSetBoolean = false
                }
            } message: {_ in }
            .alert("Delete Set?", isPresented: $deleteSetBoolean, presenting: gameModel) { gameModel in
                Button("Yes") {
                    deleteSet()
                    resetFrame()
                    deleteSetBoolean = false
                }
                
                Button("Cancel") {
                    deleteSetBoolean = false
                }
            } message: {_ in }
    }
    
    func Player1DownButton() -> some View {
        return Image.init(systemName: "chevron.down.circle.fill")
            .resizable()
            .frame(width:layoutProperties.height*scoreButtonDiameterMulitplier, height: layoutProperties.height*scoreButtonDiameterMulitplier)
            .scaledToFit()
            .symbolEffect(.bounce.up, value: player1ButtonDown)
            .onTapGesture {
                if player1Selected {
                    player1ButtonDown.toggle()
                }
            }
            .onLongPressGesture(perform: {
                    if player1Selected {
                        multipleScoreChange = true
                    }
            })
            .disabled( !player1Selected || (gameModel.player1Frames < 1) )
            .foregroundStyle(.cyan)
            .alert("Decrease "+gameModel.player1Name+"'s Score?", isPresented: $player1ButtonDown, presenting: gameModel) { gameModel in
                Button("Yes") {
                    player1ButtonDown.toggle()
                    scoreChange(forPlayer: "playerA", changeBy: -1)
                    resetFrame()
                    
//                    framesChanged(&gameModel.player1Frames,&gameModel.player1Sets,&player1ButtonDown)
                }
                
                Button("Cancel") {
                    player1ButtonDown.toggle()
                }
            } message: {_ in }
    }
    
    func Player2Background() -> some View {
        return Image("blueBG")
            .resizable()
            .opacity(player1Selected ? 0.05:1)
            .onTapGesture {
                if player1Selected {
                    shotClockPressed()
                }
                player1Selected = false
            }
    }
    
    func Player2SetsScoreAndLabel() -> VStack<TupleView<(some View, some View)>> {
        return VStack {
            Text(String(gameModel.player2Sets))
                .font(.title)
                .foregroundStyle(.yellow)
                .bold()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text("Sets")
                .font(.body)
                .foregroundStyle(.yellow)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
    }
    
    func Player2Name() -> some View {
        return Text(gameModel.player2Name)
            .font(.largeTitle)
            .foregroundStyle(.white)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
    }
    
    func Player2FramesScoreAndLabel() -> VStack<TupleView<(some View, some View)>> {
        
        let textWidth:CGFloat = layoutProperties.width/17
        
        return VStack {
            Text(String(gameModel.player2Frames))
                .font(.system(size: textWidth))
//                .font(.largeTitle)
                .foregroundStyle(.white)
                .bold()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text("Frames")
                .font(.body)
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
    }
    
    func Player2ExtensionButton() -> some View {
        return Button(action: {
            
            playExtensionSound()
            extension2Pressed = true
            addExtensionTime()
        }, label: {
            Text("EXT")
                .foregroundStyle(extension2Pressed ? .gray:.green)
                .font(.title3)
                .fontWeight(.heavy)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .symbolEffect(.bounce.up, value: extension2Pressed)
        })
        .disabled(extension2Pressed || extensionPressedThisShot || pauseTimer || player1Selected)
    }
    
    func Player2UpButton() -> some View {
        return Image.init(systemName: "chevron.up.circle.fill")
            .resizable()
            .disabled(player1Selected)
            .frame(width:layoutProperties.height*scoreButtonDiameterMulitplier, height: layoutProperties.height*scoreButtonDiameterMulitplier)
            .scaledToFit()
            .symbolEffect(.bounce.up, value: player2ButtonUp)
            .onTapGesture {
                if !player1Selected {
                    player2ButtonUp.toggle()
                }
            }
            .onLongPressGesture(perform: {
                    if !player1Selected {
                        multipleScoreChange = true
                    }
            })
            .foregroundStyle(.cyan)
            .alert("Increase "+gameModel.player2Name+"'s Score?", isPresented: $player2ButtonUp, presenting: gameModel) { gameModel in
                Button("Yes") {
                    scoreChange(forPlayer: "playerB", changeBy: 1)
                    resetFrame()
//                    framesChanged(&gameModel.player2Frames,&gameModel.player2Sets,  &player2ButtonUp)
                    player2ButtonUp.toggle()
                }
                Button("Cancel") {
                    player2ButtonUp.toggle()
                }
            } message: {_ in }
    }
    
    func Player2DownButton() -> some View {
        return Image.init(systemName: "chevron.down.circle.fill")
            .resizable()
            .disabled(player1Selected)
            .frame(width:layoutProperties.height*scoreButtonDiameterMulitplier, height: layoutProperties.height*scoreButtonDiameterMulitplier)
            .scaledToFit()
            .symbolEffect(.bounce.up, value: player2ButtonDown)
            .onTapGesture {
                if !player1Selected {
                    player2ButtonDown.toggle()
                }
            }
            .onLongPressGesture(perform: {
                    if !player1Selected {
                        multipleScoreChange = true
                    }
            })
            .disabled(gameModel.player2Frames < 1)
            .foregroundStyle(.cyan)
            .alert("Decrease "+gameModel.player2Name+"'s Score?", isPresented: $player2ButtonDown, presenting: gameModel) { gameModel in
                Button("Yes") {
                    player2ButtonDown.toggle()
                    scoreChange(forPlayer: "playerB", changeBy: -1)
                    resetFrame()
//                    framesChanged(&gameModel.player2Frames,&gameModel.player2Sets,  &player2ButtonDown)
                }
                
                Button("Cancel") {
                    player1ButtonDown.toggle()
                }
            } message: {_ in }
    }
    
    
    func HideScoreboardView() -> some View {
        let scoreBoardArrow = showingScoreboard ? "arrow.backward.to.line.circle.fill":"arrow.forward.to.line.circle.fill"
        
        return VStack(spacing:0) {
            Image("redBG")
                .resizable()
                .frame(width: layoutProperties.width/15, height: layoutProperties.height*49/100)
            Image("blackBG")
                .resizable()
                .frame(width: layoutProperties.width/15, height: layoutProperties.height/50)
            Image("blueBG")
                .resizable()
                .frame(width: layoutProperties.width/15, height: layoutProperties.height*49/100)
            Color.black
                .ignoresSafeArea()
                .frame(width: layoutProperties.width/15)
        }
        .overlay(alignment: .trailing, content: {
            Image.init(systemName: scoreBoardArrow)
                .resizable()
                .scaledToFit()
                .frame(width: layoutProperties.width/showScoreBoardButtonDiameterDivisor)
                .onTapGesture {
                    withAnimation(.smooth(duration: 0.7)) {
                        showingScoreboard.toggle()
                    }
                }
                .background(.white)
                .foregroundStyle(.black)
                .clipShape(.circle)
        })
    }
    
    func RefreshDataButton() -> some View {
        let actionButtonDiameterDivisor = showingScoreboard ? 16.0:12.0
        
        return Image.init(systemName: "arrow.clockwise.circle")
            .resizable()
            .scaledToFit()
            .frame(width: layoutProperties.width/actionButtonDiameterDivisor)
            .foregroundStyle(.white)
            .containerShape(Circle())
            .onTapGesture {
                refreshData()
                rotationAngle += 360
                rotate.toggle()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                    rotationAngle += 360
                    rotate.toggle()
                }
            }
            .rotation3DEffect(
                .degrees(rotationAngle),
                axis: (x: 0, y: 0, z: 1)
            )
            .animation(.easeInOut(duration: 1.0), value: rotate)
            .symbolEffect(.bounce.up, value: refreshBounce)
    }
    
    func OptionsButton() -> some View {
        
        let actionButtonDiameterDivisor = showingScoreboard ? 16.0:12.0
        return Image.init(systemName: "gear.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.white)
            .frame(width: layoutProperties.width/actionButtonDiameterDivisor)
            .onTapGesture {
                closeGame.toggle()
            }
            .padding(20)
            .alert("Actions", isPresented: $closeGame, presenting: gameModel, actions: {
                _ in
                if gameModel.matchSets > 1 {
                    Button("Next Set") {
                        nextSetBoolean = true
                        refreshData()
                    }
                    
                    Button("Delete Set") {
                        deleteSetBoolean = true
                        refreshData()
                    }
                }
                Button("Finish Match") {
                    finishMatchBoolean = true
                    resetGame()
                }
                Button("Close Shot Clock") {
                    resetGame()
                }
                Button("Return") {
                    closeGame.toggle()
                }
            }, message: { _ in Text("Select one of the game options")})
    }
    
    func HideScoreBoardButton() -> some View {
        let scoreBoardArrow = showingScoreboard ? "arrow.backward.to.line.circle.fill":"arrow.forward.to.line.circle.fill"
        return Image.init(systemName: scoreBoardArrow)
            .resizable()
            .scaledToFit()
            .foregroundStyle(.white)
            .frame(width: layoutProperties.width/showScoreBoardButtonDiameterDivisor)
            .onTapGesture {
                withAnimation(.spring(duration: 0.7)) {
                    showingScoreboard.toggle()
                }
            }
    }
    
    func PushOutButton() -> some View {
        let actionButtonDiameterDivisor = showingScoreboard ? 16.0:12.0
        return Button(action: {
            withAnimation(.smooth(duration: 0.6)) {
                invalidateTimer.toggle()
                extensionPressedThisShot = false
                resetCurrentTimer()
                setShotTime()
                pushOutPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.61) {
                invalidateTimer.toggle()
            }
            
        }, label: {
            Image.init(systemName: "p.circle")
                .resizable()
                .scaledToFit()
                .frame(width: layoutProperties.width/actionButtonDiameterDivisor)
                .symbolEffect(.bounce.up, value: pushOutPressed)
                .padding(20)
                .foregroundStyle((!isFirstShot || pushOutPressed || !gameModel.pushOutEnabled) ? .gray:.white)
        })
        .disabled(!isFirstShot || pushOutPressed || !gameModel.pushOutEnabled || pauseTimer)
    }
    
    func ShotClockCircle() -> some View {
        let shotClockdiameterMultiplier = showingScoreboard ? 0.6:0.75
        let clockWidth:CGFloat = showingScoreboard ? layoutProperties.width/15:layoutProperties.width/12
        let textWidth:CGFloat = showingScoreboard ? layoutProperties.width/9:layoutProperties.width/6
        
        return ZStack {
            Circle()
                .stroke(
                    //                                    player1Selected ? Color.red.opacity(0.5):Color.blue.opacity(0.5),
                    Color.gray.opacity(0.5),
                    lineWidth: clockWidth
                )
                .frame(height: layoutProperties.height*shotClockdiameterMultiplier, alignment: .center)
            Circle()
                .trim(from: 1.0-CGFloat(gameModel.currentTimer)/CGFloat(gameModel.shotTime), to: 1.0)
                .stroke(
                    setShotClockColor(currentTimer: gameModel.currentTimer),
                    lineWidth: clockWidth
                )
                .frame(height: layoutProperties.height*shotClockdiameterMultiplier, alignment: .center)
                .rotationEffect(.degrees(-90))
            Text(String(Int(gameModel.currentTimer)))
                .font(.system(size: textWidth))
                .foregroundStyle(shotClockTextColor)
                .fontWeight(.heavy)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .background(.black)
        .onTapGesture(perform: {
            
            withAnimation(.smooth(duration: 0.3)) {
                invalidateTimer.toggle()
                shotClockPressed()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                invalidateTimer.toggle()
            }
            
        })
    }
    
    func MatchTimer() -> VStack<TupleView<(Spacer, some View)>> {
        return VStack {
            Spacer()
            HStack  {
                Text(String(format: "%02d", gameModel.matchTimeLeft/3600)+":"+String(format: "%02d",gameModel.matchTimeLeft%3600/60)+":"+String(format: "%02d",gameModel.matchTimeLeft%60))
                Image.init(systemName: pauseMatchTimer ? "play.circle":"pause.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(height: layoutProperties.height/20)
                    .symbolEffect(.bounce.up, value: pauseMatchTimer)
            }
            .onTapGesture {
                pauseMatchTimer.toggle()
            }
        }
    }
    
    func Player2NameFramesExtension() -> VStack<TupleView<(Spacer, some View, Spacer, some View, Spacer, some View, Spacer)>> {
        return VStack(alignment: .center) {
            Spacer()
            Player2Name()
            Spacer()
            Player2FramesScoreAndLabel()
            Spacer()
            Player2ExtensionButton()
            Spacer()
        }
    }
    
    func Player2ScoreButtons() -> VStack<TupleView<(Spacer, some View, Spacer, some View, Spacer)>> {
        return VStack {
            Spacer()
            Player2UpButton()
            Spacer()
            Player2DownButton()
            Spacer()
        }
    }
    
    func Player1ScoreButtons() -> VStack<TupleView<(Spacer, some View, Spacer, some View, Spacer)>> {
        return VStack {
            Spacer()
            Player1UpButton()
            Spacer()
            Player1DownButton()
            Spacer()
        }
    }
    
    func Player1NamesFramesExtension() -> VStack<TupleView<(Spacer, some View, Spacer, some View, Spacer, some View, Spacer)>> {
        return VStack(alignment: .center) {
            Spacer()
            Player1Name()
            Spacer()
            Player1FramesScoreAndLabel()
            Spacer()
            Player1ExtensionButton()
            Spacer()
        }
    }
    
    func PauseButton() -> some View {
        let pauseButtonImage = pauseTimer ? "play.circle":"pause.circle"
        let actionButtonDiameterDivisor = showingScoreboard ? 16.0:12.0
        return Image.init(systemName: pauseButtonImage)
            .resizable()
            .scaledToFit()
            .foregroundStyle(.white)
            .frame(width: layoutProperties.width/actionButtonDiameterDivisor)
            .onTapGesture {
                pauseTimer.toggle()
            }
            .symbolEffect(.bounce.up, value: pauseButtonImage)
    }
    
    func Player1Content() -> HStack<TupleView<(Spacer, VStack<TupleView<(Text, Text)>>, some View, Spacer, Spacer, some View, Spacer)>> {
        return HStack {
            Spacer()
            Player1SetsScoreAndLabel()
            Player1NamesFramesExtension()
                .frame(height: layoutProperties.height*49/100)
            Spacer();Spacer()
            Player1ScoreButtons()
                .padding(buttonPadding)
            Spacer()
        }
    }
    
    func Player2Content() -> HStack<TupleView<(Spacer, VStack<TupleView<(some View, some View)>>, some View, Spacer, Spacer, some View, Spacer)>> {
        return HStack() {
            Spacer()
            Player2SetsScoreAndLabel()
            Player2NameFramesExtension()
                .frame(height: layoutProperties.height*49/100)
            Spacer();Spacer()
            Player2ScoreButtons()
                .padding(buttonPadding)
            Spacer()
        }
    }
    
    func setUpSounds(_ soundURL: URL, _ soundURL2: URL, _ soundURL3: URL) {
        do {
            soundPlayer = try AVAudioPlayer(contentsOf: soundURL)
            soundPlayer2 = try AVAudioPlayer(contentsOf: soundURL2)
            soundPlayer3 = try AVAudioPlayer(contentsOf: soundURL3)
        } catch {
            print("Failed to load the sound: \(error)")
        }
    }
    
    private func scoreChange(forPlayer playerClass: String, changeBy increment: Int) {
        let jsCode = """
        (function() {
            if (document.readyState === 'complete' || document.readyState === 'interactive') {
                if (typeof Scoreboard !== 'undefined') {
                    const button = document.querySelector('div.plus.\(playerClass)');
                    if (button) {
                        Scoreboard.scoreAdd(button, \(increment));
                        console.log('Button clicked for \(playerClass)');
                    } else {
                        console.log('Button not found for \(playerClass)');
                    }
                } else {
                    console.log('Scoreboard is not defined');
                }
            } else {
                console.log('Document not ready');
            }
        })();
        """

        webView.evaluateJavaScript(jsCode) { result, error in
            if let error = error {
                print("Error executing JavaScript for \(playerClass): \(error.localizedDescription)")
            } else {
                print("JavaScript executed successfully for \(playerClass)")
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + refreshDelay, execute: {
            refreshData()
        })
        
    }
    
    private func finishMatch() {
        let jsCode = """
        (function() {
            if (document.readyState === 'complete' || document.readyState === 'interactive') {
                if (typeof Scoreboard !== 'undefined') {
                    const button = document.querySelector('div.actions');
                    if (button) {
                        Scoreboard.finish();
                        console.log('Button clicked for finish');
                    } else {
                        console.log('Button not found for finish)');
                    }
                } else {
                    console.log('Scoreboard is not defined');
                }
            } else {
                console.log('Document not ready');
            }
        })();
        """

        webView.evaluateJavaScript(jsCode) { result, error in
            if let error = error {
                print("Error executing JavaScript for finish): \(error.localizedDescription)")
            } else {
                print("JavaScript executed successfully for finish")
            }
        }
        
        resetGame()
    }
    
    private func nextSet() {
        let jsCode = """
        (function() {
            if (document.readyState === 'complete' || document.readyState === 'interactive') {
                if (typeof Scoreboard !== 'undefined') {
                    const button = document.querySelector('div.nextSet');
                    if (button) {
                        Scoreboard.nextSet();
                        console.log('Button clicked for nextSet');
                    } else {
                        console.log('Button not found for nextSet)');
                    }
                } else {
                    console.log('Scoreboard is not defined');
                }
            } else {
                console.log('Document not ready');
            }
        })();
        """

        webView.evaluateJavaScript(jsCode) { result, error in
            if let error = error {
                print("Error executing JavaScript for finish): \(error.localizedDescription)")
            } else {
                print("JavaScript executed successfully for finish")
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + refreshDelay, execute: {
            refreshData()
        })
        
    }
    
    private func deleteSet() {
        let jsCode = """
        (function() {
            if (document.readyState === 'complete' || document.readyState === 'interactive') {
                if (typeof Scoreboard !== 'undefined') {
                    const button = document.querySelector('div.deleteSetButton');
                    if (button) {
                        Scoreboard.deleteSet();
                        console.log('Button clicked for deleteSet');
                    } else {
                        console.log('Button not found for deleteSet)');
                    }
                } else {
                    console.log('Scoreboard is not defined');
                }
            } else {
                console.log('Document not ready');
            }
        })();
        """

        webView.evaluateJavaScript(jsCode) { result, error in
            if let error = error {
                print("Error executing JavaScript for finish): \(error.localizedDescription)")
            } else {
                print("JavaScript executed successfully for finish")
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + refreshDelay, execute: {
            refreshData()
        })
        
    }
    
    func refreshData() {
        apiManager.sendAjaxRequest(tableId: tableId, code: code) { result in
            switch result {
            case .success(let jsonString):
                JSONResponseSaved = jsonString
                print("JSON Response:\n\(JSONResponseSaved)")
                let (extractedTournamentName,
                     _,
                     _,
                     _,
                     extractedFrameScoreA,
                     extractedFrameScoreB,
                     extractedSetScoreA,
                     extractedSetScoreB,
                     _) = extractMatchInfo(jsonString: jsonString)
                
                if extractedTournamentName == nil {
                    return
                }
                
                gameModel.player1Frames = extractedFrameScoreA ?? 0
                gameModel.player2Frames = extractedFrameScoreB ?? 0
                gameModel.player1Sets = extractedSetScoreA!
                gameModel.player2Sets = extractedSetScoreB!
                checkSets()
                
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
            }
        }
        
        
    }
    
    func checkSets() {
        
        if gameModel.player1Frames == gameModel.matchFrames || gameModel.player2Frames == gameModel.matchFrames {
            if gameModel.player1Frames == gameModel.matchFrames && gameModel.player1Sets+1 == gameModel.matchSets || gameModel.player2Frames == gameModel.matchFrames && gameModel.player2Sets+1 == gameModel.matchSets  {
                finishMatchBoolean = true
            } else {
                nextSetBoolean = true
            }
        }
        
    }
    
    private func loadWebPage() {
        if let url = URL(string: "https://cuescore.com/scoreboard/?code=\(gameModel.tournamentCode)") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    fileprivate func shotClockSplashScreen() -> ZStack<TupleView<(GeometryReader<some View>, GeometryReader<some View>)>> {
        return ZStack {
            GeometryReader { container in
                Image("blackBG")
                    .resizable()
                    .ignoresSafeArea()
                    .toolbarBackground(Color.black, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .onAppear {
                        AppDelegate.orientationLock = .landscape
                    }
            }
            
                GeometryReader {container in
                    
                    let imageDiameter:CGFloat = min(layoutProperties.width*0.75, layoutProperties.height*0.75)
                    VStack {
                        Image("logo no bg")
                            .resizable()
                            .frame(width: imageDiameter, height: imageDiameter, alignment: .center)
                            .position(x: container.size.width/2.0, y: container.size.height/2)
                            .opacity(opacity)
                            .onAppear {
                                
                                pauseTimer = true
                                
                                withAnimation(.easeIn(duration: 1)) {
                                    self.opacity = 1.00
                                }
                                
                                
                            }
                        
                        HStack {
                            Text("Loading")
                                .foregroundStyle(.white)
                            ProgressView()
                                .padding()
                                .tint(.white)
                            
                            if !networkMonitor.isConnected {Text("Check Network").foregroundStyle(.red)}
                        }
                        .ignoresSafeArea()
                        
                    }
                    
                }
                
                
        }
    }
    
}
