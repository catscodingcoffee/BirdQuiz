import Foundation
import Combine

// Downloads and caches the full eBird taxonomy (~10k species).
// Searches are done locally after the one-time download.
@MainActor
class eBirdService: ObservableObject {
    static let shared = eBirdService()

    @Published var allSpecies: [BirdSpecies] = []
    @Published var isLoading = false
    @Published var loadError: String?

    private let cacheDataKey = "eBirdTaxonomyData"
    private let cacheDateKey = "eBirdTaxonomyCacheDate"
    private let cacheExpiryDays: TimeInterval = 7

    private let keychainService = "com.birdquiz.app"
    private let keychainAccount = "eBirdAPIKey"

    var apiKey: String {
        get { (try? KeychainHelper.load(service: keychainService, account: keychainAccount)) ?? "" }
        set {
            if newValue.isEmpty {
                KeychainHelper.delete(service: keychainService, account: keychainAccount)
            } else {
                try? KeychainHelper.save(newValue, service: keychainService, account: keychainAccount)
            }
        }
    }

    func loadTaxonomyIfNeeded() async {
        guard allSpecies.isEmpty else { return }

        if let cached = loadFromCache() {
            allSpecies = cached
            return
        }

        await fetchTaxonomy()
    }

    func fetchTaxonomy() async {
        guard !apiKey.isEmpty else {
            loadError = "No eBird API key set. Add one in Settings."
            return
        }

        isLoading = true
        loadError = nil

        do {
            var components = URLComponents(string: "https://api.ebird.org/v2/ref/taxonomy/ebird")!
            components.queryItems = [
                URLQueryItem(name: "fmt", value: "json"),
                URLQueryItem(name: "cat", value: "species")
            ]

            var request = URLRequest(url: components.url!)
            request.setValue(apiKey, forHTTPHeaderField: "X-eBirdApiToken")
            request.timeoutInterval = 30

            let (data, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse, http.statusCode == 403 {
                loadError = "Invalid eBird API key. Check Settings."
                isLoading = false
                return
            }

            let species = try JSONDecoder().decode([BirdSpecies].self, from: data)
            allSpecies = species
            saveToCache(data: data)
        } catch {
            loadError = error.localizedDescription
        }

        isLoading = false
    }

    func search(query: String) -> [BirdSpecies] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let q = query.lowercased()
        return allSpecies.filter {
            $0.comName.lowercased().contains(q) || $0.sciName.lowercased().contains(q)
        }
    }

    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheDataKey)
        UserDefaults.standard.removeObject(forKey: cacheDateKey)
        allSpecies = []
    }

    // MARK: - Cache

    private func loadFromCache() -> [BirdSpecies]? {
        guard
            let date = UserDefaults.standard.object(forKey: cacheDateKey) as? Date,
            Date().timeIntervalSince(date) < cacheExpiryDays * 86400,
            let data = UserDefaults.standard.data(forKey: cacheDataKey)
        else { return nil }
        return try? JSONDecoder().decode([BirdSpecies].self, from: data)
    }

    private func saveToCache(data: Data) {
        UserDefaults.standard.set(data, forKey: cacheDataKey)
        UserDefaults.standard.set(Date(), forKey: cacheDateKey)
    }
}
