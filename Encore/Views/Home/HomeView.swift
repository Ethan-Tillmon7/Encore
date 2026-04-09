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
                VStack(alignment: .leading, spacing: 16) {
                    festivalHeader
                    groupCard
                    tripCard
                    lineupButton
                    scheduleSection
                }
                .padding(.horizontal, 16)
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
                .font(.system(size: 28, weight: .heavy))
                .foregroundColor(.appCTA)
            Text("June 12–15  ·  Manchester, TN")
                .font(.system(size: 13))
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
        VStack(alignment: .leading, spacing: 10) {
            Text("FESTIVAL GROUP")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.appTextMuted)
                .tracking(0.6)
            Text("No group yet")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.appTextPrimary)
            HStack(spacing: 10) {
                Button("Start a Group") {}
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Color.appCTA.opacity(0.15))
                    .foregroundColor(.appCTA)
                    .clipShape(Capsule())
                Button("Join with Code") {}
                    .font(.system(size: 13))
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Color.appSurface)
                    .foregroundColor(.appTextMuted)
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(Color.appAccent.opacity(0.18), lineWidth: 1))
    }

    private func crewCardView(crew: Crew) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("FESTIVAL GROUP")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.appTextMuted)
                        .tracking(0.6)
                    Text(crew.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.appCTA)
                }
                Spacer()
                Button(action: {}) {
                    Text("+ Invite")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.appAccent)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .overlay(RoundedRectangle(cornerRadius: 7)
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
        .padding(14)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14)
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
                    .fill(member.isOnline ? Color.appCTA : Color.appTextMuted.opacity(0.4))
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(Color.appSurface, lineWidth: 1.5))
            }
            Text(member.name)
                .font(.system(size: 9))
                .foregroundColor(.appTextMuted)
        }
    }

    // MARK: - Trip Card

    private var tripCard: some View {
        HStack(spacing: 0) {
            tripColumn(icon: "airplane",          label: "Travel",   detail: "Fri 8 AM")
            Divider().frame(height: 36)
            tripColumn(icon: "backpack",           label: "Packing",  detail: "0 / 0")
            Divider().frame(height: 36)
            tripColumn(icon: "dollarsign.circle",  label: "Expenses", detail: "$0 / person")
        }
        .padding(.vertical, 12)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(Color.appAccent.opacity(0.18), lineWidth: 1))
    }

    private func tripColumn(icon: String, label: String, detail: String) -> some View {
        Button(action: {}) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(.appAccent)
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                Text(detail)
                    .font(.system(size: 10))
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
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appCTA)
                    Text("\(lineupStore.allSets.count) artists")
                        .font(.system(size: 12))
                        .foregroundColor(.appTextMuted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.appCTA)
            }
            .padding(14)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(Color.appCTA.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Schedule Section

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("MY SCHEDULE")
                    .font(.system(size: 10, weight: .bold))
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
                        .font(.system(size: 11, weight: selectedDay == day ? .bold : .regular))
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
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("\(conflicts.count) conflict\(conflicts.count == 1 ? "" : "s") — tap to resolve")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.appTextPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.appTextMuted)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Color.orange.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 10))
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
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.appTextMuted)
                    Text(timeLabel(set.endTime))
                        .font(.system(size: 10))
                        .foregroundColor(Color.appTextMuted.opacity(0.6))
                }
                .frame(width: 44, alignment: .trailing)

                RoundedRectangle(cornerRadius: 2)
                    .fill(isConflicted ? Color.orange : set.artist.matchTier.color)
                    .frame(width: 3, height: 44)

                VStack(alignment: .leading, spacing: 3) {
                    Text(set.artist.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appTextPrimary)
                    Text(set.stageName)
                        .font(.system(size: 12))
                        .foregroundColor(.appTextMuted)
                }
                Spacer()

                if isConflicted {
                    Image(systemName: "exclamationmark.triangle.fill")
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
            .padding(.horizontal, 13).padding(.vertical, 11)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(isConflicted ? Color.orange.opacity(0.4) : Color.clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var emptySchedule: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 32))
                .foregroundColor(Color.appTextMuted.opacity(0.4))
            Text("Nothing scheduled for \(selectedDay.fullName)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.appTextMuted)
            Text("Browse the lineup to add sets")
                .font(.system(size: 12))
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
