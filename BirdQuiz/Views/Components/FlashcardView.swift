import SwiftUI

struct FlashcardView: View {
    let card: DeckCard
    let isFlipped: Bool
    let useSound: Bool
    let isPlayingAudio: Bool
    let onPlay: () -> Void
    let onFlip: () -> Void

    var body: some View {
        ZStack {
            // Front face (media)
            CardFace {
                if useSound {
                    SoundFaceContent(card: card, isPlaying: isPlayingAudio, onPlay: onPlay)
                } else {
                    ImageFaceContent(card: card)
                }
            }
            .overlay(alignment: .topTrailing) {
                if !useSound {
                    Button(action: onPlay) {
                        Image(systemName: isPlayingAudio ? "speaker.wave.2.fill" : "speaker.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .disabled(card.soundURL == nil)
                    .opacity(card.soundURL == nil ? 0.5 : 1.0)
                    .padding(36) // inset from card edge to sit inside the rounded corners
                }
            }
            .opacity(isFlipped ? 0 : 1)
            .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

            // Back face (answer)
            CardFace {
                AnswerFaceContent(card: card)
            }
            .opacity(isFlipped ? 1 : 0)
            .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .onTapGesture(perform: onFlip)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isFlipped)
    }
}

// MARK: - Card Container

private struct CardFace<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.background)
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
            .overlay {
                content()
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(3/4, contentMode: .fit)
            .padding(.horizontal, 24)
    }
}

// MARK: - Front: Image

private struct ImageFaceContent: View {
    let card: DeckCard
    @State private var photoURL: URL?

    var body: some View {
        Group {
            if let url = photoURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        PlaceholderContent(icon: "photo.slash", message: "Image unavailable")
                    default:
                        ProgressView()
                    }
                }
            } else {
                PlaceholderContent(icon: "photo", message: "No image saved")
            }
        }
        .onAppear { pickRandomPhoto() }
        .onChange(of: card.id) { pickRandomPhoto() }
        .overlay(alignment: .bottom) {
            Text("Tap to reveal")
                .font(.caption)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.bottom, 16)
        }
    }

    private func pickRandomPhoto() {
        let urls = card.photoURLs.compactMap { URL(string: $0) }
        photoURL = urls.randomElement() ?? card.imageURL.flatMap { URL(string: $0) }
    }
}

// MARK: - Front: Sound

private struct SoundFaceContent: View {
    let card: DeckCard
    let isPlaying: Bool
    let onPlay: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: isPlaying ? "waveform" : "waveform.slash")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
                .symbolEffect(.variableColor, isActive: isPlaying)

            Button(action: onPlay) {
                Label(isPlaying ? "Playing..." : "Play Sound", systemImage: isPlaying ? "stop.fill" : "play.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(.blue, in: Capsule())
            }

            Text("Tap to reveal")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(32)
    }
}

// MARK: - Back: Answer

private struct AnswerFaceContent: View {
    let card: DeckCard

    var body: some View {
        VStack(spacing: 12) {
            Text(card.commonName)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(card.scientificName)
                .font(.subheadline)
                .italic()
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Divider()
                .padding(.vertical, 4)

            Text("Tap again to continue")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(32)
    }
}

// MARK: - Placeholder

private struct PlaceholderContent: View {
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
