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
            dayPicker
                .padding(.horizontal, DS.Spacing.pageMargin)
                .padding(.vertical, 10)
                .background(Color.appBackground)

            TimetableGridView(
                sets: setsForDay,
                stages: stages,
                scheduledSetIDs: scheduledIDs,
                onSetTap:  { selectedSet = $0 },
                onWalkTap: { a, b in walkSetA = a; walkSetB = b }
            )
        }
        .background(Color.appBackground)
        .navigationTitle("Lineup")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedSet) { set in
            ArtistDetailView(festivalSet: set)
                .environmentObject(scheduleStore)
                .environmentObject(crewStore)
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
    }

    private var dayPicker: some View {
        HStack(spacing: 0) {
            ForEach(FestivalDay.allCases) { day in
                Button(action: { selectedDay = day }) {
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
    }
}

#Preview {
    NavigationStack {
        LineupView()
            .environmentObject(LineupStore())
            .environmentObject(ScheduleStore())
            .environmentObject(CrewStore())
    }
    .preferredColorScheme(.dark)
}
