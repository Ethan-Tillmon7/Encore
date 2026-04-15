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
    var artistName: String
    var festivalName: String

    init(
        id: UUID,
        artistID: UUID,
        festivalID: UUID,
        setID: UUID,
        dateAttended: Date,
        rating: Int?,
        notes: String,
        highlights: [String],
        wouldSeeAgain: WouldSeeAgain?,
        artistName: String = "",
        festivalName: String = ""
    ) {
        self.id = id
        self.artistID = artistID
        self.festivalID = festivalID
        self.setID = setID
        self.dateAttended = dateAttended
        self.rating = rating
        self.notes = notes
        self.highlights = highlights
        self.wouldSeeAgain = wouldSeeAgain
        self.artistName = artistName
        self.festivalName = festivalName
    }

    // Custom Decodable: decodes new fields with fallback for pre-existing persisted entries.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id           = try c.decode(UUID.self,            forKey: .id)
        artistID     = try c.decode(UUID.self,            forKey: .artistID)
        festivalID   = try c.decode(UUID.self,            forKey: .festivalID)
        setID        = try c.decode(UUID.self,            forKey: .setID)
        dateAttended = try c.decode(Date.self,            forKey: .dateAttended)
        rating       = try c.decodeIfPresent(Int.self,    forKey: .rating)
        notes        = try c.decode(String.self,          forKey: .notes)
        highlights   = try c.decode([String].self,        forKey: .highlights)
        wouldSeeAgain = try c.decodeIfPresent(WouldSeeAgain.self, forKey: .wouldSeeAgain)
        artistName   = (try? c.decodeIfPresent(String.self,  forKey: .artistName))  ?? ""
        festivalName = (try? c.decodeIfPresent(String.self,  forKey: .festivalName)) ?? ""
    }
}
