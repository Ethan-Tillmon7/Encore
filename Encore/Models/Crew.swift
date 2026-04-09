import Foundation
import SwiftUI

// MARK: - Crew Member

struct CrewMember: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var colorHex: String          // personal color for timeline
    var scheduledSetIDs: [UUID]   // IDs of FestivalSets they've added
    var isOnline: Bool
    var lastSeenStage: String?    // e.g. "What Stage · 4 min ago"

    var color: Color {
        Color(hex: colorHex) ?? .purple
    }

    var initials: String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }
}

// MARK: - Crew

struct Crew: Identifiable, Codable {
    let id: UUID
    var name: String
    var inviteCode: String        // short alphanumeric code
    var members: [CrewMember]

    static func generateInviteCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}

// MARK: - Meetup Pin

struct MeetupPin: Identifiable, Codable {
    let id: UUID
    var label: String             // e.g. "Meet us here after LCD!"
    var latitude: Double
    var longitude: Double
    var createdBy: UUID           // CrewMember.id
}

// MARK: - Color hex helper

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.hasPrefix("#") ? String(hexSanitized.dropFirst()) : hexSanitized
        guard hexSanitized.count == 6,
              let value = UInt64(hexSanitized, radix: 16) else { return nil }
        let r = Double((value & 0xFF0000) >> 16) / 255
        let g = Double((value & 0x00FF00) >> 8)  / 255
        let b = Double(value & 0x0000FF)          / 255
        self.init(red: r, green: g, blue: b)
    }
}
