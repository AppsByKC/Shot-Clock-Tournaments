//
//  CheckCuescoreLinkView.swift
//  Shot Clock Cue Score
//
//  Created by Owner on 27/03/2025.
//

import SwiftUI
import WebKit

struct getCuescoreMatchView: View {
    
    @Environment(GameModel.self) private var gameModel
    
    @State private var cuescoreLink = ""
    @State private var createWebView = false
    @State private var showLoading = false
    @State private var showErrorMessage = false
    @State private var tableIdandCodeDetected = false
    @State private var playerNamesDetected = false
    @State private var disableTextField = false
    @State private var disableNextPageButton = true
    @State private var disableCheckLinkButton = false
    @State private var isVisible = false
    
    @State private var statusMessage = "Paste Your Link Here"
    
    @State private var webView: WKWebView = WKWebView()
    @StateObject private var apiManager = APIManager()
    @State private var JSONResponseSaved = ""
    @StateObject var networkMonitor = NetworkMonitor()
    
    @State private var tableId = ""
    @State private var code = ""
    
    @State private var tournamentName = ""
    @State private var playerALastName = ""
    @State private var playerBLastName = ""
    @State private var bestOfSets = 1
    @State private var raceTo = 5
    @State private var playerAFrames = 0
    @State private var playerBFrames = 0
    @State private var playerASets = 0
    @State private var playerBSets = 0
    
    @State var helpViewAlert = false
    @State var backgroundColors = generateRandomColorsFromPool()
    
