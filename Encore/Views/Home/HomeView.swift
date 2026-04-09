// Encore/Views/Home/HomeView.swift
import SwiftUI

struct HomeView: View {

    @EnvironmentObject var scheduleStore: ScheduleStore
    @EnvironmentObject var lineupStore:   LineupStore
    @EnvironmentObject var crewStore:     CrewStore

    @State private var selectedDay:    FestivalDay  = .thursday
    @State private var activeConflict: SetConflict? = nil
    @State private var selectedSet:    FestivalSet? = nil
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.cardGap) {
                    festivalHeader
                    groupCard
                    tripCard
                    lineupButton
                    scheduleSection
                }
                .padding(.horizontal, DS.Spacing.pageMargin)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(Color.appBackground)
            .navigationDestination(for: String.self) { destination in
                if destination == "lineup" {
                    LineupView()
                        .environmentObject(lineupStore)
                        .environmentObject(scheduleStore)
                        .environmentObject(crewStore)
                }
            }
            .sheet(item: $selectedSet) { set in
                ArtistDetailView(festivalSet: set)
                    .environmentObject(scheduleStore)
                    .environmentObject(crewStore)
            }
            .sheet(item: $activeConflict) { conflict in
                ConflictResolverView(conflict: conflict)
                    .environmentObject(scheduleStore)
                    .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Festival Header

    private var festivalHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Bonnaroo '25")
                .font(DS.Font.hero)
                .foregroundColor(.appCTA)
            Text("June 12–15  ·  Manchester, TN")
                .font(DS.Font.metadata)
                .foregroundColor(.appTextMuted)
        }
        .padding(.top, 4)
    }

    // MARK: - Group Card

    @ViewBuilder
    private var groupCard: some View {
        if let crew = crewStore.crew {
            crewCardView(crew: crew)
        } else {
            noCrewCardView
        }
    }

    private var noCrewCardView: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sectionGap) {
            Text("FESTIVAL GROUP")
                .font(DS.Font.caps)
                .foregroundColor(.appTextMuted)
                .tracking(0.6)
            Text("No group yet")
                .font(DS.Font.cardTitle)
                .foregroundColor(.appTextPrimary)
            HStack(spacing: 10) {
                Button("Start a Group") {}
                    .font(DS.Font.listItem)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Color.appCTA.opacity(0.15))
                    .foregroundColor(.appCTA)
                    .clipShape(Capsule())
                Button("Join with Code") {}
                    .font(DS.Font.metadata)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Color.appSurface)
                    .foregroundColor(.appTextMuted)
                    .clipShape(Capsule())
            }
        }
        .padding(DS.Spacing.cardPadding)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card)
            .stroke(Color.appAccent.opacity(0.18), lineWidth: 1))
    }

    private func crewCardView(crew: Crew) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sectionGap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("FESTIVAL GROUP")
                        .font(DS.Font.caps)
                        .foregroundColor(.appTextMuted)
                        .tracking(0.6)
                    Text(crew.name)
                        .font(DS.Font.cardTitle)
                        .foregroundColor(.appTextPrimary)
                }
                Spacer()
                Button(action: {}) {
                    Text("+ Invite")
                        .font(DS.Font.label)
                        .foregroundColor(.appAccent)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .overlay(RoundedRectangle(cornerRadius: DS.Radius.chip)
                            .stroke(Color.appAccent.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            HStack(spacing: 14) {
                ForEach(crew.members) { member in
                    memberBubble(member: member)
                }
            }
        }
        .padding(DS.Spacing.cardPadding)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card)
            .stroke(Color.appAccent.opacity(0.18), lineWidth: 1))
    }

    private func memberBubble(member: CrewMember) -> some View {
        VStack(spacing: 4) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(member.color)
                    .frame(width: 38, height: 38)
                    .overlay(
                        Text(member.initials)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.appBackground)
                    )
                Circle()
                    .fill(member.isOnline ? Color.appCTA : Color.appSurface)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(Color.appSurface, lineWidth: 1.5))
            }
            Text(member.name)
                .font(DS.Font.caps)
                .foregroundColor(.appTextMuted)
        }
    }

    // MARK: - Trip Card

    private var tripCard: some View {
        HStack(spacing: 0) {
            tripColumn(icon: "airplane",         label: "Travel",   detail: "Fri 8 AM")
            Rectangle()
                .fill(Color.appAccent.opacity(0.25))
                .frame(width: 1, height: 36)
            tripColumn(icon: "backpack",          label: "Packing",  detail: "0 / 0")
            Rectangle()
                .fill(Color.appAccent.opacity(0.25))
                .frame(width: 1, height: 36)
            tripColumn(icon: "dollarsign.circle", label: "Expenses", detail: "$0 / person")
        }
        .padding(.vertical, DS.Spacing.cardPadding)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card)
            .stroke(Color.appAccent.opacity(0.18), lineWidth: 1))
    }

    private func tripColumn(icon: String, label: String, detail: String) -> some View {
        Button(action: {}) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(.appAccent)
                Text(label)
                    .font(DS.Font.label)
                    .foregroundColor(.appTextPrimary)
                Text(detail)
                    .font(DS.Font.caps)
                    .foregroundColor(.appTextMuted)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Lineup Button

    private var lineupButton: some View {
        Button(action: { navigationPath.append("lineup") }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Browse Full Lineup")
                        .font(DS.Font.listItem)
                        .foregroundColor(.appCTA)
                    Text("\(lineupStore.allSets.count) artists")
                        .font(DS.Font.metadata)
                        .foregroundColor(.appTextMuted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.appCTA)
            }
            .padding(DS.Spacing.cardPadding)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(Color.appCTA.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Schedule Section

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sectionGap) {
            HStack {
                Text("MY SCHEDULE")
                    .font(DS.Font.caps)
                    .foregroundColor(.appTextMuted)
                    .tracking(0.8)
                Spacer()
                dayPicker
            }

            if scheduleStore.hasConflicts {
                conflictBanner
            }

            let sets = scheduleStore.sets(for: selectedDay)
            if sets.isEmpty {
                emptySchedule
            } else {
                ForEach(sets) { set in
                    scheduleRow(set: set)
                }
            }
        }
    }

    private var dayPicker: some View {
        HStack(spacing: 4) {
            ForEach(FestivalDay.allCases) { day in
                Button(action: { selectedDay = day }) {
                    Text(day.rawValue)
                        .font(selectedDay == day ? DS.Font.label : DS.Font.metadata)
                        .foregroundColor(selectedDay == day ? .appCTA : .appTextMuted)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(selectedDay == day
                            ? Color.appCTA.opacity(0.15) : Color.clear)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var conflictBanner: some View {
        let conflicts = scheduleStore.conflicts
        return Button(action: { activeConflict = conflicts.first }) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.orange)
                Text("\(conflicts.count) conflict\(conflicts.count == 1 ? "" : "s") — tap to resolve")
                    .font(DS.Font.listItem)
                    .foregroundColor(.appTextPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(DS.Font.metadata)
                    .foregroundColor(.appTextMuted)
            }
            .padding(.horizontal, DS.Spacing.cardPadding).padding(.vertical, 10)
            .background(Color.orange.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
        }
        .buttonStyle(.plain)
    }

    private func scheduleRow(set: FestivalSet) -> some View {
        let isConflicted = scheduleStore.conflicts.contains {
            $0.setA.id == set.id || $0.setB.id == set.id
        }
        return Button(action: { selectedSet = set }) {
            HStack(spacing: 12) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(timeLabel(set.startTime))
                        .font(DS.Font.label)
                        .foregroundColor(.appTextMuted)
                    Text(timeLabel(set.endTime))
                        .font(DS.Font.caps)
                        .foregroundColor(Color.appTextMuted.opacity(0.6))
                }
                .frame(width: 44, alignment: .trailing)

                RoundedRectangle(cornerRadius: 2)
                    .fill(isConflicted ? Color(UIColor(appHex: "F59E0B")) : Color.appCTA)
                    .frame(width: 3)

                VStack(alignment: .leading, spacing: 3) {
                    Text(set.artist.name)
                        .font(DS.Font.listItem)
                        .foregroundColor(.appTextPrimary)
                    Text(set.stageName)
                        .font(DS.Font.metadata)
                        .foregroundColor(.appTextMuted)
                }
                Spacer()

                if isConflicted {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                        .font(.system(size: 15))
                }

                Button(action: { scheduleStore.remove(set) }) {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 20))
                        .foregroundColor(Color.appTextMuted.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .frame(minHeight: DS.RowHeight.schedule)
            .padding(.horizontal, DS.Spacing.cardPadding)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.chip)
                .stroke(isConflicted ? Color.orange.opacity(0.4) : Color.clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var emptySchedule: some View {
        VStack(spacing: DS.Spacing.sectionGap) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 32))
                .foregroundColor(Color.appTextMuted.opacity(0.4))
            Text("Nothing scheduled for \(selectedDay.fullName)")
                .font(DS.Font.listItem)
                .foregroundColor(.appTextMuted)
            Text("Browse the lineup to add sets")
                .font(DS.Font.metadata)
                .foregroundColor(Color.appTextMuted.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private func timeLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm"
        return f.string(from: date)
    }
}

#Preview {
    let schedule = ScheduleStore()
    schedule.add(FestivalSet.mockSets[4])
    schedule.add(FestivalSet.mockSets[5])
    return HomeView()
        .environmentObject(schedule)
        .environmentObject(LineupStore())
        .environmentObject(CrewStore())
        .preferredColorScheme(.dark)
}
