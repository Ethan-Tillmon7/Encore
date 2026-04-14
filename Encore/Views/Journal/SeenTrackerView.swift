// Encore/Views/Journal/SeenTrackerView.swift
import SwiftUI

struct SeenTrackerView: View {

    @EnvironmentObject var journalStore: JournalStore
    @EnvironmentObject var festivalStore: FestivalStore

    @State private var selectedFestivalFilter: UUID? = nil   // nil = all
    @State private var showLogEntry = false
    @State private var selectedEntry: JournalEntry? = nil
    @State private var pushArtistHistory: UUID? = nil         // artist ID to push history for
    @State private var showRatePastSets = false

    private var filteredEntries: [JournalEntry] {
        let all = journalStore.entries.sorted { $0.dateAttended > $1.dateAttended }
        if let id = selectedFestivalFilter {
            return all.filter { $0.festivalID == id }
        }
        return all
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

    var body: some View {
        VStack(spacing: 0) {
            // Stats strip
            statsStrip
                .padding(.horizontal, DS.Spacing.pageMargin)
                .padding(.vertical, 14)
                .background(Color.appBackground)

            // Rate Past Sets banner
            if unratedCount > 0 {
                rateBanner
                    .padding(.top, 4)
                    .background(Color.appBackground)
            }

            // Festival filter
            if !festivalStore.festivals.isEmpty {
                festivalFilterRow
                    .padding(.horizontal, DS.Spacing.pageMargin)
                    .padding(.bottom, 10)
                    .background(Color.appBackground)
            }

            Divider()

            if filteredEntries.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: DS.Spacing.cardGap) {
                        ForEach(filteredEntries) { entry in
                            JournalEntryRowView(entry: entry)
                                .onTapGesture { selectedEntry = entry }
                        }
                    }
                    .padding(.horizontal, DS.Spacing.pageMargin)
                    .padding(.vertical, DS.Spacing.cardGap)
                }
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
        .sheet(item: $selectedEntry) { entry in
            SetJournalEntryView(entry: entry)
                .environmentObject(journalStore)
        }
        .sheet(isPresented: $showRatePastSets) {
            RatePastSetsView()
                .environmentObject(journalStore)
                .environmentObject(festivalStore)
        }
        .sheet(isPresented: $showLogEntry) {
            // TODO: show artist picker first; for now show create mode with first artist
            SetJournalEntryView(festivalSet: nil, existingEntry: nil)
                .environmentObject(journalStore)
        }
    }

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

    private var emptyState: some View {
        VStack(spacing: DS.Spacing.sectionGap) {
            Image(systemName: "book.closed")
                .font(.system(size: 40))
                .foregroundColor(Color.appTextMuted.opacity(0.3))
                .padding(.top, 60)
            Text("No sets logged yet.")
                .font(DS.Font.listItem)
                .foregroundColor(.appTextMuted)
            Text("After a show, open the artist's page and tap 'Log this set.'")
                .font(DS.Font.metadata)
                .foregroundColor(Color.appTextMuted.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
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
