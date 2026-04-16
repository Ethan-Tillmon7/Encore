// Encore/Services/EDMTrainService.swift
import Foundation

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Response DTOs
// ─────────────────────────────────────────────────────────────────────────────

private struct EDMTrainResponse: Decodable {
    let success: Bool
    let data: [EDMTrainEventRow]?
}

private struct EDMTrainEventRow: Decodable {
    let id: Int
    let link: String?
    let date: String?           // "YYYY-MM-DD"
    let name: String?
    let artists: [EDMTrainArtistRow]?
    let venue: EDMTrainVenueRow?
}

private struct EDMTrainArtistRow: Decodable {
    let name: String
}

private struct EDMTrainVenueRow: Decodable {
    let name: String?
    let location: String?       // "City, State"
    let latitude: Double?
    let longitude: Double?
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - EDMTrainService
// ─────────────────────────────────────────────────────────────────────────────

actor EDMTrainService {

    static let shared = EDMTrainService()

    // ── Location mapping ─────────────────────────────────────────────────────

    /// Metro areas mapped to their EDM Train location IDs.
    /// IDs sourced from: GET https://edmtrain.com/api/locations?client=<key>
    private static let metroLocations: [(name: String, lat: Double, lon: Double, id: Int)] = [
        ("Los Angeles",   34.0522, -118.2437,  73),
        ("San Francisco", 37.7749, -122.4194,  72),
        ("New York",      40.7128,  -74.0060,  70),
        ("Chicago",       41.8781,  -87.6298,  71),
        ("Miami",         25.7617,  -80.1918,  87),
        ("Las Vegas",     36.1699, -115.1398,  69),
        ("Denver",        39.7392, -104.9903,  76),
        ("Seattle",       47.6062, -122.3321,  77),
        ("Austin",        30.2672,  -97.7431,  78),
        ("Atlanta",       33.7490,  -84.3880,  84),
        ("Nashville",     36.1627,  -86.7816, 370),
        ("New Orleans",   29.9511,  -90.0715,  95),
    ]

    private static let defaultLocationId = metroLocations[0].id  // Los Angeles fallback

    /// Returns the EDM Train location ID nearest to the given coordinates.
    /// Falls back to Los Angeles if coordinates are (0, 0) or no metros are defined.
    static func nearestLocationId(latitude: Double, longitude: Double) -> Int {
        // (0, 0) is the Festival default when Supabase omits coordinates
        guard latitude != 0 || longitude != 0 else { return defaultLocationId }

        var closest = metroLocations[0]
        var minDist = haversineKm(lat1: latitude, lon1: longitude,
                                  lat2: closest.lat, lon2: closest.lon)
        for metro in metroLocations.dropFirst() {
            let dist = haversineKm(lat1: latitude, lon1: longitude,
                                   lat2: metro.lat, lon2: metro.lon)
            if dist < minDist {
                minDist = dist
                closest = metro
            }
        }
        return closest.id
    }

    // ── Event fetch ──────────────────────────────────────────────────────────

    func fetchEvents(locationId: Int) async throws -> [Festival] {
        var components = URLComponents(string: "https://edmtrain.com/api/events")!
        components.queryItems = [
            URLQueryItem(name: "locationIds", value: "\(locationId)"),
            URLQueryItem(name: "client",      value: APIKeys.edmTrain),
        ]
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let response  = try JSONDecoder().decode(EDMTrainResponse.self, from: data)
        return (response.data ?? []).compactMap { toFestival($0) }
    }

    // ── Mapping ──────────────────────────────────────────────────────────────

    private func toFestival(_ row: EDMTrainEventRow) -> Festival? {
        guard let dateStr = row.date, let date = parseDate(dateStr) else { return nil }

        let artistNames = (row.artists ?? []).map(\.name)
        let eventName   = row.name.flatMap { $0.isEmpty ? nil : $0 }
                          ?? (artistNames.isEmpty ? "Electronic Event"
                                                  : artistNames.prefix(3).joined(separator: " & "))

        // Deterministic UUID: fixed prefix + EDM Train event ID in last 12 hex chars — guaranteed unique within EDM Train events
        let paddedHex  = String(format: "%012x", row.id)
        let uuidString = "00000000-0000-4000-8000-\(paddedHex)"
        let eventId    = UUID(uuidString: uuidString) ?? UUID()

        return Festival(
            id:            eventId,
            name:          eventName,
            slug:          "edmtrain-\(row.id)",   // "edmtrain-" prefix avoids collision with Supabase slugs; not used as a store lookup key
            location:      row.venue?.location ?? "",
            latitude:      row.venue?.latitude  ?? 0,
            longitude:     row.venue?.longitude ?? 0,
            startDate:     date,
            endDate:       date,        // single-day events: start == end
            status:        festivalStatus(for: date),
            isCamping:     false,
            genres:        ["Electronic"],
            imageColorHex: "4ECDC4",    // teal default for EDM events
            lineup:        [],
            sets:          [],
            source:        .edmTrain,
            eventURL:      row.link.flatMap { URL(string: $0) }
        )
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    private func parseDate(_ string: String) -> Date? {
        dateFormatter.date(from: String(string.prefix(10)))
    }

    private func festivalStatus(for date: Date) -> FestivalStatus {
        let now  = Date()
        let cal  = Calendar(identifier: .gregorian)
        // Use start-of-day comparison so events on today's date show as .active
        let startOfToday    = cal.startOfDay(for: now)
        let startOfTomorrow = cal.date(byAdding: .day, value: 1, to: startOfToday)!
        let startOfDate     = cal.startOfDay(for: date)
        if startOfDate >= startOfToday && startOfDate < startOfTomorrow { return .active }
        return startOfDate > startOfToday ? .upcoming : .past
    }

    private static func haversineKm(lat1: Double, lon1: Double,
                                    lat2: Double, lon2: Double) -> Double {
        let R  = 6371.0
        let φ1 = lat1 * .pi / 180
        let φ2 = lat2 * .pi / 180
        let Δφ = (lat2 - lat1) * .pi / 180
        let Δλ = (lon2 - lon1) * .pi / 180
        let a  = sin(Δφ/2) * sin(Δφ/2) + cos(φ1) * cos(φ2) * sin(Δλ/2) * sin(Δλ/2)
        return R * 2 * atan2(sqrt(a), sqrt(1-a))
    }
}
