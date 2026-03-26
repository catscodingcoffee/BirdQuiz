import SwiftUI
import SwiftData

@main
struct BirdQuizApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Deck.self, DeckCard.self])
    }
}
