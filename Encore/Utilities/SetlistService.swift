// Encore/Utilities/SetlistService.swift
import Foundation

actor SetlistService {

    static let shared = SetlistService()

    private let base = "https://api.setlist.fm/rest/1.0"
    private var cache: [String: [String]] = [:]

    // MARK: - Public

    func fetchRecentSetlist(for artistName: String) async throws -> [String] {
        if let hit = cache[artistName] { return hit }

        let mbid = try await searchMBID(for: artistName)
        guard let mbid else {
            cache[artistName] = []
            return []
        }

        let songs = try await fetchSongs(mbid: mbid)
        cache[artistName] = songs
        return songs
    }

    // MARK: - Private

    private func searchMBID(for artistName: String) async throws -> String? {
        guard let encoded = artistName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(base)/search/artists?artistName=\(encoded)&p=1&sort=relevance")
        else { return nil }

        do {
            let data = try await fetch(url: url)
            let result = try JSONDecoder().decode(ArtistSearchResponse.self, from: data)
            return result.artist?.first?.mbid
        } catch is NotFound { return nil }
    }

    private func fetchSongs(mbid: String) async throws -> [String] {
        guard let url = URL(string: "\(base)/artist/\(mbid)/setlists?p=1") else { return [] }

        do {
            let data = try await fetch(url: url)
            let result = try JSONDecoder().decode(SetlistResponse.self, from: data)
            return result.setlist?.first.map { item in
                item.sets.set.flatMap { $0.song ?? [] }.map { $0.name }
            } ?? []
        } catch is NotFound { return [] }
    }

    private func fetch(url: URL) async throws -> Data {
        var req = URLRequest(url: url)
        req.setValue(APIKeys.setlistFM, forHTTPHeaderField: "x-api-key")
        req.setValue("application/json",  forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if http.statusCode == 404 { throw NotFound() }
        guard http.statusCode == 200 else { throw URLError(.badServerResponse) }
        return data
    }

    private struct NotFound: Error {}
}

// MARK: - Decodable models (private to this file)

private struct ArtistSearchResponse: Decodable {
    let artist: [ArtistResult]?
}
private struct ArtistResult: Decodable {
    let mbid: String
}
private struct SetlistResponse: Decodable {
    let setlist: [SetlistItem]?
}
private struct SetlistItem: Decodable {
    let sets: SetContainer
}
private struct SetContainer: Decodable {
    let set: [SetGroup]
}
private struct SetGroup: Decodable {
    let song: [Song]?
}
private struct Song: Decodable {
    let name: String
}
