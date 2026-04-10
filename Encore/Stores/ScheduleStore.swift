import Foundation
import Combine

struct WalkTimeWarning: Identifiable {
    let id = UUID()
    let setA: FestivalSet
    let setB: FestivalSet
    let gapMinutes: Int
    let walkMinutes: Int
    let shortfall: Int
}

class ScheduleStore: ObservableObject {

    @Published var scheduledSets: [FestivalSet] = []

    // MARK: - Schedule management

    func add(_ set: FestivalSet) {
        guard !isScheduled(set) else { return }
        scheduledSets.append(set)
    }

    func remove(_ set: FestivalSet) {
        scheduledSets.removeAll { $0.id == set.id }
    }

    func toggle(_ set: FestivalSet) {
        isScheduled(set) ? remove(set) : add(set)
    }

    func isScheduled(_ set: FestivalSet) -> Bool {
        scheduledSets.contains { $0.id == set.id }
    }

    // MARK: - Day-bucketed view

    func sets(for day: FestivalDay) -> [FestivalSet] {
        scheduledSets
            .filter { $0.day == day }
            .sorted { $0.startTime < $1.startTime }
    }

    // MARK: - Conflict detection

    var conflicts: [SetConflict] {
        var found: [SetConflict] = []
        let sorted = scheduledSets.sorted { $0.startTime < $1.startTime }
        for i in 0..<sorted.count {
            for j in (i+1)..<sorted.count {
                if sorted[i].overlaps(with: sorted[j]) {
                    found.append(SetConflict(setA: sorted[i], setB: sorted[j]))
                }
            }
        }
        return found
    }

    var hasConflicts: Bool { !conflicts.isEmpty }

    // MARK: - Resolve conflict

    /// Keep setA, remove setB (or vice versa)
    func resolveConflict(_ conflict: SetConflict, keep: FestivalSet) {
        let drop = conflict.setA.id == keep.id ? conflict.setB : conflict.setA
        remove(drop)
    }

    // MARK: - Walk time warnings

    func walkTimeWarnings(for day: FestivalDay) -> [WalkTimeWarning] {
        let sorted = sets(for: day)
        var warnings: [WalkTimeWarning] = []
        for i in 0..<(sorted.count - 1) {
            let a = sorted[i]
            let b = sorted[i + 1]
            guard a.stageName != b.stageName else { continue }
            let gapMinutes = Int(b.startTime.timeIntervalSince(a.endTime) / 60)
            guard let walk = StageWalkTime.minutes(from: a.stageName, to: b.stageName) else { continue }
            if gapMinutes < walk + 5 {
                let shortfall = max(0, walk - gapMinutes)
                warnings.append(WalkTimeWarning(
                    setA: a, setB: b,
                    gapMinutes: gapMinutes,
                    walkMinutes: walk,
                    shortfall: shortfall
                ))
            }
        }
        return warnings
    }
}
