//
//  GameModel.swift
//  Shot Clock Cue Score
//
//  Created by Owner on 28/03/2025.
//

import Foundation

@Observable class GameModel {
    
    // Match Details
    var tournamentManager = "Cuescore"
    var tournamentCode = ""
    var challongeMatchID = ""
    var challongeAPIKey = "8bmQBcOpyGlKMHw7kieE4Ifrp8rhiz0PzNaaSEm2"
    var matchFrames = 5
    var matchSets = 1
    var player1Name = "Player 1"
    var player2Name = "Player 2"
    var player1Frames = 0
    var player1Sets = 0
    var player2Frames = 0
    var player2Sets = 0
    
    // Clock Settings
    var shotClockValue = 30
    var extensionValue = 30
    var pushOutEnabled = true
    var doubleFirstShot = true
    var matchTimerEnabled = false
    var matchTime = 3600
    var matchTimeLeft = 3600
    var currentTimer:Float = 60.0
    var shotTime = 60
    
}
