//
//  ClockSettingsView.swift
//  Shot Clock Cue Score
//
//  Created by Owner on 27/03/2025.
//

import SwiftUI

struct ClockSettingsView: View {
    
    @Environment(GameModel.self) private var gameModel
    
    @State private var pushOutEnabledisOn = true
    @State private var matchTimerisOn = false
    @State private var doubleFirstShotisOn = true
    @State private var navigateToShotClock = false
    
    @State private var shotClockSliderShowing = false
    @State private var extensionSliderShowing = false
    @State private var matchTimerShowing = false
    @State private var timerSliderValue = 30.0
    @State private var extensionSliderValue = 30.0
    
    @State private var matchTimer = 60.0
    
    @State private var selectedOption: String = "9/10 Ball (American)" // Tracks the selected option
        
        let options = [
            "9/10 Ball (American)",
            "8 Ball (American)",
            "Heyball",
            "Ultimate Pool"
        ]
    
    @State var backgroundColors = generateRandomColorsFromPool()
    
    var body: some View {
        
        
        ZStack {
            
            backgroundMesh(sixColors: backgroundColors)
                .ignoresSafeArea()
            
            VStack {
                
                Text("Clock Settings")
                    .font(.largeTitle)
                    .foregroundStyle(.white)
                
                
                Picker("Shot Clock Presets", selection: $selectedOption) {
                    ForEach(options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: selectedOption) { _,newValue in
                    withAnimation {
                        handleSelectionChange(newValue)
                    }
                }
                
                
                List {
                    
                    HStack{
                        Spacer()
                        Text("Tap a row to edit")
                        Spacer()
                    }
                    .listRowBackground(Color.gray)
                    
                    HStack {
                        Text("Shot Clock")
                            .font(.title2)
                        Spacer()
                        Text("\(Int(timerSliderValue))")
                            .font(.title2)
                            .foregroundStyle(.red)
                            .bold()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture(perform: {
                        withAnimation(.easeIn(duration: 0.5)) {
                            shotClockSliderShowing.toggle()
                        }
                    })
                    
                    if shotClockSliderShowing {
                        Slider(value: $timerSliderValue,in: 15...60, step: 5, onEditingChanged: {
                            _ in
                            saveClockSettings()
                        })
                        .tint(.red)
                        
                        Text("\(Int(timerSliderValue)) seconds")
                            .foregroundStyle(.red)
                        
                    }
                    
                    HStack {
                        Text("Extension Time")
                            .font(.title2)
                        Spacer()
                        Text("\(Int(extensionSliderValue))")
                            .font(.title2)
                            .foregroundStyle(.green)
                            .bold()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture(perform: {
                        withAnimation(.easeIn(duration: 0.5)) {
                            extensionSliderShowing.toggle()
                        }
                    })
                    
                    if extensionSliderShowing {
                        Slider(value: $extensionSliderValue,in: 15...60, step: 5, onEditingChanged: {
                            _ in
                            saveClockSettings()
                        })
                        .tint(.green)
                        
                        Text("\(Int(extensionSliderValue)) seconds")
                            .foregroundStyle(.green)
                        
                    }
                    
                    HStack {
                        Toggle("Double First Shot Timer", isOn: $doubleFirstShotisOn)
                            .minimumScaleFactor(0.6)
                            .toggleStyle(SwitchToggleStyle(tint: .yellow))
                            .font(.title2)
                            .onChange(of: doubleFirstShotisOn, {
                                _,_ in
                                saveClockSettings()
                            })
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        doubleFirstShotisOn.toggle()
                    }
                    
                    HStack {
                        Toggle("Push Out Enabled", isOn: $pushOutEnabledisOn)
                            .toggleStyle(SwitchToggleStyle(tint: .cyan))
                            .font(.title2)
                            .onChange(of: pushOutEnabledisOn, {
                                _,_ in
                                saveClockSettings()
                            })
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        pushOutEnabledisOn.toggle()
                    }
                    
                    HStack {
                        Toggle("Match Timer", isOn: $matchTimerisOn)
                            .toggleStyle(SwitchToggleStyle(tint: .indigo))
                            .font(.title2)
                            .onChange(of: matchTimerisOn, {
                                _,_ in
                                
                                
                                withAnimation(.easeIn(duration: 0.5)) {
                                    matchTimerShowing = matchTimerisOn
                                }
                                saveClockSettings()
                                
                            })
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        matchTimerisOn.toggle()
                    }
                    
                    if matchTimerShowing {
                        Slider(value: $matchTimer,in: 15...180, step: 5, onEditingChanged: {
                            _ in
                            saveClockSettings()
                        })
                        .tint(.indigo)
                        
                        Text("\(Int(matchTimer)) min")
                            .foregroundStyle(.indigo)
                        
                    }
                }
                .shadow(radius: 40)
                .scrollContentBackground(.hidden)
            }
                        
            VStack {
                Spacer()
                if gameModel.tournamentManager == "Cuescore" {
                    NavigationLink(destination: LayoutDimenions { properties in ShotClockCuescoreView(layoutProperties: properties)
                    }) {
                        Text("Start Match!")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                } else if gameModel.tournamentManager == "Challonge" {
                    
                    NavigationLink(destination: LayoutDimenions { properties in ShotClockChallongeView(layoutProperties: properties)
                    }) {
                        Text("Start Match!")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                } else {
                    Text("Something's not right")
                }
                
                
            }
            .navigationTitle("Set Up Your Shot Clock")
            .onAppear {
                saveClockSettings()
            }
        }
        
    }
    
    private func handleSelectionChange(_ newValue: String) {
            print("Selected game type: \(newValue)")
            
            // Perform any additional actions based on the selection
            switch newValue {
            case "9/10 Ball (American)":
                
                timerSliderValue = 30
                extensionSliderValue = 30
                pushOutEnabledisOn = true
                doubleFirstShotisOn = true
                matchTimerisOn = false
                matchTimer = 60
                
                saveClockSettings()
                
            case "8 Ball (American)":
                
                timerSliderValue = 30
                extensionSliderValue = 30
                pushOutEnabledisOn = false
                doubleFirstShotisOn = true
                matchTimerisOn = false
                matchTimer = 60
                
                saveClockSettings()
                
                print("Setup for 8 Ball (American)")
                
            case "Heyball":
                
                timerSliderValue = 45
                extensionSliderValue = 30
                pushOutEnabledisOn = false
                doubleFirstShotisOn = true
                matchTimerisOn = true
                matchTimer = 120
                
                saveClockSettings()
                
                print("Setup for Heyball")
                
            case "Ultimate Pool":
                
                timerSliderValue = 20
                extensionSliderValue = 30
                pushOutEnabledisOn = false
                doubleFirstShotisOn = false
                matchTimerisOn = true
                matchTimer = 50
                
                saveClockSettings()
                
                print("Setup for Ultimate Pool")
            default:
                break
            }
        }
    
    func saveClockSettings() {
        gameModel.shotClockValue = Int(timerSliderValue)
        gameModel.extensionValue = Int(extensionSliderValue)
        gameModel.doubleFirstShot = doubleFirstShotisOn
        gameModel.currentTimer = gameModel.doubleFirstShot ? (Float(gameModel.shotClockValue)*2.0):Float(gameModel.shotClockValue)
        gameModel.shotTime = Int(gameModel.currentTimer)
        gameModel.matchTimerEnabled = matchTimerisOn
        gameModel.matchTime = Int(matchTimer*60)
        gameModel.matchTimeLeft = gameModel.matchTime
        gameModel.pushOutEnabled = pushOutEnabledisOn
    }
    
}

struct ClockSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ClockSettingsView()
            .environment(GameModel())
    }
}

