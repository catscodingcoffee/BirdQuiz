import Foundation
import SwiftData
import Combine

@MainActor
class BirdSearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [BirdSpecies] = []
    @Published var addingSpeciesCode: String?   // tracks which card is being fetched
    @Published var addedSpeciesCodes: Set<String> = []

    private let eBird = eBirdService.shared
    private var searchTask: Task<Void, Never>?

    func updateSearch() {
        searchTask?.cancel()
        let q = query
        searchTask = Task {
            // Small debounce
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            results = eBird.search(query: q)
        }
    }

    func loadTaxonomyIfNeeded() async {
        await eBird.loadTaxonomyIfNeeded()
        updateSearch()
    }

    /// Adds a species to the given deck immediately, then fetches media in the background.
    func addBird(_ species: BirdSpecies, to deck: Deck, context: ModelContext) {
        guard !addedSpeciesCodes.contains(species.speciesCode) else { return }

        let card = DeckCard(species: species)
        deck.cards.append(card)
        context.insert(card)
        addedSpeciesCodes.insert(species.speciesCode)

        // Fetch media without blocking — card is already in the deck.
        // @MainActor ensures SwiftData model mutations happen on the right thread.
        Task { @MainActor in
            await MediaService.shared.populateMedia(for: card)
            try? context.save()
        }
    }

    func syncExistingCards(in deck: Deck) {
        addedSpeciesCodes = Set(deck.cards.map { $0.speciesCode })
    }
}
