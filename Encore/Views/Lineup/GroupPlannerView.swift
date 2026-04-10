// Encore/Views/Lineup/GroupPlannerView.swift
import SwiftUI

struct GroupPlannerView: View {

    @EnvironmentObject var scheduleStore: ScheduleStore
    @EnvironmentObject var crewStore:     CrewStore
    @EnvironmentObject var lineupStore:   LineupStore

    @Environment(\.dismiss) private var dismiss

    @State private var selectedDay: FestivalDay = .thursday
    @State private var myScheduleOnly = false

    private var mergedSets: [FestivalSet] {
        crewStore.mergedSets(allSets: lineupStore.allSets)
            .filter { $0.day == selectedDay }
    }

    private var displaySets: [FestivalSet] {
        if myScheduleOnly {
            return mergedSets.filter { scheduleStore.isScheduled($0) }
        }
        return mergedSets
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Day picker
                dayPicker
                    .padding(.horizontal, DS.Spacing.pageMargin)
                    .padding(.vertical, 10)
                    .background(Color.appBackground)

                // "Your schedule only" toggle
                HStack {
                    Toggle("Show only my sets", isOn: $myScheduleOnly)
                        .font(DS.Font.listItem)
                        .foregroundColor(.appTextPrimary)
                        .tint(.appCTA)
                }
                .padding(.horizontal, DS.Spacing.pageMargin)
                .padding(.bottom, 8)

                Divider()

                if displaySets.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: DS.Spacing.cardGap) {
                            ForEach(displaySets) { set in
                                groupSetRow(set: set)
                            }
                        }
                        .padding(.horizontal, DS.Spacing.pageMargin)
                        .padding(.vertical, DS.Spacing.cardGap)
                    }
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Group Planner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.appCTA)
                }
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

    private func groupSetRow(set: FestivalSet) -> some View {
        let attendees = crewStore.attendees(for: set)
        let mySet = scheduleStore.isScheduled(set)
        let sharedCount = attendees.count + (mySet ? 1 : 0)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(set.artist.name)
                        .font(DS.Font.listItem)
                        .foregroundColor(.appTextPrimary)
                    Text("\(set.stageName)  ·  \(set.timeRangeLabel)")
                        .font(DS.Font.metadata)
                        .foregroundColor(.appTextMuted)
                }
                Spacer()
                // Tier badge
                Text(set.artist.matchTier.rawValue.uppercased())
                    .font(DS.Font.caps)
                    .foregroundColor(set.artist.matchTier.color)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(set.artist.matchTier.backgroundColor)
                    .clipShape(Capsule())
            }

            if sharedCount > 1 {
                HStack(spacing: 6) {
                    // Crew avatar stack
                    HStack(spacing: -6) {
                        if mySet {
                            Circle()
                                .fill(Color.appCTA)
                                .frame(width: 22, height: 22)
                                .overlay(
                                    Text("You")
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundColor(Color.appBackground)
                                )
                                .overlay(Circle().stroke(Color.appSurface, lineWidth: 1.5))
                        }
                        ForEach(attendees.prefix(3)) { member in
                            CrewAvatarBubble(member: member, size: 22)
                                .overlay(Circle().stroke(Color.appSurface, lineWidth: 1.5))
                        }
                    }
                    let names = attendees.prefix(2).map(\.name).joined(separator: ", ")
                    let extra = attendees.count > 2 ? " +\(attendees.count - 2)" : ""
                    Text("\(mySet ? "You, " : "")\(names)\(extra) going")
                        .font(DS.Font.metadata)
                        .foregroundColor(.appTextMuted)
                        .lineLimit(1)
                }
            }
        }
        .padding(DS.Spacing.cardPadding)
        .background(mySet ? Color.appCTA.opacity(0.08) : Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.chip)
            .stroke(mySet ? Color.appCTA.opacity(0.25) : Color.clear, lineWidth: 1))
    }

    private var emptyState: some View {
        VStack(spacing: DS.Spacing.sectionGap) {
            Image(systemName: "person.2")
                .font(.system(size: 36))
                .foregroundColor(Color.appTextMuted.opacity(0.3))
                .padding(.top, 60)
            Text("No crew sets for \(selectedDay.fullName).")
                .font(DS.Font.listItem)
                .foregroundColor(.appTextMuted)
            Text("Crew members need to add sets to their schedule.")
                .font(DS.Font.metadata)
                .foregroundColor(Color.appTextMuted.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    GroupPlannerView()
        .environmentObject(ScheduleStore())
        .environmentObject(CrewStore())
        .environmentObject(LineupStore())
        .preferredColorScheme(.dark)
}
