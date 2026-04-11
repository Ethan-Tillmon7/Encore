// Encore/Stores/FestivalDiscoveryStore.swift
import Foundation
import Combine

// MARK: - Supporting Types

enum CampingFilter: String, CaseIterable, Identifiable {
    case any         = "Any"
    case campingOnly = "Camping"
    case noCamping   = "No Camping"

    var id: String { rawValue }
}

// MARK: - FestivalDiscoveryStore

/// Owns the full catalog of discoverable festivals and all browse/search filter state.
/// Separate from FestivalStore (which tracks the user's *active* festival context).
class FestivalDiscoveryStore: ObservableObject {

    // MARK: - Source data
    @Published var allFestivals: [Festival]

    // MARK: - Filters
    @Published var searchText: String = ""
    /// Artist name typed by the user — shows only festivals whose lineup contains a match.
    @Published var artistNameFilter: String = ""
    /// Selected genre names (top-level OR sub-genre). A festival matches if any of its genres
    /// or any of its artists' genres contains one of the selected values.
    @Published var selectedGenres: Set<String> = []
    @Published var campingFilter: CampingFilter = .any
    @Published var selectedStatus: FestivalStatus? = nil

    // MARK: - Init

    init(festivals: [Festival] = Festival.mockFestivals) {
        allFestivals = festivals
    }

    // MARK: - Computed: filtered list

    var filteredFestivals: [Festival] {
        var results = allFestivals

        // 1. Status pill
        if let status = selectedStatus {
            results = results.filter { $0.status == status }
        }

        // 2. Free-text search (festival name or city)
        let query = searchText.trimmingCharacters(in: .whitespaces)
        if !query.isEmpty {
            results = results.filter {
                $0.name.localizedCaseInsensitiveContains(query) ||
                $0.location.localizedCaseInsensitiveContains(query)
            }
        }

        // 3. Artist name filter — "show only festivals that feature X"
        let artistQuery = artistNameFilter.trimmingCharacters(in: .whitespaces)
        if !artistQuery.isEmpty {
            results = results.filter { festival in
                festival.lineup.contains {
                    $0.name.localizedCaseInsensitiveContains(artistQuery)
                }
            }
        }

        // 4. Genre filter — match top-level festival genres OR any artist's genres.
        //    A festival passes if it overlaps with *any* of the selected genres.
        if !selectedGenres.isEmpty {
            results = results.filter { festival in
                let festivalGenres = festival.genres.map { $0.lowercased() }
                let artistGenres   = festival.lineup.flatMap { $0.genres }.map { $0.lowercased() }
                let allGenres      = festivalGenres + artistGenres

                return selectedGenres.contains { selected in
                    let s = selected.lowercased()
                    // exact match first, then substring for compound names (e.g. "Indie Rock" ⊂ "Indie Rock, Post-Punk")
                    return allGenres.contains { $0 == s || $0.contains(s) || s.contains($0) }
                }
            }
        }

        // 5. Camping filter
        switch campingFilter {
        case .campingOnly: results = results.filter { $0.isCamping }
        case .noCamping:   results = results.filter { !$0.isCamping }
        case .any:         break
        }

        return results
    }

    // MARK: - Filter helpers

    var hasActiveFilters: Bool {
        activeFilterCount > 0
    }

    /// Count shown on the filter button badge.
    /// Counts artist filter, each selected genre, and camping filter as separate units.
    var activeFilterCount: Int {
        var n = 0
        if !artistNameFilter.trimmingCharacters(in: .whitespaces).isEmpty { n += 1 }
        n += selectedGenres.count
        if campingFilter != .any { n += 1 }
        return n
    }

    func clearFilters() {
        searchText        = ""
        artistNameFilter  = ""
        selectedGenres    = []
        campingFilter     = .any
        // intentionally leave selectedStatus — it's the primary nav filter
    }

    func toggleGenre(_ genre: String) {
        if selectedGenres.contains(genre) {
            selectedGenres.remove(genre)
        } else {
            selectedGenres.insert(genre)
        }
    }

    /// Toggle an entire top-level category: selects/deselects the category name itself.
    /// Sub-genre selections within it are left intact so the user doesn't lose drill-down choices.
    func toggleCategory(_ category: GenreCategory) {
        toggleGenre(category.name)
    }

    /// True when at least one genre within this category is selected.
    func isCategoryActive(_ category: GenreCategory) -> Bool {
        selectedGenres.contains(category.name) ||
        category.subcategories.contains { selectedGenres.contains($0) }
    }
}
