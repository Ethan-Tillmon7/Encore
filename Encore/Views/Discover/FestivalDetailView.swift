// Encore/Views/Discover/FestivalDetailView.swift
import SwiftUI

struct FestivalDetailView: View {

    let festival: Festival

    @EnvironmentObject var festivalStore:  FestivalStore
    @EnvironmentObject var journalStore:   JournalStore
    @EnvironmentObject var scheduleStore:  ScheduleStore
    @EnvironmentObject var crewStore:      CrewStore

    @State private var selectedArtistSet: FestivalSet? = nil
    @State private var showTravelDetails = false

    private var accentColor: Color {
        Color(hex: festival.imageColorHex) ?? .appCTA
    }

    private var seenEntries: [JournalEntry] {
        journalStore.entries(forFestival: festival.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Hero
                festivalHero

                // "Set as active" CTA
                if festival.status == .active || festival.status == .upcoming {
                    setActiveCTA
                }

                Divider()

                // Lineup section
                lineupSection

                Divider()

                // Your history
                historySection

                Divider()

                // Travel details row
                Button(action: { showTravelDetails = true }) {
                    HStack {
                        Label("Travel Details", systemImage: "suitcase")
                            .font(DS.Font.listItem)
                            .foregroundColor(.appTextPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(DS.Font.metadata)
                            .foregroundColor(.appTextMuted)
                    }
                    .padding(DS.Spacing.cardPadding)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DS.Spacing.pageMargin)
            .padding(.vertical, DS.Spacing.cardGap)
        }
        .background(Color.appBackground)
        .navigationTitle(festival.name)
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedArtistSet) { set in
            ArtistDetailView(festivalSet: set)
                .environmentObject(scheduleStore)
                .environmentObject(crewStore)
                .environmentObject(LineupStore())
                .environmentObject(journalStore)
        }
        .sheet(isPresented: $showTravelDetails) {
            TravelDetailsView(festivalID: festival.id)
                .environmentObject(festivalStore)
        }
    }

    // MARK: - Hero

    private var festivalHero: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sectionGap) {
            HStack(spacing: 8) {
                statusPill
                if festival.isCamping {
                    Label("Camping", systemImage: "tent.fill")
                        .font(DS.Font.caps)
                        .foregroundColor(.appTextMuted)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color.appSurface)
                        .clipShape(Capsule())
                }
                Spacer()
            }
            Text("\(dateRangeLabel)  ·  \(festival.location)")
                .font(DS.Font.listItem)
                .foregroundColor(.appTextMuted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(festival.genres, id: \.self) { genre in
                        Text(genre)
                            .font(DS.Font.caps)
                            .foregroundColor(accentColor)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(accentColor.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var statusPill: some View {
        switch festival.status {
        case .active:
            Label("Happening Now", systemImage: "circle.fill")
                .font(DS.Font.label)
                .foregroundColor(.appCTA)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Color.appCTA.opacity(0.15))
                .clipShape(Capsule())
        case .upcoming:
            Text("Upcoming · \(daysUntilLabel)")
                .font(DS.Font.label)
                .foregroundColor(.appAccent)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Color.appAccent.opacity(0.15))
                .clipShape(Capsule())
        case .past:
            Text("Past")
                .font(DS.Font.label)
                .foregroundColor(.appTextMuted)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Color.appSurface)
                .clipShape(Capsule())
        }
    }

    // MARK: - CTA

    private var setActiveCTA: some View {
        let isSelected = festivalStore.selectedFestival?.id == festival.id
        return Button(action: { festivalStore.selectFestival(festival) }) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                Text(isSelected ? "Your active festival" : "Set as my festival")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? Color.appSurface : accentColor.opacity(0.15))
            .foregroundColor(isSelected ? .appTextMuted : accentColor)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(accentColor.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Lineup

    private var lineupSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sectionGap) {
            HStack {
                sectionLabel("Lineup")
                Spacer()
                if !festival.sets.isEmpty {
                    NavigationLink(destination:
                        LineupView()
                            .environmentObject(LineupStore())
                            .environmentObject(scheduleStore)
                            .environmentObject(crewStore)
                    ) {
                        Text("See full lineup →")
                            .font(DS.Font.metadata)
                            .foregroundColor(accentColor)
                    }
                }
            }

            if festival.lineup.isEmpty {
                Text("Lineup not announced yet.")
                    .font(DS.Font.metadata)
                    .foregroundColor(.appTextMuted)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(festival.lineup.prefix(12)) { artist in
                            let matchingSet = festival.sets.first(where: { $0.artist.id == artist.id })
                            Button(action: {
                                if let set = matchingSet { selectedArtistSet = set }
                            }) {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(artist.matchTier.color)
                                        .frame(width: 8, height: 8)
                                    Text(artist.name)
                                        .font(DS.Font.metadata)
                                        .foregroundColor(matchingSet != nil ? .appTextPrimary : .appTextMuted)
                                }
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(Color.appSurface)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .disabled(matchingSet == nil)
                        }
                    }
                }
            }
        }
    }

    // MARK: - History

    @ViewBuilder
    private var historySection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sectionGap) {
            sectionLabel("Your History")
            if seenEntries.isEmpty {
                Text("You haven't attended this festival yet.")
                    .font(DS.Font.metadata)
                    .foregroundColor(.appTextMuted)
            } else {
                let avgRating: Double? = {
                    let rated = seenEntries.compactMap(\.rating)
                    guard !rated.isEmpty else { return nil }
                    return Double(rated.reduce(0, +)) / Double(rated.count)
                }()
                HStack(spacing: 20) {
                    VStack(spacing: 2) {
                        Text("\(seenEntries.count)")
                            .font(DS.Font.stat)
                            .foregroundColor(.appCTA)
                        Text("sets seen")
                            .font(DS.Font.caps)
                            .foregroundColor(.appTextMuted)
                    }
                    if let avg = avgRating {
                        VStack(spacing: 2) {
                            Text(String(format: "★ %.1f", avg))
                                .font(DS.Font.stat)
                                .foregroundColor(.appCTA)
                            Text("avg rating")
                                .font(DS.Font.caps)
                                .foregroundColor(.appTextMuted)
                        }
                    }
                }
                .padding(DS.Spacing.cardPadding)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
            }
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(DS.Font.label)
            .foregroundColor(.appTextMuted)
            .textCase(.uppercase)
            .tracking(0.8)
    }

    private var dateRangeLabel: String {
        let f = DateFormatter(); f.dateFormat = "MMM d"
        let g = DateFormatter(); g.dateFormat = "d, yyyy"
        return "\(f.string(from: festival.startDate))–\(g.string(from: festival.endDate))"
    }

    private var daysUntilLabel: String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: festival.startDate).day ?? 0
        return days > 0 ? "In \(days) days" : "Soon"
    }
}

#Preview {
    let festivals = FestivalStore()
    festivals.festivals = Festival.mockFestivals
    festivals.selectedFestival = Festival.mockFestivals[1]
    let journal = JournalStore()
    journal.entries = JournalEntry.mockEntries
    return NavigationStack {
        FestivalDetailView(festival: Festival.mockFestivals[1])
            .environmentObject(festivals)
            .environmentObject(journal)
            .environmentObject(ScheduleStore())
            .environmentObject(CrewStore())
    }
    .preferredColorScheme(.dark)
}
