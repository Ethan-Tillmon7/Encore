// Encore/App/RootView.swift
import SwiftUI

struct RootView: View {

    @State private var selectedTab: Tab = .home

    enum Tab: Int { case home, lineup, map, crew, profile }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("Home",    systemImage: "house.fill") }
            .tag(Tab.home)

            NavigationStack {
                LineupView()
            }
            .tabItem { Label("Lineup",  systemImage: "calendar") }
            .tag(Tab.lineup)

            NavigationStack {
                FestivalMapView()
            }
            .tabItem { Label("Map",     systemImage: "map.fill") }
            .tag(Tab.map)

            NavigationStack {
                CrewManageView()
            }
            .tabItem { Label("Crew",    systemImage: "person.2.fill") }
            .tag(Tab.crew)

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
