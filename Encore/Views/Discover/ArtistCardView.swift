import SwiftUI

struct ArtistCardView: View {

    let festivalSet: FestivalSet
    let isScheduled: Bool
    let crewCount: Int         // how many crew members are going
    let onToggle: () -> Void

    var artist: Artist { festivalSet.artist }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {

            // Tier color bar
            RoundedRectangle(cornerRadius: 2)
                .fill(artist.matchTier.color)
                .frame(width: 3)
                .padding(.vertical, 4)

            // Artist info
            VStack(alignment: .leading, spacing: 6) {

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(artist.name)
                        .font(DS.Font.listItem)
                        .foregroundColor(.appTextPrimary)

                    if artist.isHeadliner {
                        Text("HEADLINER")
                            .font(DS.Font.caps)
                            .foregroundColor(artist.matchTier.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(artist.matchTier.backgroundColor)
                            .clipShape(Capsule())
                    }

                    Spacer()
                }

                // Stage + time
                Text("\(festivalSet.stageName)  ·  \(festivalSet.day.rawValue)  ·  \(festivalSet.timeRangeLabel)")
                    .font(DS.Font.metadata)
                    .foregroundColor(.appTextMuted)

                HStack(spacing: 10) {
                    // Spotify score
                    if let label = artist.spotifyLabel {
                        Label(label, systemImage: "music.note")
                            .font(DS.Font.label)
                            .foregroundColor(artist.matchTier.color)
                    } else if !artist.soundsLike.isEmpty {
                        Text("Sounds like \(artist.soundsLike.prefix(2).joined(separator: ", "))")
                            .font(DS.Font.label)
                            .foregroundColor(.appTextMuted)
                    }

                    // Crew indicator
                    if crewCount > 0 {
                        Label("\(crewCount) friend\(crewCount == 1 ? "" : "s") going", systemImage: "person.2.fill")
                            .font(DS.Font.label)
                            .foregroundColor(.appTextMuted)
                    }
                }
            }

            // Add / Remove button
            Button(action: onToggle) {
                Image(systemName: isScheduled ? "checkmark.circle.fill" : "plus.circle")
                    .font(.system(size: 24))
                    .foregroundColor(isScheduled ? .appCTA : .appTextMuted)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
        .padding(.horizontal, DS.Spacing.cardPadding)
        .padding(.vertical, DS.Spacing.cardPadding)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
    }
}

#Preview {
    ArtistCardView(
        festivalSet: FestivalSet.mockSets[0],
        isScheduled: false,
        crewCount: 2,
        onToggle: {}
    )
    .padding()
    .preferredColorScheme(.dark)
}
