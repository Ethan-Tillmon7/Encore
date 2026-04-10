// Encore/Views/Lineup/SetBlockView.swift
import SwiftUI

struct SetBlockView: View {

    let set: FestivalSet
    let height: CGFloat
    let isAdded: Bool

    @EnvironmentObject var crewStore: CrewStore

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 6)
                .fill(set.artist.matchTier.blockFill)
            RoundedRectangle(cornerRadius: 6)
                .stroke(isAdded ? Color.appCTA : set.artist.matchTier.blockBorder,
                        lineWidth: isAdded ? 2 : 0.8)

            VStack(alignment: .leading, spacing: 2) {
                Text(set.artist.name)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(set.artist.matchTier.color)
                    .lineLimit(2)

                if height > 52 {
                    Text(timeLabel(set.startTime))
                        .font(.system(size: 8))
                        .foregroundColor(set.artist.matchTier.color.opacity(0.7))
                }
            }
            .padding(4)

            if isAdded {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.appCTA)
                    .frame(maxWidth: .infinity, maxHeight: .infinity,
                           alignment: .topTrailing)
                    .padding(3)
            }

            let attendees = crewStore.attendees(for: set)
            if !attendees.isEmpty {
                HStack(spacing: -4) {
                    ForEach(attendees.prefix(3)) { member in
                        CrewAvatarBubble(member: member, size: 18)
                            .overlay(Circle().stroke(Color.appSurface, lineWidth: 1))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity,
                       alignment: .bottomLeading)
                .padding(3)
            }
        }
        .frame(height: max(height - 4, 20))
    }

    private func timeLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm"
        return f.string(from: date)
    }
}
