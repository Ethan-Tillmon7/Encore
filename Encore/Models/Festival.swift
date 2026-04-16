// Encore/Models/Festival.swift
import Foundation

enum FestivalSource: String, Codable {
    case supabase
    case edmTrain
}

enum FestivalStatus: String, Codable {
    case upcoming, active, past
}

struct Festival: Identifiable, Codable {
    var id: UUID
    var name: String
    var slug: String
    var location: String
    var latitude: Double
    var longitude: Double
    var startDate: Date
    var endDate: Date
    var status: FestivalStatus
    var isCamping: Bool
    var genres: [String]
    var imageColorHex: String
    var lineup: [Artist]
    var sets: [FestivalSet]
    var source: FestivalSource = .supabase
    var eventURL: URL?

    /// Classifies the festival into a broad geographic region using its coordinates.
    var region: RegionFilter {
        // Outside continental US + Alaska/Hawaii bounds → International
        guard latitude >= 24 && latitude <= 72 && longitude >= -180 && longitude <= -67 else {
            return .international
        }
        // West: CA, OR, WA, NV, ID, MT, WY, UT, CO (roughly west of -114)
        if longitude <= -114 { return .west }
        // Southwest: AZ, NM, TX, OK — south of 37°, between -114 and -93
        if latitude < 37 && longitude > -114 && longitude <= -93 { return .southwest }
        // Midwest: IL, MI, MN, WI, IA, IN, OH, MO, KS, NE, SD, ND — north of 36°, between -104 and -80
        if latitude >= 36 && longitude > -104 && longitude <= -80 { return .midwest }
        // Southeast: TN, GA, FL, NC, SC, VA, AL, MS, AR, LA — south of 37°, east of -93
        if latitude < 37 && longitude > -93 { return .southeast }
        // Northeast: NY, PA, MA, CT, etc. — north of 37°, east of -80
        if latitude >= 37 && longitude > -80 { return .northeast }
        return .west
    }
}
