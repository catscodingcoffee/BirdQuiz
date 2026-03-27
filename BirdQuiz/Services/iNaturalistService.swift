import Foundation

// iNaturalist taxa + observations APIs — public, no auth required.
// Used for bird photos since it has reliable coverage for nearly all species.
// Docs: https://api.inaturalist.org/v1/docs/
class iNaturalistService {
    static let shared = iNaturalistService()

    // MARK: - Taxa response (resolves taxon ID with name validation)

    private struct TaxaResponse: Codable {
        let results: [Taxon]
    }

    private struct Taxon: Codable {
        let id: Int?
        let preferredCommonName: String?
        let defaultPhoto: Photo?
        enum CodingKeys: String, CodingKey {
            case id
            case preferredCommonName = "preferred_common_name"
            case defaultPhoto = "default_photo"
        }
    }

    private struct Photo: Codable {
        let url: String?
        let mediumUrl: String?
        enum CodingKeys: String, CodingKey {
            case url
            case mediumUrl = "medium_url"
        }
        // medium_url is present in taxa responses; fall back to replacing the
        // size token in the generic url field for observation photo objects.
        var resolvedMediumUrl: String? {
            mediumUrl ?? url?.replacingOccurrences(of: "square", with: "medium")
        }
    }

    // MARK: - Observations response (multiple research-grade photos)

    private struct ObservationsResponse: Codable {
        let results: [Observation]
    }

    private struct Observation: Codable {
        let observationPhotos: [ObservationPhoto]
        enum CodingKeys: String, CodingKey {
            case observationPhotos = "observation_photos"
        }
    }

    private struct ObservationPhoto: Codable {
        let photo: Photo?
    }

    // MARK: - Public API

    /// Returns up to 20 research-grade observation photo URLs for a species.
    /// Falls back to the taxon default photo if no observations are found.
    func photoURLs(sciName: String, commonName: String) async -> [String] {
        guard let (taxonId, defaultPhotoURL) = await resolveTaxon(sciName: sciName, commonName: commonName) else {
            return []
        }

        let obsURLs = await fetchObservationPhotos(taxonId: taxonId)
        if !obsURLs.isEmpty { return obsURLs }

        // Fall back to the taxon's own default photo if no observations matched
        print("[iNat] no observation photos found, using default photo for '\(commonName)'")
        return defaultPhotoURL.map { [$0] } ?? []
    }

    // MARK: - Private helpers

    /// Resolves the iNaturalist taxon ID and default photo URL for a species,
    /// trying scientific name first then common name to handle eBird/iNaturalist
    /// taxonomy differences (e.g. Mareca strepera vs. Anas strepera for Gadwall).
    private func resolveTaxon(sciName: String, commonName: String) async -> (id: Int, defaultPhoto: String?)? {
        if let result = await fetchTaxon(query: sciName, queryParam: "taxon_name", expectedCommonName: commonName) {
            return result
        }
        print("[iNat] falling back to common name search for '\(commonName)'")
        return await fetchTaxon(query: commonName, queryParam: "q", expectedCommonName: commonName)
    }

    private func fetchTaxon(query: String, queryParam: String, expectedCommonName: String) async -> (id: Int, defaultPhoto: String?)? {
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
              let response = try? JSONDecoder().decode(TaxaResponse.self, from: data),
              let taxon = response.results.first,
              let taxonId = taxon.id,
              taxon.preferredCommonName?.lowercased() == expectedCommonName.lowercased()
        else { return nil }

        print("[iNat] resolved taxon ID \(taxonId) for '\(commonName)'")
        return (taxonId, taxon.defaultPhoto?.resolvedMediumUrl)
    }

    private func fetchObservationPhotos(taxonId: Int) async -> [String] {
        var components = URLComponents(string: "https://api.inaturalist.org/v1/observations")!
        components.queryItems = [
            URLQueryItem(name: "taxon_id", value: String(taxonId)),
            URLQueryItem(name: "quality_grade", value: "research"),
            URLQueryItem(name: "photos", value: "true"),
            URLQueryItem(name: "per_page", value: "20"),
            URLQueryItem(name: "order_by", value: "votes")
        ]
        guard let url = components.url,
              let (data, _) = try? await URLSession.shared.data(from: url),
              let response = try? JSONDecoder().decode(ObservationsResponse.self, from: data)
        else {
            print("[iNat] observations request failed for taxon \(taxonId)")
            return []
        }

        let urls = response.results.compactMap { $0.observationPhotos.first?.photo?.resolvedMediumUrl }
        print("[iNat] fetched \(urls.count) observation photos for taxon \(taxonId)")
        return urls
    }
}
