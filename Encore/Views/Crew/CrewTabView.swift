// Encore/Views/Crew/CrewTabView.swift
import SwiftUI

struct CrewTabView: View {

    @EnvironmentObject var crewStore:    CrewStore
    @EnvironmentObject var festivalStore: FestivalStore

    @State private var showInvite         = false
    @State private var showTravelDetails  = false
    @State private var showLeaveConfirm   = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.cardGap) {
                if let crew = crewStore.crew {
                    membersCard(crew: crew)
                    travelRow
                    packingSection
                    expensesPlaceholder
                    playlistPlaceholder
                    leaveCrewButton(crew: crew)
                } else {
                    noCrewContent
                }
            }
            .padding(.horizontal, DS.Spacing.pageMargin)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(Color.appBackground)
        .navigationTitle(crewStore.crew?.name ?? "Crew")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if crewStore.crew != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showInvite = true }) {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(.appCTA)
                    }
                }
            }
        }
        .sheet(isPresented: $showInvite) {
            CrewInviteView()
                .environmentObject(crewStore)
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
        .confirmationDialog(
            "Leave \(crewStore.crew?.name ?? "crew")?",
            isPresented: $showLeaveConfirm,
            titleVisibility: .visible
        ) {
            Button("Leave Crew", role: .destructive) { crewStore.leaveCrew() }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Members

    private func membersCard(crew: Crew) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sectionGap) {
            HStack {
                Text("MEMBERS")
                    .font(DS.Font.caps)
                    .foregroundColor(.appTextMuted)
                    .tracking(0.6)
                Spacer()
                Text("Invite code: \(crew.inviteCode)")
                    .font(DS.Font.caps)
                    .foregroundColor(.appTextMuted)
            }
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
    }

    private func memberBubble(member: CrewMember) -> some View {
        VStack(spacing: 4) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(member.color)
                    .frame(width: 42, height: 42)
                    .overlay(
                        Text(member.initials)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color.appBackground)
                    )
                Circle()
                    .fill(member.isOnline ? Color.appCTA : Color.appSurface)
                    .frame(width: 11, height: 11)
                    .overlay(Circle().stroke(Color.appSurface, lineWidth: 1.5))
            }
            Text(member.name)
                .font(DS.Font.caps)
                .foregroundColor(.appTextMuted)
        }
    }

    // MARK: - Travel

    private var travelRow: some View {
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

    // MARK: - Packing

    private var packingItems: [PackingItem] {
        guard let id = festivalStore.selectedFestival?.id else { return [] }
        return festivalStore.travelDetails[id]?.packingItems ?? []
    }

    private func toggleItem(_ item: PackingItem) {
        guard let id = festivalStore.selectedFestival?.id else { return }
        var details = festivalStore.travelDetails[id] ?? TravelDetails(
            festivalID: id, packingItems: [], expenses: []
        )
        guard let idx = details.packingItems.firstIndex(where: { $0.id == item.id }) else { return }
        details.packingItems[idx].isPacked.toggle()
        festivalStore.saveTravelDetails(details, for: id)
    }

    private var packingSection: some View {
        let items = packingItems
        return VStack(alignment: .leading, spacing: DS.Spacing.sectionGap) {
            HStack {
                Text("PACKING LIST")
                    .font(DS.Font.caps)
                    .foregroundColor(.appTextMuted)
                    .tracking(0.6)
                Spacer()
                if !items.isEmpty {
                    Text("\(items.filter(\.isPacked).count)/\(items.count) packed")
                        .font(DS.Font.caps)
                        .foregroundColor(.appTextMuted)
                }
            }
            if items.isEmpty {
                Text("No items yet — add them in Travel Details.")
                    .font(DS.Font.metadata)
                    .foregroundColor(Color.appTextMuted.opacity(0.6))
            } else {
                ForEach(items) { item in
                    Button(action: { toggleItem(item) }) {
                        HStack(spacing: 12) {
                            Image(systemName: item.isPacked ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundColor(item.isPacked ? .appCTA : Color.appTextMuted.opacity(0.4))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(DS.Font.listItem)
                                    .foregroundColor(item.isPacked ? .appTextMuted : .appTextPrimary)
                                    .strikethrough(item.isPacked)
                                Text(item.category)
                                    .font(DS.Font.caps)
                                    .foregroundColor(.appTextMuted)
                            }
                            Spacer()
                        }
                        .frame(minHeight: 36)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(DS.Spacing.cardPadding)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card)
            .stroke(Color.appAccent.opacity(0.18), lineWidth: 1))
    }

    // MARK: - Placeholders

    private var expensesPlaceholder: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sectionGap) {
            Text("EXPENSES")
                .font(DS.Font.caps)
                .foregroundColor(.appTextMuted)
                .tracking(0.6)
            HStack(spacing: 12) {
                Image(systemName: "dollarsign.circle")
                    .font(.system(size: 20))
                    .foregroundColor(Color.appTextMuted.opacity(0.4))
                Text("Shared expense tracking — coming soon")
                    .font(DS.Font.listItem)
                    .foregroundColor(.appTextMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
        }
        .padding(DS.Spacing.cardPadding)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card)
            .stroke(Color.appAccent.opacity(0.18), lineWidth: 1))
    }

    private var playlistPlaceholder: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sectionGap) {
            Text("SHARED PLAYLIST")
                .font(DS.Font.caps)
                .foregroundColor(.appTextMuted)
                .tracking(0.6)
            Button(action: {}) {
                HStack(spacing: 10) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 16))
                        .foregroundColor(.appAccent)
                    Text("Add a playlist")
                        .font(DS.Font.listItem)
                        .foregroundColor(.appAccent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .disabled(true)
        }
        .padding(DS.Spacing.cardPadding)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card)
            .stroke(Color.appAccent.opacity(0.18), lineWidth: 1))
    }

    // MARK: - Leave Crew

    private func leaveCrewButton(crew: Crew) -> some View {
        Button(role: .destructive, action: { showLeaveConfirm = true }) {
            Label("Leave Crew", systemImage: "rectangle.portrait.and.arrow.right")
                .font(DS.Font.listItem)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(DS.Spacing.cardPadding)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(Color.appAccent.opacity(0.18), lineWidth: 1))
        }
    }

    // MARK: - No Crew State

    private var noCrewContent: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sectionGap) {
            Text("CREW")
                .font(DS.Font.caps)
                .foregroundColor(.appTextMuted)
                .tracking(0.6)
            Text("Plan with your crew")
                .font(DS.Font.cardTitle)
                .foregroundColor(.appTextPrimary)
            Text("Create or join a crew to coordinate schedules, track travel, and share playlists.")
                .font(DS.Font.metadata)
                .foregroundColor(.appTextMuted)
            HStack(spacing: 10) {
                Button("Create a Crew") { showInvite = true }
                    .font(DS.Font.listItem)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Color.appCTA.opacity(0.15))
                    .foregroundColor(.appCTA)
                    .clipShape(Capsule())
                Button("Join with Code") { showInvite = true }
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
}

#Preview {
    NavigationStack {
        CrewTabView()
    }
    .environmentObject(CrewStore())
    .environmentObject(FestivalStore())
    .preferredColorScheme(.dark)
}
