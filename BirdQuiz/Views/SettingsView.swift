import SwiftUI

struct SettingsView: View {
    @ObservedObject private var eBird = eBirdService.shared
    @State private var apiKeyInput = ""
    @State private var showingClearCacheAlert = false
    @State private var showingSavedBanner = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: eBird API
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("eBird API Key")
                            .font(.headline)
                        Text("Required to search the full bird taxonomy. Get a free key at ebird.org/api/keygen.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        SecureField("Paste your API key", text: $apiKeyInput)
                            .textContentType(.password)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .padding(10)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))

                        Button("Save API Key") {
                            eBird.apiKey = apiKeyInput.trimmingCharacters(in: .whitespaces)
                            showingSavedBanner = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showingSavedBanner = false
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(apiKeyInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.vertical, 4)

                    if showingSavedBanner {
                        Label("API key saved!", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .transition(.opacity)
                    }
                } header: {
                    Text("API Configuration")
                }

                // MARK: Taxonomy Cache
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Taxonomy Cache")
                            Text("Species list is cached for 7 days")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if eBird.isLoading {
                            ProgressView()
                        } else if !eBird.allSpecies.isEmpty {
                            Text("\(eBird.allSpecies.count) species")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button("Refresh Taxonomy", role: .destructive) {
                        showingClearCacheAlert = true
                    }
                } header: {
                    Text("Data")
                }

                // MARK: About
                Section {
                    LabeledContent("Bird data", value: "eBird / Cornell Lab")
                    LabeledContent("Photos", value: "iNaturalist")
                    LabeledContent("Audio", value: "Xeno-canto")
                } header: {
                    Text("Data Sources")
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                apiKeyInput = eBird.apiKey
            }
            .alert("Refresh Taxonomy?", isPresented: $showingClearCacheAlert) {
                Button("Refresh", role: .destructive) {
                    eBird.clearCache()
                    Task { await eBird.fetchTaxonomy() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will re-download the full eBird species list.")
            }
        }
    }
}
