// Encore/Views/Lineup/TimetableGridView.swift
import SwiftUI

struct TimetableGridView: View {

    let sets: [FestivalSet]
    let stages: [String]
    let scheduledSetIDs: Set<UUID>
    var onSetTap: (FestivalSet) -> Void
    var onWalkTap: ((FestivalSet, FestivalSet) -> Void)? = nil

    // Layout constants
    private let rowHeight:       CGFloat = 44   // per 30-min slot
    private let columnWidth:     CGFloat = 110
    private let timeColumnWidth: CGFloat = 36
    private let headerHeight:    CGFloat = 30

    // MARK: - Derived geometry

    private var dayStart: Date {
        guard let earliest = sets.map(\.startTime).min() else { return Date() }
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour], from: earliest)
        return Calendar.current.date(from: comps) ?? earliest
    }

    private var dayEnd: Date {
        sets.map(\.endTime).max() ?? Date()
    }

    private var totalMinutes: Int {
        max(Int(dayEnd.timeIntervalSince(dayStart)) / 60, 30)
    }

    private var rowCount: Int {
        Int(ceil(Double(totalMinutes) / 30.0))
    }

    private var totalWidth: CGFloat {
        timeColumnWidth + CGFloat(stages.count) * columnWidth
    }

    private var totalHeight: CGFloat {
        headerHeight + CGFloat(rowCount) * rowHeight
    }

    // MARK: - Body

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    // Canvas background
                    Color.appBackground
                        .frame(width: totalWidth, height: totalHeight)

                    // Horizontal grid lines (one per 30-min row)
                    ForEach(0 ..< rowCount, id: \.self) { row in
                        Rectangle()
                            .fill(Color.appAccent.opacity(row % 2 == 0 ? 0.08 : 0.04))
                            .frame(width: totalWidth, height: 1)
                            .offset(y: headerHeight + CGFloat(row) * rowHeight)
                    }

                    // Vertical stage dividers
                    ForEach(0 ..< stages.count, id: \.self) { col in
                        Rectangle()
                            .fill(Color.appAccent.opacity(0.08))
                            .frame(width: 1, height: totalHeight)
                            .offset(x: timeColumnWidth + CGFloat(col) * columnWidth)
                    }

                    // Stage column headers
                    ForEach(Array(stages.enumerated()), id: \.offset) { idx, stage in
                        Text(stage)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.appCTA)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(width: columnWidth, height: headerHeight)
                            .offset(x: timeColumnWidth + CGFloat(idx) * columnWidth)
                    }

                    // Time labels (every hour)
                    ForEach(0 ..< rowCount, id: \.self) { row in
                        if row % 2 == 0 {
                            Text(hourLabel(minuteOffset: row * 30))
                                .font(.system(size: 8))
                                .foregroundColor(.appTextMuted)
                                .frame(width: timeColumnWidth - 4, alignment: .trailing)
                                .offset(x: 0,
                                        y: headerHeight + CGFloat(row) * rowHeight - 6)
                        }
                    }

                    // Set blocks
                    ForEach(sets) { set in
                        let pos = blockOrigin(for: set)
                        let h   = blockHeight(for: set)
                        let added = scheduledSetIDs.contains(set.id)

                        Button(action: { onSetTap(set) }) {
                            SetBlockView(set: set, height: h, isAdded: added)
                        }
                        .buttonStyle(.plain)
                        .frame(width: columnWidth - 4)
                        .offset(x: pos.x + 2, y: pos.y + 2)
                    }

                    // Walk-time gap pills (between consecutive scheduled sets on different stages)
                    let scheduledSorted = sets.filter { scheduledSetIDs.contains($0.id) }
                                              .sorted { $0.startTime < $1.startTime }
                    if scheduledSorted.count >= 2 {
                        ForEach(0..<(scheduledSorted.count - 1), id: \.self) { idx in
                            let setA = scheduledSorted[idx]
                            let setB = scheduledSorted[idx + 1]
                            if setA.stageName != setB.stageName && setB.startTime > setA.endTime {
                                let gapMins = Int(setB.startTime.timeIntervalSince(setA.endTime) / 60)
                                let walk = StageWalkTime.minutes(from: setA.stageName, to: setB.stageName)
                                let severity: Color = {
                                    guard let w = walk else { return DS.WalkSeverity.safe }
                                    if gapMins >= w { return gapMins - w <= 5 ? DS.WalkSeverity.close : DS.WalkSeverity.safe }
                                    return DS.WalkSeverity.tight
                                }()
                                let midMinOffset = Int(setA.endTime.timeIntervalSince(dayStart) / 60) + gapMins / 2
                                let yPos = headerHeight + CGFloat(midMinOffset) / 30.0 * rowHeight

                                Button(action: { onWalkTap?(setA, setB) }) {
                                    HStack(spacing: 3) {
                                        Image(systemName: "figure.walk")
                                            .font(.system(size: 8))
                                        if let w = walk {
                                            Text("→ \(w) min walk")
                                                .font(.system(size: 8, weight: .medium))
                                        } else {
                                            Text("→ different stage")
                                                .font(.system(size: 8, weight: .medium))
                                        }
                                    }
                                    .foregroundColor(severity)
                                    .padding(.horizontal, 6).padding(.vertical, 3)
                                    .background(severity.opacity(0.15))
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                                .offset(x: timeColumnWidth, y: yPos - 10)
                            }
                        }
                    }

                    // "Now" indicator — only when current time is within the day
                    let now = Date()
                    if now > dayStart && now < dayEnd {
                        let minsFromStart = Int(now.timeIntervalSince(dayStart)) / 60
                        let yPos = headerHeight + CGFloat(minsFromStart) / 30.0 * rowHeight
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.appCTA)
                                .frame(width: totalWidth - timeColumnWidth, height: 1.5)
                            Circle()
                                .fill(Color.appCTA)
                                .frame(width: 7, height: 7)
                        }
                        .id("now-line")
                        .offset(x: timeColumnWidth - 3, y: yPos - 0.75)
                    }
                }
                .frame(width: totalWidth, height: totalHeight)
            }
            .onAppear {
                let now = Date()
                if now > dayStart && now < dayEnd {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo("now-line", anchor: .center)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func blockOrigin(for set: FestivalSet) -> CGPoint {
        let stageIdx = stages.firstIndex(of: set.stageName) ?? 0
        let x = timeColumnWidth + CGFloat(stageIdx) * columnWidth
        let minsFromStart = Int(set.startTime.timeIntervalSince(dayStart)) / 60
        let y = headerHeight + CGFloat(minsFromStart) / 30.0 * rowHeight
        return CGPoint(x: x, y: y)
    }

    private func blockHeight(for set: FestivalSet) -> CGFloat {
        CGFloat(set.durationMinutes) / 30.0 * rowHeight
    }

    private func hourLabel(minuteOffset: Int) -> String {
        let date = Date(timeInterval: Double(minuteOffset * 60), since: dayStart)
        let f = DateFormatter()
        f.dateFormat = "h a"
        return f.string(from: date)
    }
}

#Preview {
    let sets = FestivalSet.mockSets.filter { $0.day == .saturday }
    let stages = Array(Set(sets.map { $0.stageName })).sorted()
    return TimetableGridView(
        sets: sets,
        stages: stages,
        scheduledSetIDs: [sets[0].id],
        onSetTap: { _ in }
    )
    .frame(height: 500)
    .preferredColorScheme(.dark)
}
