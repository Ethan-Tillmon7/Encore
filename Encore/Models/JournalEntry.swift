// Encore/Models/JournalEntry.swift
import Foundation

enum WouldSeeAgain: String, Codable {
    case yes, maybe, no
}

struct JournalEntry: Identifiable, Codable {
    var id: UUID
    var artistID: UUID
    var festivalID: UUID
    var setID: UUID
    var dateAttended: Date
    var rating: Int?
    var notes: String
    var highlights: [String]
    var wouldSeeAgain: WouldSeeAgain?
}
