import SwiftUI

struct BirdRowView: View {
    let species: BirdSpecies
    let isAdded: Bool
    let isLoading: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(species.comName)
                    .font(.body)
                Text(species.sciName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
                if let family = species.familyComName {
                    Text(family)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if isLoading {
                ProgressView()
                    .controlSize(.small)
            } else if isAdded {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button(action: onAdd) {
                    Image(systemName: "plus.circle")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}
