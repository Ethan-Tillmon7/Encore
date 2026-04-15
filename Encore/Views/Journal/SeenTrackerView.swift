// Encore/Views/Journal/SeenTrackerView.swift
import SwiftUI

struct SeenTrackerView: View {

    @EnvironmentObject var journalStore: JournalStore
    @EnvironmentObject var festivalStore: FestivalStore

    @State private var selectedFestivalFilter: UUID? = nil
    @State private var showLogEntry = false
    @State private var selectedEntry: JournalEntry? = nil
    @State private var showRatePastSets = false
    // Quick-log flow: QuickLogView dismisses, then we present SetJournalEntryView
    @State private var quickLogArtist: Artist? = nil
    @State private var quickLogFestival: Festival? = nil
    @State private var showCreateEntry = false

    // MARK: - Computed data

    private var filteredEntries: [JournalEntry] {
        let all = journalStore.entries.sorted { $0.dateAttended > $1.dateAttended }
        if let id = selectedFestivalFilter {
            return all.filter { $0.festivalID == id }
        }
        return all
    }

    /// One item per unique artistID. Rating = most recent entry's rating.
    private var seenArtists: [(artistID: UUID, artistName: String, rating: Int?)] {
        var seen: [UUID: (String, Int?)] = [:]
        for entry in filteredEntries where seen[entry.artistID] == nil {
            seen[entry.artistID] = (entry.artistName, entry.rating)
        }
        return seen
            .map { (artistID: $0.key, artistName: $0.value.0, rating: $0.value.1) }
            .sorted { $0.artistName < $1.artistName }
    }

    private func latestEntry(for artistID: UUID) -> JournalEntry? {
        filteredEntries.first { $0.artistID == artistID }
    }

    private var totalFestivals: Int {
        Set(journalStore.entries.map(\.festivalID)).count
    }

    private var avgRating: Double? {
        let rated = journalStore.entries.compactMap(\.rating)
        guard !rated.isEmpty else { return nil }
        return Double(rated.reduce(0, +)) / Double(rated.count)
    }

