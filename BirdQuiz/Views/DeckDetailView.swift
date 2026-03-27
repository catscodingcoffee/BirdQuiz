import SwiftUI
import SwiftData

struct DeckDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var deck: Deck

    @State private var showingSearch = false
    @State private var showingQuizSetup = false
    @State private var quizMode: QuizMode = .flashcard
    @State private var mediaMode: MediaMode = .image
    @State private var showingQuiz = false
    @State private var cardToDelete: DeckCard?
    @State private var isRefreshingMedia = false

    var body: some View {
        List {
            if deck.cards.isEmpty {
                emptyState
            } else {
                ForEach(deck.sortedCards) { card in
                    CardRow(card: card)
                }
                .onDelete(perform: deleteCards)
            }
        }
        .navigationTitle(deck.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingSearch = true
                } label: {
                    Label("Add Bird", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    Task {
                        isRefreshingMedia = true
                        for card in deck.cards {
                            await MediaService.shared.refreshMedia(for: card)
                        }
                        try? context.save()
                        isRefreshingMedia = false
                    }
                } label: {
                    if isRefreshingMedia {
                        ProgressView()
                    } else {
                        Label("Refresh Media", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(deck.cards.isEmpty || isRefreshingMedia)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !deck.cards.isEmpty && !showingQuiz {
                Button {
                    showingQuizSetup = true
                } label: {
                    Label("Start Quiz", systemImage: "play.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 16)
                }
                .padding(.vertical, 8)
                .background(.bar)
            }
        }
        .sheet(isPresented: $showingSearch) {
            BirdSearchSheet(deck: deck)
        }
        .sheet(isPresented: $showingQuizSetup) {
            QuizSetupSheet(
                deck: deck,
                quizMode: $quizMode,
                mediaMode: $mediaMode,
                onStart: { showingQuiz = true }
            )
            .presentationDetents([.medium])
        }
        .fullScreenCover(isPresented: $showingQuiz) {
            QuizView(deck: deck, quizMode: quizMode, mediaMode: mediaMode)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Birds Yet", systemImage: "bird")
        } description: {
            Text("Tap + to search for birds and add them to this deck.")
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private func deleteCards(at offsets: IndexSet) {
        let sorted = deck.sortedCards
        for index in offsets {
            let card = sorted[index]
            deck.cards.removeAll { $0.id == card.id }
            context.delete(card)
        }
    }
}

// MARK: - Card Row

private struct CardRow: View {
    let card: DeckCard

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            Group {
                if let urlString = card.imageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            Image(systemName: "bird").foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Image(systemName: "bird").foregroundStyle(.secondary)
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(card.commonName)
                    .font(.body)
                    .fontWeight(.medium)
                Text(card.scientificName)
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Media indicators
            HStack(spacing: 6) {
                if card.imageURL != nil {
                    Image(systemName: "photo").font(.caption2).foregroundStyle(.secondary)
                }
                if card.soundURL != nil {
                    Image(systemName: "waveform").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Quiz Setup Sheet

private struct QuizSetupSheet: View {
    let deck: Deck
    @Binding var quizMode: QuizMode
    @Binding var mediaMode: MediaMode
    let onStart: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Quiz Style") {
                    Picker("Mode", selection: $quizMode) {
                        ForEach(QuizMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Media") {
                    ForEach(MediaMode.allCases) { mode in
                        HStack {
                            Label(mode.rawValue, systemImage: mode.systemImage)
                            Spacer()
                            if mediaMode == mode {
                                Image(systemName: "checkmark").foregroundStyle(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { mediaMode = mode }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: {
                    dismiss()
                    // Small delay to let sheet dismiss before fullScreenCover presents
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onStart()
                    }
                }) {
                        HStack {
                            Spacer()
                            Label("Start Quiz (\(deck.cards.count) cards)", systemImage: "play.fill")
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .tint(.blue)
            }
            .navigationTitle("Quiz Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
