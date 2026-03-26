import SwiftUI
import SwiftData

struct DeckListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Deck.createdAt, order: .forward) private var decks: [Deck]

    @State private var showingNewDeck = false
    @State private var newDeckName = ""

    var body: some View {
        NavigationStack {
            Group {
                if decks.isEmpty {
                    emptyState
                } else {
                    deckList
                }
            }
            .navigationTitle("Bird Decks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        newDeckName = ""
                        showingNewDeck = true
                    } label: {
                        Label("New Deck", systemImage: "plus")
                    }
                }
            }
            .alert("New Deck", isPresented: $showingNewDeck) {
                TextField("Deck name", text: $newDeckName)
                    .autocorrectionDisabled()
                Button("Create", action: createDeck)
                    .disabled(newDeckName.trimmingCharacters(in: .whitespaces).isEmpty)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter a name for your new bird deck.")
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Decks", systemImage: "tray")
        } description: {
            Text("Create a deck to start building your bird quiz collection.")
        } actions: {
            Button("Create Deck") {
                newDeckName = ""
                showingNewDeck = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var deckList: some View {
        List {
            ForEach(decks) { deck in
                NavigationLink(destination: DeckDetailView(deck: deck)) {
                    DeckRow(deck: deck)
                }
            }
            .onDelete(perform: deleteDecks)
        }
    }

    // MARK: - Actions

    private func createDeck() {
        let name = newDeckName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let deck = Deck(name: name)
        context.insert(deck)
    }

    private func deleteDecks(at offsets: IndexSet) {
        for index in offsets {
            context.delete(decks[index])
        }
    }
}

// MARK: - Deck Row

private struct DeckRow: View {
    let deck: Deck

    var body: some View {
        HStack(spacing: 14) {
            // Stack of bird thumbnails
            ThumbnailStack(cards: deck.sortedCards)

            VStack(alignment: .leading, spacing: 4) {
                Text(deck.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    Label("\(deck.cards.count) bird\(deck.cards.count == 1 ? "" : "s")", systemImage: "bird")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if deck.cards.contains(where: { $0.soundURL != nil }) {
                        Image(systemName: "waveform")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Thumbnail Stack

private struct ThumbnailStack: View {
    let cards: [DeckCard]
    private let size: CGFloat = 44
    private let overlap: CGFloat = 12

    var preview: [DeckCard] { Array(cards.prefix(3)) }

    var body: some View {
        ZStack {
            ForEach(Array(preview.enumerated()), id: \.element.id) { idx, card in
                thumbnail(for: card)
                    .offset(x: CGFloat(idx) * overlap)
                    .zIndex(Double(idx))
            }
        }
        .frame(width: size + CGFloat(max(0, preview.count - 1)) * overlap, height: size)
    }

    private func thumbnail(for card: DeckCard) -> some View {
        Group {
            if let urlString = card.imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        Image(systemName: "bird").foregroundStyle(.secondary).font(.caption)
                    }
                }
            } else {
                Image(systemName: "bird").foregroundStyle(.secondary).font(.caption)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .background(Circle().fill(.quaternary))
        .overlay(Circle().strokeBorder(.background, lineWidth: 2))
    }
}
