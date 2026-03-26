import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DeckListView()
                .tabItem {
                    Label("Decks", systemImage: "rectangle.stack")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}
