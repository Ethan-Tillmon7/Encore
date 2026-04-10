// Encore/Models/Festival.swift
import Foundation

enum FestivalStatus: String, Codable {
    case upcoming, active, past
}

struct Festival: Identifiable, Codable {
    var id: UUID
    var name: String
    var location: String
    var startDate: Date
    var endDate: Date
    var status: FestivalStatus
    var genres: [String]
    var imageColorHex: String
    var lineup: [Artist]
    var sets: [FestivalSet]
}
