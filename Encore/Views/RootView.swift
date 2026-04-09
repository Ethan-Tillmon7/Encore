// Encore/Views/RootView.swift
import SwiftUI

struct RootView: View {

    @State private var selectedTab: Tab = .home

    enum Tab: Int { case home, profile }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }
                .tag(Tab.home)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.circle") }
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
}
