//
//  selectTournamentManagerView.swift
//  Shot Clock Cue Score
//
//  Created by Owner on 03/04/2025.
//

import Foundation
import SwiftUI

struct SelectTournamentManagerView: View {
    
    @State var newRequestAlert = false
    @State var backgroundColors = generateRandomColorsFromPool()
    
    var body: some View {
        ZStack {
            
            backgroundMesh(sixColors: backgroundColors)
                .ignoresSafeArea()
            
            VStack{
                Spacer()
                NavigationLink(destination: getChallongeMatchView()) {
                    Text("Challonge")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 15)
                            .fill(Color.orange) // Background color
                            .shadow(radius: 20))
                        .foregroundColor(.white)
                }
                NavigationLink(destination: getCuescoreMatchView()) {
                    Text("Cuescore")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 15)
                            .fill(Color.blue)
                            .shadow(radius: 20)
                        )
                        .foregroundColor(.white)
                }
                Spacer()
                Button {
                    newRequestAlert = true
                } label: {
                     Text("Can't see your tournament manager here?")
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.white)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 15)
                            .fill(Color.gray) // Background color
                            .shadow(radius: 20))
                }
                .alert("New Tournament Manager Request", isPresented: $newRequestAlert, presenting: self) { _ in
                    Link("Email", destination: URL(string: "mailto:indigoappsnz@gmail.com?subject=New Tournament Manager Request")!)
                    Link("Instagram", destination: URL(string: "https://www.instagram.com/shot_clock_app")!)
                    Button("Cancel") {
                        newRequestAlert = false
                    }
                } message: {
                    _ in
                    Text("Reach us via email or our social media page")
                }
                .navigationTitle("Tournament Manager")
                                
            }
            .padding()
        }
    }
}

struct SelectTournamentManagerView_Previews: PreviewProvider {
    static var previews: some View {
        SelectTournamentManagerView()
    }
}
