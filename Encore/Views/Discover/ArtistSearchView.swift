// Encore/Views/Discover/ArtistSearchView.swift
import SwiftUI

struct ArtistSearchView: View {

    @EnvironmentObject var discoveryStore: FestivalDiscoveryStore
    @EnvironmentObject var festivalStore:  FestivalStore
    @EnvironmentObject var journalStore:   JournalStore
    @EnvironmentObject var scheduleStore:  ScheduleStore
    @EnvironmentObject var crewStore:      CrewStore

    @State private var searchText  = ""
    @State private var tierFilter:  MatchTier? = nil
    @State private var selectedSet: FestivalSet? = nil

    @Environment(\.dismiss) private var dismiss

    private var allArtists: [(artist: Artist, festival: Festival, set: FestivalSet?)] {
        var result: [(Artist, Festival, FestivalSet?)] = []
        for festival in discoveryStore.allFestivals {
            for artist in festival.lineup {
                let set = festival.sets.first(where: { $0.artist.id == artist.id })
                result.append((artist, festival, set))
            }
        }
        // Remove duplicates by artist name (same artist appears at multiple festivals)
        var seen = Set<String>()
        return result.filter { seen.insert($0.0.name.lowercased()).inserted }
    }

    private var filteredArtists: [(artist: Artist, festival: Festival, set: FestivalSet?)] {
        allArtists.filter { item in
            let matchesSearch = searchText.isEmpty ||
                item.artist.name.localizedCaseInsensitiveContains(searchText) ||
                item.artist.genres.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            let matchesTier = tierFilter == nil || item.artist.matchTier == tierFilter
            return matchesSearch && matchesTier
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tier filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        tierChip(label: "All", tier: nil)
                        ForEach(MatchTier.allCases.filter { $0 != .unknown }) { tier in
                            tierChip(label: tier.rawValue, tier: tier)
                        }
                    }
                    .padding(.horizontal, DS.Spacing.pageMargin)
                    .padding(.vertical, 10)
                }
                .background(Color.appBackground)

                Divider()

                if filteredArtists.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(filteredArtists, id: \.artist.id) { item in
                            Button(action: {
                                if let set = item.set { selectedSet = set }
                            }) {
                                artistRow(item: item)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.appSurface)
                            .listRowSeparatorTint(Color.appAccent.opacity(0.2))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.appBackground)
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Artist Search")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Artist, genre...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.appCTA)
                }
            }
            .sheet(item: $selectedSet) { set in
                ArtistDetailView(festivalSet: set)
                    .environmentObject(scheduleStore)
                    .environmentObject(crewStore)
                    .environmentObject(LineupStore())
                    .environmentObject(journalStore)
            }
        }
    }

    private func artistRow(item: (artist: Artist, festival: Festival, set: FestivalSet?)) -> some View {
        HStack(spacing: 12) {
            // Tier color dot
            Circle()
                .fill(item.artist.matchTier.color)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.artist.name)
                        .font(DS.Font.listItem)
                        .foregroundColor(.appTextPrimary)
                    if journalStore.hasSeenArtist(item.artist.id) {
                        Text("Seen")
                            .font(DS.Font.caps)
                            .foregroundColor(.appCTA)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.appCTA.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                Text(item.artist.genres.prefix(2).joined(separator: "  ·  "))
                    .font(DS.Font.metadata)
                    .foregroundColor(.appTextMuted)
            }

            Spacer()

            if item.set != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(.appTextMuted)
            }
        }
        .padding(.vertical, 6)
    }

    private func tierChip(label: String, tier: MatchTier?) -> some View {
        let isSelected = tierFilter == tier
        return Button(action: { tierFilter = tier }) {
            Text(label)
                .font(DS.Font.label)
                .foregroundColor(isSelected ? Color.appBackground : .appTextMuted)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(isSelected ? Color.appCTA : Color.appSurface)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: DS.Spacing.sectionGap) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundColor(Color.appTextMuted.opacity(0.3))
                .padding(.top, 60)
            Text("No artists match your search.")
                .font(DS.Font.listItem)
                .foregroundColor(.appTextMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let journal = JournalStore()
    journal.entries = JournalEntry.mockEntries
    return ArtistSearchView()
        .environmentObject(FestivalDiscoveryStore())
        .environmentObject(FestivalStore())
        .environmentObject(journal)
        .environmentObject(ScheduleStore())
        .environmentObject(CrewStore())
        .preferredColorScheme(.dark)
}
