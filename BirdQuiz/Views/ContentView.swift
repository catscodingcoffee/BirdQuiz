import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DeckListView()
                .tabItem {
                    Label("Decks", systemImage: "rectangle.stack")
                }

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}
