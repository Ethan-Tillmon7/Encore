import SwiftUI

struct ConflictResolverView: View {

    let conflict: SetConflict
    @EnvironmentObject var scheduleStore: ScheduleStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {

            // Handle bar
            Capsule()
                .fill(Color.appTextMuted)
                .frame(width: 36, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 20)

            // Header
            VStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.orange)
                Text("Schedule Conflict")
                    .font(DS.Font.cardTitle)
                    .foregroundColor(.appTextPrimary)
                Text("These two sets overlap by \(conflict.overlapMinutes) min. Pick one.")
                    .font(DS.Font.listItem)
                    .foregroundColor(.appTextMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 28)

            // Side-by-side comparison
            HStack(alignment: .top, spacing: 12) {
                conflictCard(set: conflict.setA)
                conflictCard(set: conflict.setB)
            }
            .padding(.horizontal, 20)

            Spacer()

            // Actions
            VStack(spacing: 10) {
                Button(action: {
                    scheduleStore.resolveConflict(conflict, keep: conflict.setA)
                    dismiss()
                }) {
                    actionButton(
                        label: "Keep \(conflict.setA.artist.name)",
                        style: .keep
                    )
                }

                Button(action: {
                    scheduleStore.resolveConflict(conflict, keep: conflict.setB)
                    dismiss()
                }) {
                    actionButton(
                        label: "Keep \(conflict.setB.artist.name)",
                        style: .keep
                    )
                }

                Button(action: { dismiss() }) {
                    actionButton(label: "Decide Later", style: .later)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color.appBackground)
    }

    // MARK: - Conflict card

    private func conflictCard(set: FestivalSet) -> some View {
        let artist = set.artist
        return VStack(alignment: .leading, spacing: DS.Spacing.sectionGap) {
            // Tier indicator
            Text(artist.matchTier.rawValue)
                .font(DS.Font.label)
                .foregroundColor(artist.matchTier.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(artist.matchTier.backgroundColor)
                .clipShape(Capsule())

            Text(artist.name)
                .font(DS.Font.cardTitle)
                .foregroundColor(.appTextPrimary)

            VStack(alignment: .leading, spacing: 4) {
                Label(set.stageName, systemImage: "location.fill")
                    .font(DS.Font.metadata)
                    .foregroundColor(.appTextMuted)
                Label(set.timeRangeLabel, systemImage: "clock")
                    .font(DS.Font.metadata)
                    .foregroundColor(.appTextMuted)
            }

            if let label = artist.spotifyLabel {
                Text(label)
                    .font(DS.Font.label)
                    .foregroundColor(artist.matchTier.color)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.cardPadding)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(Color.orange.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - Action button

    private enum ActionStyle { case keep, later }

    private func actionButton(label: String, style: ActionStyle) -> some View {
        Text(label)
            .font(style == .keep ? DS.Font.cardTitle : DS.Font.listItem)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                style == .keep
                    ? Color.appCTA
                    : Color.appSurface
            )
            .foregroundColor(style == .keep ? Color.appBackground : .appTextMuted)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
    }
}

#Preview {
    let sets = FestivalSet.mockSets
    let conflict = SetConflict(setA: sets[5], setB: sets[6]) // LCD vs ODESZA
    return ConflictResolverView(conflict: conflict)
        .environmentObject(ScheduleStore())
        .preferredColorScheme(.dark)
}
