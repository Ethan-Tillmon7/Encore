// Encore/Views/Schedule/WalkTimeView.swift
import SwiftUI

struct WalkTimeView: View {

    let setA: FestivalSet
    let setB: FestivalSet

    @Environment(\.dismiss) private var dismiss

    private var gapMinutes: Int {
        max(0, Int(setB.startTime.timeIntervalSince(setA.endTime) / 60))
    }

    private var walkMinutes: Int? {
        StageWalkTime.minutes(from: setA.stageName, to: setB.stageName)
    }

    private var severity: WalkSeverity {
        guard let walk = walkMinutes else { return .safe }
        if gapMinutes >= walk { return gapMinutes - walk <= 5 ? .close : .safe }
        return gapMinutes > 0 ? .tight : .over
    }

    private enum WalkSeverity {
        case safe, close, tight, over
        var color: Color {
            switch self {
            case .safe:  return DS.WalkSeverity.safe
            case .close: return DS.WalkSeverity.close
            case .tight: return DS.WalkSeverity.tight
            case .over:  return DS.WalkSeverity.over
            }
        }
        var statusText: String {
            switch self {
            case .safe:  return "You have plenty of time"
            case .close: return "Cutting it close — leave a little early"
            case .tight: return "Not enough time — leave early"
            case .over:  return "No gap — you'll need to leave before the set ends"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(Color.appAccent.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Getting from")
                            .font(DS.Font.metadata)
                            .foregroundColor(.appTextMuted)
                        Text("\(setA.stageName) to \(setB.stageName)")
                            .font(DS.Font.cardTitle)
                            .foregroundColor(.appTextPrimary)
                    }

                    // Walk time display
                    if let walk = walkMinutes {
                        VStack(spacing: 6) {
                            Text("\(walk) min walk")
                                .font(.system(size: 42, weight: .black))
                                .foregroundColor(severity.color)

                            Text(severity.statusText)
                                .font(DS.Font.listItem)
                                .foregroundColor(.appTextMuted)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)

                        // Timeline bar
                        timelineBar(walkMinutes: walk)

                        // Leave early suggestion
                        if severity == .tight || severity == .close {
                            let shortfall = max(0, walk - gapMinutes)
                            if shortfall > 0 {
                                HStack(spacing: 8) {
                                    Image(systemName: "figure.walk")
                                        .foregroundColor(severity.color)
                                    Text("Consider leaving \(setA.artist.name) \(shortfall) min early to make it")
                                        .font(DS.Font.metadata)
                                        .foregroundColor(.appTextMuted)
                                }
                                .padding(12)
                                .background(severity.color.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
                            }
                        }
                    } else {
                        Text("Walk time data not available for these stages.")
                            .font(DS.Font.listItem)
                            .foregroundColor(.appTextMuted)
                    }

                    // Set info
                    VStack(spacing: 8) {
                        setInfoRow(set: setA, label: "FROM")
                        setInfoRow(set: setB, label: "TO")
                    }
                    .padding(DS.Spacing.pageMargin)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))

                    // Context note
                    Text("Walk times are estimates based on Centeroo's typical stage layout.")
                        .font(DS.Font.metadata)
                        .foregroundColor(Color.appTextMuted.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, DS.Spacing.pageMargin)
                .padding(.bottom, 32)
            }
        }
        .background(Color.appBackground)
    }

    private func timelineBar(walkMinutes: Int) -> some View {
        let totalDuration = max(gapMinutes + walkMinutes, 1)
        let walkFraction = CGFloat(walkMinutes) / CGFloat(totalDuration)
        let gapFraction  = CGFloat(gapMinutes)  / CGFloat(totalDuration)

        return GeometryReader { geo in
            HStack(spacing: 0) {
                // "Set A ends" marker
                VStack(spacing: 3) {
                    Capsule()
                        .fill(Color.appAccent.opacity(0.5))
                        .frame(width: 3, height: 24)
                    Text("End")
                        .font(.system(size: 8))
                        .foregroundColor(.appTextMuted)
                }

                // Gap block (time available)
                Rectangle()
                    .fill(severity.color.opacity(0.25))
                    .frame(width: geo.size.width * gapFraction * 0.7, height: 24)
                    .overlay(
                        Text("\(gapMinutes)m gap")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(severity.color)
                            .lineLimit(1)
                            .padding(.horizontal, 2)
                    )

                // Walk block
                Rectangle()
                    .fill(Color.appAccent.opacity(0.15))
                    .frame(width: geo.size.width * walkFraction * 0.7, height: 24)
                    .overlay(
                        Text("\(walkMinutes)m walk")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.appTextMuted)
                            .lineLimit(1)
                            .padding(.horizontal, 2)
                    )

                Spacer()

                // "Set B starts" marker
                VStack(spacing: 3) {
                    Capsule()
                        .fill(Color.appCTA.opacity(0.5))
                        .frame(width: 3, height: 24)
                    Text("Start")
                        .font(.system(size: 8))
                        .foregroundColor(.appTextMuted)
                }
            }
        }
        .frame(height: 40)
    }

    private func setInfoRow(set: FestivalSet, label: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(DS.Font.caps)
                    .foregroundColor(.appTextMuted)
                Text(set.artist.name)
                    .font(DS.Font.listItem)
                    .foregroundColor(.appTextPrimary)
                Text(set.stageName)
                    .font(DS.Font.metadata)
                    .foregroundColor(.appTextMuted)
            }
            Spacer()
            Text(timeLabel(set.endTime))
                .font(DS.Font.label)
                .foregroundColor(.appTextMuted)
        }
    }

    private func timeLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }
}

#Preview {
    WalkTimeView(setA: FestivalSet.mockSets[2], setB: FestivalSet.mockSets[3])
        .preferredColorScheme(.dark)
        .presentationDetents([.medium])
}
