import Foundation

// MARK: - eBird Taxonomy

struct BirdSpecies: Identifiable, Codable, Hashable {
    let speciesCode: String
    let comName: String
    let sciName: String
    let order: String?
    let familyComName: String?
    let category: String

    var id: String { speciesCode }

    enum CodingKeys: String, CodingKey {
        case speciesCode, comName, sciName, order, familyComName, category
    }
}

// MARK: - Xeno-canto (audio)

struct XenoCantoResponse: Codable {
    let numRecordings: String
    let recordings: [XenoCantoRecording]
}

struct XenoCantoRecording: Identifiable, Codable {
    let id: String
    let en: String
    let file: String
    let q: String?
    let type: String?
    let sono: XenoCantoSono?

    var audioURL: URL? { URL(string: file.hasPrefix("//") ? "https:" + file : file) }

    enum CodingKeys: String, CodingKey {
        case id, en, file, q, type, sono
    }
}

struct XenoCantoSono: Codable {
    let small: String?
    let med: String?
}
