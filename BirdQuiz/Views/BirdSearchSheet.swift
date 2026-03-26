import SwiftUI
import SwiftData

struct BirdSearchSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = BirdSearchViewModel()
    @ObservedObject private var eBird = eBirdService.shared

    let deck: Deck

    var body: some View {
        NavigationStack {
            Group {
                if eBird.isLoading {
                    loadingView
                } else if let error = eBird.loadError {
                    errorView(error)
                } else {
                    searchResultsList
                }
            }
            .navigationTitle("Add Birds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .searchable(text: $vm.query, prompt: "Search by name or scientific name")
            .onChange(of: vm.query) { vm.updateSearch() }
        }
        .task {
            vm.syncExistingCards(in: deck)
            await vm.loadTaxonomyIfNeeded()
            vm.updateSearch()
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading eBird taxonomy…")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Could not load birds", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Retry") {
                Task { await eBird.fetchTaxonomy() }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var searchResultsList: some View {
        Group {
            if vm.query.trimmingCharacters(in: .whitespaces).isEmpty {
                ContentUnavailableView(
                    "Search for a Bird",
                    systemImage: "magnifyingglass",
                    description: Text("Type a common or scientific name")
                )
            } else if vm.results.isEmpty {
                ContentUnavailableView.search(text: vm.query)
            } else {
                List(vm.results) { species in
                    BirdRowView(
                        species: species,
                        isAdded: vm.addedSpeciesCodes.contains(species.speciesCode),
                        isLoading: vm.addingSpeciesCode == species.speciesCode
                    ) {
                        vm.addBird(species, to: deck, context: context)
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}
