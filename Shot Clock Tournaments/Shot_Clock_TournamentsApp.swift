//
//  Shot_Clock_Cue_ScoreApp.swift
//  Shot Clock Cue Score
//
//  Created by Owner on 27/03/2025.
//

import SwiftUI
import AVFoundation

@main
struct Shot_Clock_Tournaments: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var gameModel = GameModel()
    @StateObject private var audioManager = AudioManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(gameModel)
        }
    }
}

extension EnvironmentValues {
    var gameModel: GameModel {
        get { self[GameModelKey.self] }
        set { self[GameModelKey.self] = newValue }
    }
}

private struct GameModelKey: EnvironmentKey {
    static var defaultValue: GameModel = GameModel()
}

class AppDelegate: NSObject, UIApplicationDelegate {
        
    static var orientationLock = UIInterfaceOrientationMask.all //By default you want all your views to rotate freely

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
    
}

class AudioManager: ObservableObject {
    init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }
}
