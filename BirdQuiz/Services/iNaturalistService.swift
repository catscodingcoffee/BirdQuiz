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
        let defaultPhoto: Photo?
        enum CodingKeys: String, CodingKey {
            case defaultPhoto = "default_photo"
        }
    }

    private struct Photo: Codable {
        let mediumUrl: String?
        enum CodingKeys: String, CodingKey {
            case mediumUrl = "medium_url"
        }
    }

    func photoURL(sciName: String) async -> String? {
        var components = URLComponents(string: "https://api.inaturalist.org/v1/taxa")!
        components.queryItems = [
            URLQueryItem(name: "taxon_name", value: sciName),
            URLQueryItem(name: "rank", value: "species"),
            URLQueryItem(name: "iconic_taxa", value: "Aves"),
            URLQueryItem(name: "per_page", value: "1")
        ]
        guard let url = components.url,
              let (data, _) = try? await URLSession.shared.data(from: url),
              let response = try? JSONDecoder().decode(Response.self, from: data)
        else { return nil }

        return response.results.first?.defaultPhoto?.mediumUrl
    }
}
