// Encore/App/RootView.swift
import SwiftUI

struct RootView: View {

    @State private var selectedTab: Tab = .home

    enum Tab: Int { case journal, crew, home, fests, profile }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                SeenTrackerView()
            }
            .tabItem { Label("Journal", systemImage: "book.fill") }
            .tag(Tab.journal)

            NavigationStack {
                CrewTabView()
            }
            .tabItem { Label("Crew", systemImage: "person.2.fill") }
            .tag(Tab.crew)

            NavigationStack {
                HomeView()
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(Tab.home)

            NavigationStack {
                FestivalListView()
            }
            .tabItem { Label("Fests", systemImage: "sparkles") }
            .tag(Tab.fests)

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
        .environmentObject(FestivalDiscoveryStore())
}