    private var unratedCount: Int {
        festivalStore.festivals
            .filter { $0.status == .past && !$0.lineup.isEmpty }
            .flatMap { festival in
                festival.lineup.filter { artist in
                    !journalStore.entries.contains {
                        $0.artistID == artist.id &&
                        $0.festivalID == festival.id &&
                        $0.rating != nil
                    }
                }
            }
            .count
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            statsStrip
                .padding(.horizontal, DS.Spacing.pageMargin)
                .padding(.vertical, 14)
                .background(Color.appBackground)

            if unratedCount > 0 {
                rateBanner
                    .padding(.top, 4)
                    .background(Color.appBackground)
            }

            if !festivalStore.festivals.isEmpty {
                festivalFilterRow
                    .padding(.horizontal, DS.Spacing.pageMargin)
                    .padding(.bottom, 10)
                    .background(Color.appBackground)
            }

            Divider()

            if seenArtists.isEmpty {
                emptyState
            } else {
                artistGrid
            }
        }
        .background(Color.appBackground)
        .navigationTitle("Journal")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showLogEntry = true }) {
                    Text("Log a Set")
                        .font(DS.Font.label)
                        .foregroundColor(.appCTA)
                }
            }
        }
        // Edit existing entry
        .sheet(item: $selectedEntry) { entry in
            SetJournalEntryView(entry: entry)
                .environmentObject(journalStore)
        }
        // Rate Past Sets
        .sheet(isPresented: $showRatePastSets) {
            RatePastSetsView()
                .environmentObject(journalStore)
                .environmentObject(festivalStore)
        }
        // Step 1+2: festival → artist picker
        .sheet(isPresented: $showLogEntry) {
            QuickLogView { artist, festival in
                quickLogArtist = artist
                quickLogFestival = festival
                // iOS requires a brief pause before presenting a new sheet
                // after the previous one finishes dismissing.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    showCreateEntry = true
                }
            }
            .environmentObject(festivalStore)
        }
        // Step 3: entry form for selected artist
        .sheet(isPresented: $showCreateEntry) {
            if let a = quickLogArtist, let f = quickLogFestival {
                SetJournalEntryView(artist: a, festival: f)
                    .environmentObject(journalStore)
            }
        }
    }

    // MARK: - Artist grid

    private var artistGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: DS.Spacing.cardGap
            ) {
                ForEach(seenArtists, id: \.artistID) { item in
                    ArtistGridCell(artistName: item.artistName, rating: item.rating)
                        .onTapGesture {
                            if let entry = latestEntry(for: item.artistID) {
                                selectedEntry = entry
                            }
                        }
                }
            }
            .padding(.horizontal, DS.Spacing.pageMargin)
            .padding(.vertical, DS.Spacing.cardGap)
        }
    }

    // MARK: - Stats strip

    private var statsStrip: some View {
        HStack(spacing: 0) {
            statCell(value: "\(journalStore.entries.count)", label: "sets seen")
            Divider().frame(height: 32)
            statCell(value: "\(totalFestivals)", label: "festivals")
            Divider().frame(height: 32)
            if let avg = avgRating {
                statCell(value: String(format: "★ %.1f", avg), label: "avg rating")
            } else {
                statCell(value: "★ —", label: "avg rating")
            }
        }
        .padding(.vertical, 8)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(DS.Font.stat)
                .foregroundColor(.appCTA)
                .minimumScaleFactor(0.5)
            Text(label)
                .font(DS.Font.caps)
                .foregroundColor(.appTextMuted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Rate banner

    private var rateBanner: some View {
        Button(action: { showRatePastSets = true }) {
            HStack(spacing: 10) {
                Image(systemName: "star.leadinghalf.filled")
                    .font(.system(size: 16))
                    .foregroundColor(.appCTA)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rate your history")
                        .font(DS.Font.listItem)
                        .foregroundColor(.appTextPrimary)
                    Text("\(unratedCount) set\(unratedCount == 1 ? "" : "s") unrated")
                        .font(DS.Font.metadata)
                        .foregroundColor(.appTextMuted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.appTextMuted)
            }
            .padding(DS.Spacing.cardPadding)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.chip)
                .stroke(Color.appCTA.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, DS.Spacing.pageMargin)
        .padding(.bottom, 4)
    }

    // MARK: - Festival filter

    private var festivalFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "All festivals", id: nil)
                ForEach(festivalStore.festivals) { festival in
                    filterChip(label: festival.name, id: festival.id)
                }
            }
        }
    }

    private func filterChip(label: String, id: UUID?) -> some View {
        let isSelected = selectedFestivalFilter == id
        return Button(action: { selectedFestivalFilter = id }) {
            Text(label)
                .font(DS.Font.label)
                .foregroundColor(isSelected ? Color.appBackground : .appTextMuted)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(isSelected ? Color.appCTA : Color.appSurface)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: DS.Spacing.sectionGap) {
            Image(systemName: "music.note.list")
                .font(.system(size: 40))
                .foregroundColor(Color.appTextMuted.opacity(0.3))
                .padding(.top, 60)
            Text("No sets logged yet.")
                .font(DS.Font.listItem)
                .foregroundColor(.appTextMuted)
            Text("Tap \"Log a Set\" to record your first set.")
                .font(DS.Font.metadata)
                .foregroundColor(Color.appTextMuted.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - ArtistGridCell

private struct ArtistGridCell: View {
    let artistName: String
    let rating: Int?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                Text(artistName.isEmpty ? "Unknown Artist" : artistName)
                    .font(DS.Font.listItem)
                    .foregroundColor(.appTextPrimary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
            }
            .padding(DS.Spacing.cardPadding)

            ratingBadge
                .padding(DS.Spacing.cardPadding)
        }
        .frame(minHeight: 90)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    @ViewBuilder
    private var ratingBadge: some View {
        if let rating = rating {
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.system(size: 9))
                        .foregroundColor(star <= rating ? DS.Journal.starFilled : DS.Journal.starEmpty)
                }
            }
        } else {
            Text("—")
                .font(.system(size: 11))
                .foregroundColor(.appTextMuted)
        }
    }
}

#Preview {
    let journal = JournalStore()
    journal.entries = JournalEntry.mockEntries
    let festival = FestivalStore()
    festival.festivals = Festival.mockFestivals
    return NavigationStack {
        SeenTrackerView()
            .environmentObject(journal)
            .environmentObject(festival)
    }
    .preferredColorScheme(.dark)
}
