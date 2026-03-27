import Foundation

// Coordinates media fetching:
//   Photos  → iNaturalist API
//   Audio   → Xeno-canto API
class MediaService {
    static let shared = MediaService()

    private let iNat = iNaturalistService.shared
    private let xenoCanto = XenoCantoService.shared

    /// Clears existing media URLs and re-fetches them.
    @MainActor
    func refreshMedia(for card: DeckCard) async {
        card.imageURL = nil
        card.soundURL = nil
        await populateMedia(for: card)
    }

    /// Fetches and saves photo + audio URLs into a DeckCard.
    /// Must be called from the MainActor so SwiftData model mutations are on the right thread.
    @MainActor
    func populateMedia(for card: DeckCard) async {
        async let photoTask = iNat.photoURL(sciName: card.scientificName, commonName: card.commonName)
        async let audioTask = xenoCanto.bestAudioURL(sciName: card.scientificName)
        let photo = await photoTask
        let audio = await audioTask
        card.imageURL = photo
        card.soundURL = audio
    }
}
