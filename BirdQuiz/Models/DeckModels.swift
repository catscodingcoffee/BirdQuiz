import Foundation
import SwiftData

// MARK: - Deck

@Model
class Deck {
    var id: UUID
    var name: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var cards: [DeckCard]

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.cards = []
    }

    var sortedCards: [DeckCard] {
        cards.sorted { $0.addedAt < $1.addedAt }
    }
}

// MARK: - DeckCard

@Model
class DeckCard {
    var id: UUID
    var speciesCode: String
    var commonName: String
    var scientificName: String
    var imageURL: String?           // first photo, used for list thumbnails
    var photoURLs: [String] = []    // full set of observation photos for random selection
    var soundURL: String?
    var addedAt: Date

    init(species: BirdSpecies, imageURL: String? = nil, photoURLs: [String] = [], soundURL: String? = nil) {
        self.id = UUID()
        self.speciesCode = species.speciesCode
        self.commonName = species.comName
        self.scientificName = species.sciName
        self.imageURL = imageURL
        self.photoURLs = photoURLs
        self.soundURL = soundURL
        self.addedAt = Date()
    }
}

// MARK: - Quiz Types

enum QuizMode: String, CaseIterable, Identifiable {
    case flashcard = "Flashcard"
    case multipleChoice = "Multiple Choice"
    var id: String { rawValue }
}

enum MediaMode: String, CaseIterable, Identifiable {
    case image = "Image"
    case sound = "Sound"
    case mixed = "Mixed"
    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .image: return "photo"
        case .sound: return "waveform"
        case .mixed: return "shuffle"
        }
    }
}
