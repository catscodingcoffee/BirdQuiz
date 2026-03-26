import Foundation
import Combine
import AVFoundation

@MainActor
class QuizViewModel: ObservableObject {
    // MARK: - Config
    let deck: Deck
    let quizMode: QuizMode
    let mediaMode: MediaMode

    // MARK: - State
    @Published var currentIndex = 0
    @Published var isFlipped = false
    @Published var score = (correct: 0, incorrect: 0)
    @Published var isFinished = false
    @Published var selectedAnswer: String?
    @Published var showingResult = false
    @Published var isPlayingAudio = false

    // Multiple choice options for current card
    @Published var choices: [String] = []

    private var shuffledCards: [DeckCard] = []
    private var player: AVPlayer?

    var currentCard: DeckCard? {
        guard currentIndex < shuffledCards.count else { return nil }
        return shuffledCards[currentIndex]
    }

    var progress: Double {
        guard !shuffledCards.isEmpty else { return 0 }
        return Double(currentIndex) / Double(shuffledCards.count)
    }

    var totalCards: Int { shuffledCards.count }

    // Whether this card uses image or sound (for mixed mode, alternates)
    var useSound: Bool {
        switch mediaMode {
        case .image: return false
        case .sound: return true
        case .mixed: return currentIndex % 2 == 1
        }
    }

    init(deck: Deck, quizMode: QuizMode, mediaMode: MediaMode) {
        self.deck = deck
        self.quizMode = quizMode
        self.mediaMode = mediaMode
        self.shuffledCards = deck.cards.shuffled()
        buildChoicesForCurrentCard()
    }

    // MARK: - Navigation

    func flipCard() {
        isFlipped.toggle()
    }

    func markCorrect() {
        score.correct += 1
        advance()
    }

    func markIncorrect() {
        score.incorrect += 1
        advance()
    }

    func selectAnswer(_ answer: String) {
        guard selectedAnswer == nil else { return }
        selectedAnswer = answer

        if answer == currentCard?.commonName {
            score.correct += 1
        } else {
            score.incorrect += 1
        }

        showingResult = true
    }

    func advanceAfterMCQ() {
        selectedAnswer = nil
        showingResult = false
        advance()
    }

    private func advance() {
        stopAudio()
        isFlipped = false

        if currentIndex + 1 >= shuffledCards.count {
            isFinished = true
        } else {
            currentIndex += 1
            buildChoicesForCurrentCard()
        }
    }

    func restart() {
        shuffledCards = deck.cards.shuffled()
        currentIndex = 0
        isFlipped = false
        score = (0, 0)
        isFinished = false
        selectedAnswer = nil
        showingResult = false
        buildChoicesForCurrentCard()
    }

    // MARK: - Multiple Choice

    private func buildChoicesForCurrentCard() {
        guard quizMode == .multipleChoice, let card = currentCard else {
            choices = []
            return
        }

        var options = [card.commonName]
        let others = shuffledCards.filter { $0.id != card.id }.map { $0.commonName }
        let distractors = Array(others.shuffled().prefix(3))
        options.append(contentsOf: distractors)

        // Pad if deck is small
        let fallbackNames = ["American Robin", "Blue Jay", "Northern Cardinal", "Red-tailed Hawk",
                             "Bald Eagle", "Great Horned Owl", "Mallard", "Canada Goose"]
        var idx = 0
        while options.count < 4 {
            let name = fallbackNames[idx % fallbackNames.count]
            if !options.contains(name) { options.append(name) }
            idx += 1
        }

        choices = Array(options.prefix(4)).shuffled()
    }

    // MARK: - Audio

    func playAudio() {
        guard let urlString = currentCard?.soundURL, let url = URL(string: urlString) else { return }
        stopAudio()

        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)

        // Configure audio session
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        isPlayingAudio = true
        player?.play()

        // Observe playback end using async sequence to avoid @Sendable capture issues
        Task { @MainActor [weak self] in
            for await _ in NotificationCenter.default.notifications(named: .AVPlayerItemDidPlayToEndTime, object: item) {
                guard let self else { return }
                self.isPlayingAudio = false
                break
            }
        }
    }

    func stopAudio() {
        player?.pause()
        player = nil
        isPlayingAudio = false
    }
}

