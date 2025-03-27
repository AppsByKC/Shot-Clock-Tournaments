//
//  getChallongeMatchView.swift
//  Shot Clock Cue Score
//
//  Created by Owner on 03/04/2025.
//

import Foundation
import SwiftUI

struct getChallongeMatchView: View {
    
    @Environment(GameModel.self) private var gameModel
    
    @State private var challongeTournamentLink = ""
    @State private var disableTextField = false
    @State private var disableCheckLinkButton = false
    @State private var playerNamesDetected = false
    @State private var challongeTournamentCode = "0"
    
    @State private var id: Int = 0
    @State private var player1Name: String = ""
    @State private var player2Name: String = ""
    @State private var matches: [Match] = []
    @State private var isLoading = false
    
    @State var helpViewAlert = false
    
    @State private var selectedMatchID: Int? = nil
    @State private var selectedPlayer1Name: String = ""
    @State private var selectedPlayer2Name: String = ""
    
    @State private var statusMessage = "Paste Your Link Here"
    @StateObject var networkMonitor = NetworkMonitor()
    @State var backgroundColors = generateRandomColorsFromPool()
    
    
    var body: some View {
        
        ZStack {
            
            backgroundMesh(sixColors: backgroundColors)
                .ignoresSafeArea()
            
            VStack{
                HStack{
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
                            Link("Email", destination: URL(string: "mailto:indigoappsnz@gmail.com?subject=Help Request")!)
                            Link("Instagram", destination: URL(string: "https://www.instagram.com/shot_clock_app")!)
                            Button("Close") {
                                helpViewAlert = false
                            }
                        } message: {
                            _ in
                            Text("1. Open your tournament homepage on Challonge\n2. Copy the URL\n\nThat's it! Paste the link in the box and you're good to go!\n\nStill need help? Flick us a message")
                            
                        }
                        
                    }
                }
                .padding(.horizontal)
                
                TextField("Enter Challonge Tournament link", text: $challongeTournamentLink)
                    .padding()
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange, lineWidth: 2)
                    )
                
                HStack {
                    Image(systemName: !networkMonitor.isConnected ? "network.slash":
                            playerNamesDetected ? "checkmark.circle.fill":
                            "circle.dotted")
                    .foregroundStyle(!networkMonitor.isConnected ? .red : playerNamesDetected ? .green : .red)
                    
                    Text(!networkMonitor.isConnected ? "No Network Connection" : statusMessage)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                
                Button(action: {
                    isLoading = true
                    clearData()
                    checkLink()
                }) {
                    Text("Check Link")
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 15)
                            .fill(disableCheckLinkButton || challongeTournamentLink.isEmpty ? Color.gray : Color.green) // Background color
                            .shadow(radius: 20))
                        .foregroundColor(.white)
                }
                .disabled(disableCheckLinkButton || challongeTournamentLink.isEmpty)
                .padding()
                
                VStack {
                    if isLoading {
                        ProgressView("Loading matches...")
                    } else if matches.isEmpty {
                        Text("No active matches found.")
                            .font(.headline)
                            .foregroundColor(.gray)
                    } else {
                        List(matches, selection: $selectedMatchID) { match in
                            VStack(alignment: .leading) {
                                Text("Player 1: \(match.player1Name)")
                                Text("Player 2: \(match.player2Name)")
                            }
                            .contentShape(Rectangle()) // Make the entire row tappable
                            .onTapGesture {
                                // Update selected match details when tapped
                                selectedMatchID = match.id
                                selectedPlayer1Name = match.player1Name
                                selectedPlayer2Name = match.player2Name
                                
                                saveData()
                                
                            }
                        }
                        .scrollContentBackground(.hidden) 
                        .listStyle(InsetGroupedListStyle())
                    }
                }
                
            }
            .padding()
            
            VStack {
                
                Spacer()
                NavigationLink(destination: ClockSettingsView()) {
                    Text("Select This Match!")
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 15)
                            .fill(selectedMatchID == nil || gameModel.player1Name.isEmpty || gameModel.player2Name.isEmpty || !networkMonitor.isConnected ? Color.gray:Color.blue) // Background color
                            .shadow(radius: 20))
                        .foregroundColor(.white)
                }
                .padding()
                .onAppear{
                    gameModel.tournamentManager = "Challonge"
                }
                .navigationTitle("Find Your Challonge Match")
                .disabled(selectedMatchID == nil || gameModel.player1Name.isEmpty || gameModel.player2Name.isEmpty || !networkMonitor.isConnected)
                
            }
        }
    }
    
    func saveData() {
        gameModel.tournamentCode = challongeTournamentCode
        gameModel.challongeMatchID = "\(selectedMatchID!)"
        gameModel.matchFrames = 1000000
        gameModel.matchSets = 1000000
        gameModel.player1Name = selectedPlayer1Name
        gameModel.player2Name = selectedPlayer2Name
        gameModel.player1Frames = 0
        gameModel.player1Sets = 0
        gameModel.player2Frames = 0
        gameModel.player2Sets = 0
        gameModel.tournamentManager = "Challonge"
        
        
        print(gameModel.tournamentCode)
        print(gameModel.challongeMatchID)
        print(gameModel.challongeAPIKey)
        
    }
    
    func checkLink() {
        
        withAnimation(.smooth(duration: 0.3)){
            statusMessage = "Loading"
        }
        
        guard let url = URL(string: challongeTournamentLink) else {
            isLoading = false
            //            showErrorMessage = true
            withAnimation(.smooth(duration: 0.3)){
                statusMessage = "Please Enter a Valid URL"
            }
            print("while creating URL")
            return
        }
        
        if !UIApplication.shared.canOpenURL(url) {
            isLoading = false
            //            showErrorMessage = true
            withAnimation(.smooth(duration: 0.3)){
                statusMessage = "Please Enter a Valid URL"
            }
            print("while opening URL")
            return
        }
        
        guard url.host == "challonge.com" else {
            isLoading = false
            print("Not a Challonge URL")
            return
        }
        
        fetchActiveMatches(link: challongeTournamentLink)
        
    }
    
    func clearData() {
        
        selectedMatchID = nil
        selectedPlayer1Name = ""
        selectedPlayer2Name = ""
        player1Name = ""
        player2Name = ""
        matches = []
        playerNamesDetected = false
        statusMessage = playerNamesDetected ? "Match Found" : "Please Enter a Valid URL"
        
    }
    
    func fetchActiveMatches(link challongeTournamentLink: String) {
        let apiKey = gameModel.challongeAPIKey
        let tournamentCodeSplitter = challongeTournamentLink.split(separator: "/")
        let tournamentUrl = tournamentCodeSplitter.last.map { String($0) }
        //        let tournamentUrl = challongeTournamentLink
        let baseUrl = "https://api.challonge.com/v1"
        
        guard let matchesUrl = URL(string: "\(baseUrl)/tournaments/\(tournamentUrl ?? "0")/matches.json?api_key=\(apiKey)") else {
            clearData()
            isLoading = false
            return
        }
        
        print("Here")
        // Fetch active matches
        URLSession.shared.dataTask(with: matchesUrl) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching matches:", error?.localizedDescription ?? "Unknown error")
                return
            }
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] else {
                    print("Invalid JSON format: Expected array of dictionaries")
                    clearData()
                    isLoading = false
                    return
                }
                
                var fetchedMatches: [Match] = []
                for matchData in json {
                    if let match = matchData["match"] as? [String: Any],
                       let state = match["state"] as? String,
                       state == "open",
                       let matchId = match["id"] as? Int,
                       let player1Id = match["player1_id"] as? Int,
                       let player2Id = match["player2_id"] as? Int {
                        
                        // Fetch player names for each match
                        fetchPlayerName(tournamentUrl: tournamentUrl ?? "0", participantId: player1Id, apiKey: apiKey) { player1Name in
                            fetchPlayerName(tournamentUrl: tournamentUrl ??  "0", participantId: player2Id, apiKey: apiKey) { player2Name in
                                DispatchQueue.main.async {
                                    fetchedMatches.append(Match(id: matchId, player1Name: player1Name ?? "Unknown", player2Name: player2Name ?? "Unknown"))
                                    self.matches = fetchedMatches.sorted(by: { $0.id < $1.id })
                                    withAnimation(.smooth(duration: 0.5)){
                                        self.isLoading = false
                                        self.playerNamesDetected = player1Name != "Unknown" || player2Name != "Unknown"
                                        self.statusMessage = playerNamesDetected ? "Match Found" : "Please Enter a Valid URL"
                                        self.challongeTournamentCode = tournamentUrl ?? ""
                                    }
                                }
                            }
                        }
                    }
                }
                //                }
            } catch {
                print("Error parsing JSON:", error.localizedDescription)
            }
        }.resume()
    }
    
    func fetchPlayerName(tournamentUrl: String, participantId: Int, apiKey: String, completion: @escaping (String?) -> Void) {
        let baseUrl = "https://api.challonge.com/v1"
        guard let participantUrl = URL(string: "\(baseUrl)/tournaments/\(tournamentUrl)/participants/\(participantId).json?api_key=\(apiKey)") else { return }
        
        URLSession.shared.dataTask(with: participantUrl) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching participant:", error?.localizedDescription ?? "Unknown error")
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let participant = json["participant"] as? [String: Any],
                   let name = participant["name"] as? String {
                    completion(name)
                } else {
                    completion(nil)
                }
            } catch {
                print("Error parsing JSON:", error.localizedDescription)
                completion(nil)
            }
        }.resume()
    }
    
    struct Match: Identifiable {
        let id: Int
        let player1Name: String
        let player2Name: String
    }
    
}

//struct getChallongeMatchView_Previews: PreviewProvider {
//    static var previews: some View {
//        getChallongeMatchView()
//    }
//}
