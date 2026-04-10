// Encore/Views/Lineup/LineupView.swift
import SwiftUI

struct LineupView: View {

    @EnvironmentObject var lineupStore:   LineupStore
    @EnvironmentObject var scheduleStore: ScheduleStore
    @EnvironmentObject var crewStore:     CrewStore

    @State private var selectedDay: FestivalDay = .thursday
    @State private var selectedSet: FestivalSet? = nil
    @State private var walkSetA: FestivalSet? = nil
    @State private var walkSetB: FestivalSet? = nil
    @State private var isListMode: Bool = false
    @State private var showGroupPlanner: Bool = false

    private var showWalkTime: Bool { walkSetA != nil && walkSetB != nil }

    private var stages: [String] {
        Array(Set(lineupStore.allSets.map { $0.stageName })).sorted()
    }

    private var setsForDay: [FestivalSet] {
        lineupStore.allSets.filter { $0.day == selectedDay }
    }

    private var scheduledIDs: Set<UUID> {
        Set(scheduleStore.scheduledSets.map { $0.id })
    }

    var body: some View {
        VStack(spacing: 0) {
            topControlsBar
                .padding(.horizontal, DS.Spacing.pageMargin)
                .padding(.vertical, 10)
                .background(Color.appBackground)

            if isListMode {
                listModeFiltersRow
            }

            if isListMode {
                listContent
            } else {
                TimetableGridView(
                    sets: setsForDay,
                    stages: stages,
                    scheduledSetIDs: scheduledIDs,
                    onSetTap:  { selectedSet = $0 },
                    onWalkTap: { a, b in walkSetA = a; walkSetB = b }
                )
            }
        }
        .background(Color.appBackground)
        .navigationTitle("Lineup")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showGroupPlanner = true }) {
                    Image(systemName: "person.2")
                        .foregroundColor(.appCTA)
                }
            }
        }
        .sheet(item: $selectedSet) { set in
            ArtistDetailView(festivalSet: set)
                .environmentObject(scheduleStore)
                .environmentObject(crewStore)
                .environmentObject(lineupStore)
                .environmentObject(JournalStore())
        }
        .sheet(isPresented: Binding(
            get: { showWalkTime },
            set: { if !$0 { walkSetA = nil; walkSetB = nil } }
        )) {
            if let a = walkSetA, let b = walkSetB {
                WalkTimeView(setA: a, setB: b)
                    .presentationDetents([.medium, .large])
            }
        }
        .sheet(isPresented: $showGroupPlanner) {
            GroupPlannerView()
                .environmentObject(scheduleStore)
                .environmentObject(crewStore)
                .environmentObject(lineupStore)
        }
    }

    // MARK: - Top Controls Bar

    private var topControlsBar: some View {
        HStack(spacing: 8) {
            // Day picker (expands to fill)
            HStack(spacing: 0) {
                ForEach(FestivalDay.allCases) { day in
                    Button(action: { selectedDay = day; lineupStore.selectedDay = day }) {
                        Text(day.fullName)
                            .font(selectedDay == day ? DS.Font.label : DS.Font.metadata)
                            .foregroundColor(selectedDay == day ? .appCTA : .appTextMuted)
                            .frame(maxWidth: .infinity)
                            .frame(height: DS.RowHeight.dayPicker)
                            .background(selectedDay == day
                                ? Color.appCTA.opacity(0.12) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))

            // Grid / List toggle
            Button(action: { withAnimation { isListMode.toggle() } }) {
                Image(systemName: isListMode ? "rectangle.grid.2x2" : "list.bullet")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.appCTA)
                    .frame(width: 40, height: DS.RowHeight.dayPicker)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - List Mode Filters

    private var listModeFiltersRow: some View {
        VStack(spacing: 8) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.appTextMuted)
                    .font(.system(size: 13))
                TextField("Search artists...", text: $lineupStore.searchText)
                    .font(DS.Font.listItem)
                    .foregroundColor(.appTextPrimary)
                if !lineupStore.searchText.isEmpty {
                    Button(action: { lineupStore.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.appTextMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))

            // Tier filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    tierChip(label: "All", tier: nil)
                    tierChip(label: "Must-see", tier: .mustSee)
                    tierChip(label: "Worth checking", tier: .worthChecking)
                    tierChip(label: "Explore", tier: .explore)
                }
            }
        }
        .padding(.horizontal, DS.Spacing.pageMargin)
        .padding(.bottom, 8)
    }

    private func tierChip(label: String, tier: MatchTier?) -> some View {
        let isSelected = lineupStore.selectedTier == tier
        return Button(action: { lineupStore.selectedTier = tier }) {
            Text(label)
                .font(DS.Font.label)
                .foregroundColor(isSelected ? Color.appBackground : .appTextMuted)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(isSelected ? Color.appCTA : Color.appSurface)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - List Mode Content

    private var listContent: some View {
        let sets = lineupStore.filteredSets.filter { $0.day == selectedDay }
        return ScrollView {
            LazyVStack(spacing: DS.Spacing.cardGap) {
                if sets.isEmpty {
                    Text("No artists match your filters.")
                        .font(DS.Font.listItem)
                        .foregroundColor(.appTextMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else {
                    ForEach(sets) { set in
                        Button(action: { selectedSet = set }) {
                            ArtistCardView(
                                festivalSet: set,
                                isScheduled: scheduleStore.isScheduled(set),
                                crewCount: crewStore.attendees(for: set).count,
                                onToggle: { scheduleStore.toggle(set) }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.pageMargin)
            .padding(.vertical, DS.Spacing.cardGap)
        }
    }
}

#Preview {
    NavigationStack {
        LineupView()
            .environmentObject(LineupStore())
            .environmentObject(ScheduleStore())
            .environmentObject(CrewStore())
            .environmentObject(JournalStore())
    }
    .preferredColorScheme(.dark)
}
