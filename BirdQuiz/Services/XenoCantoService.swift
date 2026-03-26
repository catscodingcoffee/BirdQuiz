import Foundation

// Xeno-canto API v2 — free bird sound recordings.
// Used for bird audio.
// API docs: https://xeno-canto.org/explore/api
class XenoCantoService {
    static let shared = XenoCantoService()

    func fetchRecordings(sciName: String, count: Int = 5) async throws -> [XenoCantoRecording] {
        // Prefer "song" type, quality A/B
        let query = "\(sciName) q:A type:song"
        var components = URLComponents(string: "https://xeno-canto.org/api/2/recordings")!
        components.queryItems = [URLQueryItem(name: "query", value: query)]

        var request = URLRequest(url: components.url!)
        request.setValue("BirdQuizApp/1.0", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(XenoCantoResponse.self, from: data)

        // Fall back to any quality if no A-quality results
        if response.recordings.isEmpty {
            return try await fetchRecordingsAnyQuality(sciName: sciName, count: count)
        }

        return Array(response.recordings.prefix(count))
    }

    private func fetchRecordingsAnyQuality(sciName: String, count: Int) async throws -> [XenoCantoRecording] {
        var components = URLComponents(string: "https://xeno-canto.org/api/2/recordings")!
        components.queryItems = [URLQueryItem(name: "query", value: sciName)]

        var request = URLRequest(url: components.url!)
        request.setValue("BirdQuizApp/1.0", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(XenoCantoResponse.self, from: data)
        return Array(response.recordings.prefix(count))
    }

    func bestAudioURL(sciName: String) async -> String? {
        let recordings = try? await fetchRecordings(sciName: sciName, count: 1)
        return recordings?.first?.audioURL?.absoluteString
    }
}
