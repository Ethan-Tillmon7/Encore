import Foundation

// MARK: - Festival Day

enum FestivalDay: String, CaseIterable, Codable, Identifiable {
    case thursday  = "Thu"
    case friday    = "Fri"
    case saturday  = "Sat"
    case sunday    = "Sun"

    var id: String { rawValue }

    var fullName: String {
        switch self {
        case .thursday:  return "Thursday"
        case .friday:    return "Friday"
        case .saturday:  return "Saturday"
        case .sunday:    return "Sunday"
        }
    }
}

// MARK: - Festival Set

struct FestivalSet: Identifiable, Codable, Hashable {
    let id: UUID
    var artist: Artist
    var stageName: String
    var day: FestivalDay
    var startTime: Date
    var endTime: Date

    var durationMinutes: Int {
        Int(endTime.timeIntervalSince(startTime) / 60)
    }

    var timeRangeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: startTime)) – \(formatter.string(from: endTime))"
    }

    func overlaps(with other: FestivalSet) -> Bool {
        guard day == other.day else { return false }
        return startTime < other.endTime && endTime > other.startTime
    }
}

// MARK: - Conflict

struct SetConflict: Identifiable {
    let id = UUID()
    let setA: FestivalSet
    let setB: FestivalSet

    var overlapMinutes: Int {
        let overlapStart = max(setA.startTime, setB.startTime)
        let overlapEnd   = min(setA.endTime, setB.endTime)
        return max(0, Int(overlapEnd.timeIntervalSince(overlapStart) / 60))
    }
}
