import Foundation

// iNaturalist taxa API — public, no auth required.
// Used for bird photos since it has reliable coverage for nearly all species.
// Docs: https://api.inaturalist.org/v1/docs/
class iNaturalistService {
    static let shared = iNaturalistService()

    private struct Response: Codable {
        let results: [Taxon]
    }

    private struct Taxon: Codable {
        let preferredCommonName: String?
        let defaultPhoto: Photo?
        enum CodingKeys: String, CodingKey {
            case preferredCommonName = "preferred_common_name"
            case defaultPhoto = "default_photo"
        }
    }

    private struct Photo: Codable {
        let mediumUrl: String?
        enum CodingKeys: String, CodingKey {
            case mediumUrl = "medium_url"
        }
    }

    func photoURL(sciName: String, commonName: String) async -> String? {
        // Try scientific name first; fall back to common name search if taxonomy differs
        // between eBird and iNaturalist (e.g. Mareca strepera vs. Anas strepera for Gadwall).
        if let url = await fetchPhotoURL(query: sciName, queryParam: "taxon_name", expectedCommonName: commonName) {
            return url
        }
        print("[iNat] falling back to common name search for '\(commonName)'")
        return await fetchPhotoURL(query: commonName, queryParam: "q", expectedCommonName: commonName)
    }

    private func fetchPhotoURL(query: String, queryParam: String, expectedCommonName: String) async -> String? {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }

        var components = URLComponents(string: "https://api.inaturalist.org/v1/taxa")!
        components.queryItems = [
            URLQueryItem(name: queryParam, value: query),
            URLQueryItem(name: "rank", value: "species"),
            URLQueryItem(name: "iconic_taxa", value: "Aves"),
            URLQueryItem(name: "per_page", value: "1")
        ]
        guard let url = components.url,
              let (data, _) = try? await URLSession.shared.data(from: url),
              let response = try? JSONDecoder().decode(Response.self, from: data)
        else {
            print("[iNat] request/decode failed for '\(query)'")
            return nil
        }

        let taxon = response.results.first
        let returnedName = taxon?.preferredCommonName ?? "(none)"
        let photoURL = taxon?.defaultPhoto?.mediumUrl
        print("[iNat] queried '\(query)' | got common name: '\(returnedName)' | photo: \(photoURL ?? "nil")")

        guard let taxon,
              taxon.preferredCommonName?.lowercased() == expectedCommonName.lowercased()
        else {
            print("[iNat] name mismatch — expected '\(expectedCommonName)', got '\(returnedName)'")
            return nil
        }

        return photoURL
    }
}
