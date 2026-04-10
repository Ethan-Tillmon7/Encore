// Encore/App/RootView.swift
import SwiftUI

struct RootView: View {

    @State private var selectedTab: Tab = .home

    enum Tab: Int { case home, discover, lineup, journal, profile }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(Tab.home)

            NavigationStack {
                FestivalListView()
            }
            .tabItem { Label("Discover", systemImage: "safari.fill") }
            .tag(Tab.discover)

            NavigationStack {
                LineupView()
            }
            .tabItem { Label("Lineup", systemImage: "calendar") }
            .tag(Tab.lineup)

            NavigationStack {
                SeenTrackerView()
            }
            .tabItem { Label("Journal", systemImage: "book.fill") }
            .tag(Tab.journal)

            NavigationStack {
                ProfileView()
            }
            .tabItem { Label("Profile", systemImage: "person.circle.fill") }
            .tag(Tab.profile)
        }
        .tint(.appCTA)
    }
}

#Preview {
    RootView()
        .environmentObject(ScheduleStore())
        .environmentObject(LineupStore())
        .environmentObject(CrewStore())
        .environmentObject(FestivalStore())
        .environmentObject(JournalStore())
}
