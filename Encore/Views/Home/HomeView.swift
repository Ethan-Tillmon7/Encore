// Encore/Views/Home/HomeView.swift
import SwiftUI

struct HomeView: View {

    @EnvironmentObject var scheduleStore:  ScheduleStore
    @EnvironmentObject var lineupStore:    LineupStore
    @EnvironmentObject var crewStore:      CrewStore
    @EnvironmentObject var festivalStore:  FestivalStore
    @EnvironmentObject var discoveryStore: FestivalDiscoveryStore
    @EnvironmentObject var journalStore:   JournalStore

    @State private var selectedDay:    FestivalDay  = .thursday
    @State private var activeConflict: SetConflict? = nil
    @State private var selectedSet:    FestivalSet? = nil
    @State private var navigationPath = NavigationPath()
    @State private var showCrewInvite: Bool = false
    @State private var showCrewSheet:  Bool = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.cardGap) {
                    festivalHeader
                    groupCard
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
                } else if destination == "discover" {
                    FestivalListView()
                        .environmentObject(discoveryStore)
                }
            }
            .sheet(item: $selectedSet) { set in
                ArtistDetailView(festivalSet: set)
                    .environmentObject(scheduleStore)
                    .environmentObject(crewStore)
                    .environmentObject(lineupStore)
                    .environmentObject(journalStore)
            }
            .sheet(item: $activeConflict) { conflict in
                ConflictResolverView(conflict: conflict)
                    .environmentObject(scheduleStore)
                    .environmentObject(crewStore)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showCrewInvite) {
                CrewInviteView()
            }
            .sheet(isPresented: $showCrewSheet) {
                if let crew = crewStore.crew {
                    CrewQuickView(crew: crew)
                        .environmentObject(festivalStore)
                }
            }
        }
    }

    // MARK: - Festival Header

    private var festivalHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Bonnaroo '25")
                .font(DS.Font.hero)
                .foregroundColor(.appCTA)
            Text(festivalContextLine)
                .font(DS.Font.metadata)
                .foregroundColor(.appTextMuted)
        }
        .padding(.top, 4)
    }

    private var festivalContextLine: String {
        let sets = lineupStore.allSets
        guard let festivalStart = sets.map(\.startTime).min(),
              let festivalEnd   = sets.map(\.endTime).max()
        else { return "June 12–15  ·  Manchester, TN" }

        let now = Date()
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: festivalStart)
        let todayStart = calendar.startOfDay(for: now)

        if now < festivalStart {
            let days = calendar.dateComponents([.day], from: todayStart, to: startDay).day ?? 0
            switch days {
            case 0:  return "Gates open today!  ·  Manchester, TN"
            case 1:  return "1 day until gates open  ·  Manchester, TN"
            default: return "\(days) days until Bonnaroo  ·  Manchester, TN"
            }
        } else if now <= festivalEnd {
            let dayNum = (calendar.dateComponents([.day], from: startDay, to: todayStart).day ?? 0) + 1
            return "Day \(dayNum) of 4  ·  Manchester, TN"
        } else {
            return "See you next year  ·  Manchester, TN"
        }
    }

    // MARK: - Group Card

    @ViewBuilder
    private var groupCard: some View {
        if let crew = crewStore.crew {
            Button(action: { showCrewSheet = true }) {
                crewCardView(crew: crew)
            }
            .buttonStyle(.plain)
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
            Text("Planning with friends?")
                .font(DS.Font.cardTitle)
                .foregroundColor(.appTextPrimary)
            Text("Create or join a crew to coordinate schedules.")
                .font(DS.Font.metadata)
                .foregroundColor(.appTextMuted)
            HStack(spacing: 10) {
                Button("Create a Crew") { showCrewInvite = true }
                    .font(DS.Font.listItem)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Color.appCTA.opacity(0.15))
                    .foregroundColor(.appCTA)
                    .clipShape(Capsule())
                Button("Join with Code") { showCrewInvite = true }
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
                Button(action: { showCrewInvite = true }) {
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

                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    scheduleStore.remove(set)
                }) {
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
            Text("Nothing scheduled for \(selectedDay.fullName).")
                .font(DS.Font.listItem)
                .foregroundColor(.appTextMuted)
            Button("Browse the lineup →") {
                navigationPath.append("lineup")
            }
            .font(DS.Font.metadata)
            .foregroundColor(.appCTA)
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

// MARK: - Crew Quick Sheet

private struct CrewQuickView: View {
    let crew: Crew
    @EnvironmentObject var festivalStore: FestivalStore
    @Environment(\.dismiss) private var dismiss
    @State private var showTravelDetails = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.cardGap) {
                    // Member bubbles
                    VStack(alignment: .leading, spacing: DS.Spacing.sectionGap) {
                        Text("MEMBERS")
                            .font(DS.Font.caps)
                            .foregroundColor(.appTextMuted)
                            .tracking(0.6)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(crew.members) { member in
                                    memberBubble(member: member)
                                }
                            }
                        }
                    }
                    .padding(DS.Spacing.cardPadding)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
                    .overlay(RoundedRectangle(cornerRadius: DS.Radius.card)
                        .stroke(Color.appAccent.opacity(0.18), lineWidth: 1))

                    // Travel Details row
                    Button(action: { showTravelDetails = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "suitcase")
                                .font(.system(size: 18))
                                .foregroundColor(.appAccent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Travel Details")
                                    .font(DS.Font.listItem)
                                    .foregroundColor(.appTextPrimary)
                                Text("Arrival · Accommodation · Campsite")
                                    .font(DS.Font.metadata)
                                    .foregroundColor(.appTextMuted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.appTextMuted)
                        }
                        .padding(DS.Spacing.cardPadding)
                        .background(Color.appSurface)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
                        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card)
                            .stroke(Color.appAccent.opacity(0.18), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, DS.Spacing.pageMargin)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(Color.appBackground)
            .navigationTitle(crew.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.appCTA)
                }
            }
            .sheet(isPresented: $showTravelDetails) {
                if let id = festivalStore.selectedFestival?.id {
                    TravelDetailsView(festivalID: id)
                        .environmentObject(festivalStore)
                } else {
                    TravelDetailsView(festivalID: UUID())
                        .environmentObject(festivalStore)
                }
            }
        }
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
}

#Preview {
    let schedule = ScheduleStore()
    schedule.add(FestivalSet.mockSets[4])
    schedule.add(FestivalSet.mockSets[5])
    return NavigationStack {
        HomeView()
    }
    .environmentObject(schedule)
    .environmentObject(LineupStore())
    .environmentObject(CrewStore())
    .environmentObject(FestivalStore())
    .environmentObject(JournalStore())
    .environmentObject(FestivalDiscoveryStore())
    .preferredColorScheme(.dark)
}
