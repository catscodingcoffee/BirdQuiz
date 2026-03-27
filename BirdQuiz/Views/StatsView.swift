import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var stats: [BirdStat]

    private var needsWork: [BirdStat] {
        stats
            .filter { $0.totalAttempts >= 2 && $0.correctRate < 1.0 }
            .sorted { $0.correctRate < $1.correctRate }
    }

    private var mostPracticed: [BirdStat] {
        stats
            .filter { $0.totalAttempts > 0 }
            .sorted { $0.totalAttempts > $1.totalAttempts }
    }

    var body: some View {
        NavigationStack {
            Group {
                if stats.isEmpty {
                    emptyState
                } else {
                    List {
                        if !needsWork.isEmpty {
                            Section("Needs Work") {
                                ForEach(needsWork) { stat in
                                    StatRow(stat: stat)
                                }
                            }
                        }

                        if !mostPracticed.isEmpty {
                            Section("Most Practiced") {
                                ForEach(mostPracticed) { stat in
                                    StatRow(stat: stat)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Stats")
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No History Yet", systemImage: "chart.bar")
        } description: {
            Text("Complete a quiz to start tracking your progress.")
        }
    }
}

// MARK: - Stat Row

private struct StatRow: View {
    let stat: BirdStat

    var body: some View {
        HStack(spacing: 12) {
            // Accuracy ring
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: stat.correctRate)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(stat.correctRate * 100))%")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(stat.commonName)
                    .font(.body)
                    .fontWeight(.medium)
                Text(stat.scientificName)
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(stat.totalAttempts) attempts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Label("\(stat.correctCount)", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Label("\(stat.incorrectCount)", systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                }
                .font(.caption2)
            }
        }
        .padding(.vertical, 2)
    }

    private var ringColor: Color {
        if stat.correctRate >= 0.8 { return .green }
        if stat.correctRate >= 0.5 { return .orange }
        return .red
    }
}
