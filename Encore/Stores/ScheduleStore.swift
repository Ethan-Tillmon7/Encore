import Foundation
import Combine

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
}
