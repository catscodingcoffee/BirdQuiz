import SwiftUI
import SwiftData

struct QuizView: View {
    @StateObject private var vm: QuizViewModel
    @Environment(\.dismiss) private var dismiss

    init(deck: Deck, quizMode: QuizMode, mediaMode: MediaMode, context: ModelContext) {
        _vm = StateObject(wrappedValue: QuizViewModel(deck: deck, quizMode: quizMode, mediaMode: mediaMode, context: context))
    }

    var body: some View {
        NavigationStack {
            Group {
                if vm.isFinished {
                    ResultsView(vm: vm, onDismiss: { dismiss() })
                } else if let card = vm.currentCard {
                    quizContent(card: card)
                }
            }
            .navigationTitle(vm.deck.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("End") { dismiss() }
                }
            }
        }
        .onDisappear { vm.stopAudio() }
    }

    @ViewBuilder
    private func quizContent(card: DeckCard) -> some View {
        VStack(spacing: 0) {
            // Progress bar
            progressBar

            ScrollView {
                VStack(spacing: 24) {
                    // Card counter
                    Text("\(vm.currentIndex + 1) of \(vm.totalCards)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)

                    // Flashcard
                    FlashcardView(
                        card: card,
                        isFlipped: vm.isFlipped,
                        useSound: vm.useSound,
                        isPlayingAudio: vm.isPlayingAudio,
                        onPlay: {
                            if vm.isPlayingAudio { vm.stopAudio() } else { vm.playAudio() }
                        },
                        onFlip: {
                            if vm.quizMode == .flashcard { vm.flipCard() }
                        }
                    )

                    // Action buttons
                    switch vm.quizMode {
                    case .flashcard:
                        flashcardControls
                    case .multipleChoice:
                        multipleChoiceControls
                    }

                    // Speaker button (image mode only — sound mode has it inside the card)
                    if !vm.useSound {
                        speakerButton
                    }
                }
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Speaker Button

    private var speakerButton: some View {
        Button(action: { if vm.isPlayingAudio { vm.stopAudio() } else { vm.playAudio() } }) {
            Image(systemName: vm.isPlayingAudio ? "speaker.wave.2.fill" : "speaker.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.blue)
                .padding(14)
                .background(Circle().fill(.blue.opacity(0.1)))
        }
        .disabled(vm.currentCard?.soundURL == nil)
        .opacity(vm.currentCard?.soundURL == nil ? 0.4 : 1.0)
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(.quaternary)
                Rectangle()
                    .fill(.blue)
                    .frame(width: geo.size.width * vm.progress)
            }
        }
        .frame(height: 4)
        .animation(.easeInOut, value: vm.progress)
    }

    // MARK: - Flashcard Controls

    @ViewBuilder
    private var flashcardControls: some View {
        if vm.isFlipped {
            HStack(spacing: 20) {
                Button(action: vm.markIncorrect) {
                    Label("Missed it", systemImage: "xmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.red.gradient, in: RoundedRectangle(cornerRadius: 14))
                }

                Button(action: vm.markCorrect) {
                    Label("Got it!", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.green.gradient, in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 24)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            Button(action: vm.flipCard) {
                Text("Reveal Answer")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Multiple Choice Controls

    private var multipleChoiceControls: some View {
        VStack(spacing: 12) {
            ForEach(vm.choices, id: \.self) { choice in
                ChoiceButton(
                    text: choice,
                    state: choiceState(for: choice),
                    action: { vm.selectAnswer(choice) }
                )
            }

            if vm.showingResult {
                Button(action: vm.advanceAfterMCQ) {
                    Text("Next")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.top, 4)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 24)
        .animation(.easeInOut(duration: 0.2), value: vm.showingResult)
    }

    private func choiceState(for choice: String) -> ChoiceButton.State {
        guard vm.showingResult else { return .normal }
        if choice == vm.currentCard?.commonName { return .correct }
        if choice == vm.selectedAnswer { return .incorrect }
        return .dimmed
    }
}

// MARK: - Choice Button

private struct ChoiceButton: View {
    enum State { case normal, correct, incorrect, dimmed }

    let text: String
    let state: State
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.body)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                Spacer()
                icon
            }
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(borderColor, lineWidth: 1.5)
            )
        }
        .disabled(state != .normal)
        .animation(.easeInOut(duration: 0.15), value: state)
    }

    @ViewBuilder
    private var icon: some View {
        switch state {
        case .correct:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        case .incorrect:
            Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
        default:
            EmptyView()
        }
    }

    private var backgroundColor: Color {
        switch state {
        case .normal: return .secondarySystemBackground
        case .correct: return .green.opacity(0.15)
        case .incorrect: return .red.opacity(0.15)
        case .dimmed: return .secondarySystemBackground.opacity(0.5)
        }
    }

    private var foregroundColor: Color {
        switch state {
        case .dimmed: return .secondary
        default: return .primary
        }
    }

    private var borderColor: Color {
        switch state {
        case .normal, .dimmed: return .clear
        case .correct: return .green
        case .incorrect: return .red
        }
    }
}

// MARK: - Results View

private struct ResultsView: View {
    @ObservedObject var vm: QuizViewModel
    let onDismiss: () -> Void

    private var percentage: Int {
        guard vm.totalCards > 0 else { return 0 }
        return Int(Double(vm.score.correct) / Double(vm.totalCards) * 100)
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Score ring
            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 16)
                Circle()
                    .trim(from: 0, to: Double(percentage) / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 1), value: percentage)

                VStack(spacing: 4) {
                    Text("\(percentage)%")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                    Text("Score")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 180, height: 180)

            VStack(spacing: 8) {
                Text(scoreMessage)
                    .font(.title2)
                    .fontWeight(.semibold)

                HStack(spacing: 24) {
                    Label("\(vm.score.correct) correct", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Label("\(vm.score.incorrect) missed", systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                }
                .font(.subheadline)
            }

            Spacer()

            VStack(spacing: 12) {
                Button(action: vm.restart) {
                    Text("Try Again")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 14))
                }

                Button(action: onDismiss) {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private var scoreColor: Color {
        if percentage >= 80 { return .green }
        if percentage >= 50 { return .orange }
        return .red
    }

    private var scoreMessage: String {
        if percentage == 100 { return "Perfect!" }
        if percentage >= 80 { return "Great job!" }
        if percentage >= 50 { return "Keep practicing!" }
        return "Keep at it!"
    }
}

// MARK: - Color extension for UIKit bridging

private extension Color {
    static var secondarySystemBackground: Color {
        Color(uiColor: .secondarySystemBackground)
    }
}
