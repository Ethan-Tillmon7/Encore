// Encore/EncoreApp.swift
import SwiftUI

@main
struct EncoreApp: App {

    @StateObject private var scheduleStore = ScheduleStore()
    @StateObject private var lineupStore   = LineupStore()
    @StateObject private var crewStore     = CrewStore()

    @AppStorage("appTheme") private var appTheme: String = "system"

    private var preferredColorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil   // system
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(scheduleStore)
                .environmentObject(lineupStore)
                .environmentObject(crewStore)
                .preferredColorScheme(preferredColorScheme)
        }
    }
}
