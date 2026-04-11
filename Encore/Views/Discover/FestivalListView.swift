// Encore/Views/Discover/FestivalListView.swift
import SwiftUI

struct FestivalListView: View {

    @EnvironmentObject var discoveryStore: FestivalDiscoveryStore
    @EnvironmentObject var festivalStore:  FestivalStore
    @EnvironmentObject var journalStore:   JournalStore
    @EnvironmentObject var scheduleStore:  ScheduleStore
    @EnvironmentObject var crewStore:      CrewStore

    @State private var showArtistSearch = false
    @State private var showFilters = false

    var body: some View {
        VStack(spacing: 0) {
            statusFilterRow
                .padding(.horizontal, DS.Spacing.pageMargin)
                .padding(.vertical, 10)
                .background(Color.appBackground)

            Divider()

            if discoveryStore.filteredFestivals.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: DS.Spacing.cardGap) {
                        ForEach(discoveryStore.filteredFestivals) { festival in
                            NavigationLink(destination: festivalDetail(festival)) {
                                FestivalCardView(festival: festival)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, DS.Spacing.pageMargin)
                    .padding(.vertical, DS.Spacing.cardGap)
                }
            }
        }
        .background(Color.appBackground)
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $discoveryStore.searchText, prompt: "Festival or city…")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Filter button with active-count badge
                    Button(action: { showFilters = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(discoveryStore.activeFilterCount > 0 ? .appCTA : .appTextMuted)
                            .overlay(alignment: .topTrailing) {
                                if discoveryStore.activeFilterCount > 0 {
                                    Text("\(discoveryStore.activeFilterCount)")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(Color.appBackground)
                                        .padding(3)
                                        .background(Color.appCTA)
                                        .clipShape(Circle())
                                        .offset(x: 8, y: -8)
                                }
                            }
                    }
                    Button(action: { showArtistSearch = true }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.appCTA)
                    }
                }
            }
        }
        .sheet(isPresented: $showFilters) {
            DiscoveryFilterSheet()
                .environmentObject(discoveryStore)
        }
        .sheet(isPresented: $showArtistSearch) {
            ArtistSearchView()
                .environmentObject(discoveryStore)
                .environmentObject(festivalStore)
                .environmentObject(journalStore)
                .environmentObject(scheduleStore)
                .environmentObject(crewStore)
        }
    }

    @ViewBuilder
    private func festivalDetail(_ festival: Festival) -> some View {
        FestivalDetailView(festival: festival)
            .environmentObject(festivalStore)
            .environmentObject(journalStore)
            .environmentObject(scheduleStore)
            .environmentObject(crewStore)
    }

    private var statusFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterPill(label: "All",      status: nil)
                filterPill(label: "Upcoming", status: .upcoming)
                filterPill(label: "Active",   status: .active)
                filterPill(label: "Past",     status: .past)
            }
        }
    }

    private func filterPill(label: String, status: FestivalStatus?) -> some View {
        let isSelected = discoveryStore.selectedStatus == status
        return Button(action: { discoveryStore.selectedStatus = status }) {
            Text(label)
                .font(DS.Font.label)
                .foregroundColor(isSelected ? Color.appBackground : .appTextMuted)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(isSelected ? Color.appCTA : Color.appSurface)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: DS.Spacing.sectionGap) {
            Image(systemName: "safari")
                .font(.system(size: 40))
                .foregroundColor(Color.appTextMuted.opacity(0.3))
                .padding(.top, 60)
            Text("No \(discoveryStore.selectedStatus?.rawValue ?? "") festivals found.")
                .font(DS.Font.listItem)
                .foregroundColor(.appTextMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        FestivalListView()
            .environmentObject(FestivalDiscoveryStore())
            .environmentObject(FestivalStore())
            .environmentObject(JournalStore())
            .environmentObject(ScheduleStore())
            .environmentObject(CrewStore())
    }
    .preferredColorScheme(.dark)
}
