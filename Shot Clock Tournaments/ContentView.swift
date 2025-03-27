import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            HomePageView()
//            SelectTournamentManagerView()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
