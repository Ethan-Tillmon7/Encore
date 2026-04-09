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
                    .font(.system(size: 20, weight: .bold))
                Text("These two sets overlap by \(conflict.overlapMinutes) min. Pick one.")
                    .font(.system(size: 14))
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
        return VStack(alignment: .leading, spacing: 10) {
            // Tier indicator
            Text(artist.matchTier.rawValue)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(artist.matchTier.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(artist.matchTier.backgroundColor)
                .clipShape(Capsule())

            Text(artist.name)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.appTextPrimary)

            VStack(alignment: .leading, spacing: 4) {
                Label(set.stageName, systemImage: "location.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.appTextMuted)
                Label(set.timeRangeLabel, systemImage: "clock")
                    .font(.system(size: 12))
                    .foregroundColor(.appTextMuted)
            }

            if let label = artist.spotifyLabel {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(artist.matchTier.color)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.orange.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - Action button

    private enum ActionStyle { case keep, later }

    private func actionButton(label: String, style: ActionStyle) -> some View {
        Text(label)
            .font(.system(size: 16, weight: style == .keep ? .semibold : .regular))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                style == .keep
                    ? Color.appCTA
                    : Color.appSurface
            )
            .foregroundColor(style == .keep ? Color.appBackground : .appTextMuted)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    let sets = FestivalSet.mockSets
    let conflict = SetConflict(setA: sets[5], setB: sets[6]) // LCD vs ODESZA
    return ConflictResolverView(conflict: conflict)
        .environmentObject(ScheduleStore())
        .preferredColorScheme(.dark)
}
