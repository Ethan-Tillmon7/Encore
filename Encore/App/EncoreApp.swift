// Encore/App/EncoreApp.swift
import SwiftUI

@main
struct EncoreApp: App {

    @StateObject private var scheduleStore = ScheduleStore()
    @StateObject private var lineupStore   = LineupStore()
    @StateObject private var crewStore     = CrewStore()
    @StateObject private var festivalStore = FestivalStore()
    @StateObject private var journalStore  = JournalStore()

    @AppStorage("appTheme") private var appTheme: String = "system"

    private var preferredColorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(scheduleStore)
                .environmentObject(lineupStore)
                .environmentObject(crewStore)
                .environmentObject(festivalStore)
                .environmentObject(journalStore)
                .preferredColorScheme(preferredColorScheme)
        }
    }
}