    var body: some View {
        ZStack{
            
            backgroundMesh(sixColors: backgroundColors)
                .ignoresSafeArea()
            
            VStack {
                
                HStack {
                    
                    Spacer()
                    
                    Button {
                        helpViewAlert = true
                    } label: {
                        
                        HStack {
                            Text("Need a hand")
                                .foregroundStyle(.white)
                            Image(systemName: "questionmark.circle")
                                .foregroundStyle(.white)
                        }
                        .alert("Help Guide", isPresented: $helpViewAlert, presenting: self) { _ in
                            Link("Cuescore Manual", destination: URL(string: "https://cuescore.com/cuescore/posts/Cuescore+manual+-+index/56176114")!)
                            Link("Email", destination: URL(string: "mailto:indigoappsnz@gmail.com?subject=Help Request")!)
                            Link("Instagram", destination: URL(string: "https://www.instagram.com/shot_clock_app")!)
                            Button("Close") {
                                helpViewAlert = false
                            }
                        } message: {
                            _ in
                            Text("1. Login to your Cuescore Account\n2. Go to Dashboard>Venues>Your Venue>Billiard Tables\n3. Copy the link below 'Score Code'.\n\nThat's it! Paste the link in the box and you're good to go! \n\nStill need help? Flick us a message")
                                .multilineTextAlignment(.leading)
                        }
                    }
                    
                }
                .padding(.horizontal)
                
                TextField("Enter Cuescore link here", text: $cuescoreLink)
                    .padding()
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .disabled(disableTextField)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                    .onChange(of: cuescoreLink, {
                        showErrorMessage = false
                    })
                
                HStack {
                    Image(systemName: !networkMonitor.isConnected ? "network.slash":
                            !playerNamesDetected && tableIdandCodeDetected ? "checkmark.circle.badge.questionmark":
                            tableIdandCodeDetected ? "checkmark.circle.fill":
                            "circle.dotted")
                    .foregroundStyle(!networkMonitor.isConnected ? .red : tableIdandCodeDetected ? .green : .red)
                    
                    Text(!networkMonitor.isConnected ? "No Network Connection" : statusMessage)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                
                Button(action: {
                    clearData()
                    checkLink()
                }) {
                    Text("Check Link")
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 15)
                            .fill(disableCheckLinkButton || cuescoreLink.isEmpty ? Color.gray : Color.green) // Background color
                            .shadow(radius: 20))
                        .foregroundColor(.white)
                }
                .disabled(disableCheckLinkButton || cuescoreLink.isEmpty)
                .padding()
                
                if showLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(2.0)
                        .padding()
                }
                Text( (playerNamesDetected) ?  "\(playerALastName) vs \(playerBLastName)": (tableIdandCodeDetected) ? "Table may be waiting or finished": "")
                    .bold(playerNamesDetected)
                    .opacity(!tournamentName.isEmpty ? 1: tableIdandCodeDetected ? 0.3 : 0)
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .padding(.top)
                
                Text(!tournamentName.isEmpty ? "\(tournamentName)" : (tableIdandCodeDetected) ? "Try again":"")
                    .italic(!tournamentName.isEmpty)
                    .opacity(!tournamentName.isEmpty ? 1: tableIdandCodeDetected ? 0.3 : 0)
                
                if createWebView && !cuescoreLink.isEmpty {
                    WebView(url: URL(string: cuescoreLink)!, onDataExtracted: { extractedTableId, extractedCode in
                        self.tableId = extractedTableId ?? ""
                        self.code = extractedCode ?? ""
                        
                        withAnimation(.smooth(duration: 0.2)){
                            tableIdandCodeDetected = !tableId.isEmpty && !code.isEmpty
                        }
                        
                        withAnimation(.smooth(duration: 1)){
                            statusMessage = tableIdandCodeDetected ? "Table Detected, Getting Data" : "Please Enter a Valid URL"
                        }
                    }, onPageLoaded: getDataFromAPI)
                    .frame(width: 0, height: 0)
                    .opacity(0)
                }
                
            }
            .padding()
            VStack {
                Spacer()
                
                NavigationLink(destination: ClockSettingsView()) {
                    Text("Select This Match!")
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 15)
                            .fill((disableNextPageButton || tableId.isEmpty || code.isEmpty || !networkMonitor.isConnected) || playerALastName.isEmpty ? Color.gray : Color.indigo) // Background color
                            .shadow(radius: 20))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                .onAppear {
                    gameModel.tournamentManager = "Cuescore"
                }
                .disabled(disableNextPageButton || tableId.isEmpty || code.isEmpty || tournamentName == "Error, retry link" || playerALastName.isEmpty || !networkMonitor.isConnected)
                
                
            }
            .navigationTitle("Find Your Cuescore Match")
        }
    }
    
    func getDataFromAPI() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
            
            apiManager.sendAjaxRequest(tableId: tableId, code: code) { result in
                switch result {
                case .success(let jsonString):
                    JSONResponseSaved = jsonString
                    print("JSON Response:\n\(JSONResponseSaved)")
                    let (extractedTournamentName,
                         extractedPlayerALastName,
                         extractedPlayerBLastName,
                         extractedBestOfSets,
                         extractedFrameScoreA,
                         extractedFrameScoreB,
                         extractedSetScoreA,
                         extractedSetScoreB,
                         extractedRaceTo) = extractMatchInfo(jsonString: jsonString)
                    
                    if extractedPlayerALastName != nil && extractedPlayerBLastName != nil {
                        playerNamesDetected = true
                        withAnimation(.smooth(duration: 1)){
                            statusMessage = "Match Found!"
                        }
                    } else {
                        playerNamesDetected = false
                    }
                    
                    finishedGettingData()
                    
                    if extractedTournamentName == nil || !playerNamesDetected {
                        return
                    }
                    
                    tournamentName = extractedTournamentName!
                    playerALastName = extractedPlayerALastName!
                    playerBLastName = extractedPlayerBLastName!
                    bestOfSets = extractedBestOfSets!
                    playerASets = extractedSetScoreA ?? 0
                    playerBSets = extractedSetScoreB ?? 0
                    playerAFrames = extractedFrameScoreA ?? 0
                    playerBFrames = extractedFrameScoreB ?? 0
                    raceTo = extractedRaceTo!
                    
                    saveMatchData()
                    
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                }
            }
            
            print("Checking link: \(cuescoreLink)")
            print("tableId: \(self.tableId)")
            print("code: \(self.code)")
            
            //            finishedGettingData()
            
        })
        
    }
    
    fileprivate func loadWebView() {
        createWebView = true
        showLoading = true
        disableNextPageButton = true
        disableCheckLinkButton = true
        disableTextField = true
        withAnimation(.smooth(duration: 1)){
            statusMessage = "Testing URL"
        }
    }
    
    func finishedGettingData() {
        showLoading = false
        createWebView = false
        disableNextPageButton = false
        disableTextField = false
        disableCheckLinkButton = false
    }
    
    func checkLink() {
        
        guard let url = URL(string: cuescoreLink) else {
            //            showErrorMessage = true
            withAnimation(.smooth(duration: 0.3)){
                statusMessage = "Please Enter a Valid URL"
            }
            print("while creating URL")
            return
        }
        
        if !UIApplication.shared.canOpenURL(url) {
            //            showErrorMessage = true
            withAnimation(.smooth(duration: 0.3)){
                statusMessage = "Please Enter a Valid URL"
            }
            print("while opening URL")
            return
        }
        
        loadWebView()
        
    }
    
    func saveMatchData() {
        gameModel.tournamentCode = code
        gameModel.matchFrames = raceTo
        gameModel.matchSets = bestOfSets == 0 ? 1: bestOfSets
        gameModel.player1Name = playerALastName
        gameModel.player2Name = playerBLastName
        gameModel.player1Frames = playerAFrames
        gameModel.player1Sets = playerASets
        gameModel.player2Frames = playerBFrames
        gameModel.player2Sets = playerBSets
        gameModel.tournamentManager = "Cuescore"
        
        print(playerAFrames)
        print(playerBFrames)
        print(playerASets)
        print(playerBSets)
    }
    
    func clearData() {
        tableId = ""
        code = ""
        playerALastName = ""
        playerBLastName = ""
        tournamentName = ""
        withAnimation(.smooth(duration: 0.2)){
            tableIdandCodeDetected = false
        }
        playerNamesDetected = false
    }
    
}

struct getCuescoreMatchView_Previews: PreviewProvider {
    static var previews: some View {
        getCuescoreMatchView()
            .environment(GameModel())
    }
}
