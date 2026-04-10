// Encore/Views/Discover/FestivalListView.swift
import SwiftUI

struct FestivalListView: View {

    @EnvironmentObject var festivalStore: FestivalStore
    @EnvironmentObject var journalStore:  JournalStore
    @EnvironmentObject var scheduleStore: ScheduleStore
    @EnvironmentObject var crewStore:     CrewStore

    @State private var selectedStatus: FestivalStatus? = nil
    @State private var showArtistSearch = false

    private var filteredFestivals: [Festival] {
        if let status = selectedStatus {
            return festivalStore.festivals.filter { $0.status == status }
        }
        return festivalStore.festivals
    }

    var body: some View {
        VStack(spacing: 0) {
            // Status filter pills
            statusFilterRow
                .padding(.horizontal, DS.Spacing.pageMargin)
                .padding(.vertical, 10)
                .background(Color.appBackground)

            Divider()

            if filteredFestivals.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: DS.Spacing.cardGap) {
                        ForEach(filteredFestivals) { festival in
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showArtistSearch = true }) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.appCTA)
                }
            }
        }
        .sheet(isPresented: $showArtistSearch) {
            ArtistSearchView()
                .environmentObject(festivalStore)
                .environmentObject(journalStore)
                .environmentObject(scheduleStore)
                .environmentObject(crewStore)
        }
        .onAppear {
            // Seed mock data if empty
            if festivalStore.festivals.isEmpty {
                festivalStore.festivals = Festival.mockFestivals
            }
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
                filterPill(label: "All", status: nil)
                filterPill(label: "Upcoming", status: .upcoming)
                filterPill(label: "Active", status: .active)
                filterPill(label: "Past", status: .past)
            }
        }
    }

    private func filterPill(label: String, status: FestivalStatus?) -> some View {
        let isSelected = selectedStatus == status
        return Button(action: { selectedStatus = status }) {
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
            Text("No \(selectedStatus?.rawValue ?? "") festivals yet.")
                .font(DS.Font.listItem)
                .foregroundColor(.appTextMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let festivals = FestivalStore()
    festivals.festivals = Festival.mockFestivals
    return NavigationStack {
        FestivalListView()
            .environmentObject(festivals)
            .environmentObject(JournalStore())
            .environmentObject(ScheduleStore())
            .environmentObject(CrewStore())
    }
    .preferredColorScheme(.dark)
}
