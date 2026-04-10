// Encore/Views/Artist/ArtistDetailView.swift
import SwiftUI

struct ArtistDetailView: View {

    let festivalSet: FestivalSet
    @EnvironmentObject var scheduleStore: ScheduleStore
    @EnvironmentObject var crewStore:     CrewStore
    @EnvironmentObject var lineupStore:   LineupStore
    @EnvironmentObject var journalStore:  JournalStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSimilarSet: FestivalSet? = nil

    var artist: Artist { festivalSet.artist }

    private let recentSetlist: [String] = [
        "Someone Great", "All My Friends", "Dance Yrself Clean",
        "Drunk Girls", "I Can Change", "New York I Love You", "Home"
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    heroHeader
                    Divider().padding(.vertical, 20)
                    sectionLabel("Set Info")
                    setInfoRow
                    Divider().padding(.vertical, 20)
                    let attendees = crewStore.attendees(for: festivalSet)
                    if !attendees.isEmpty {
                        sectionLabel("Your Crew")
                        crewRow(attendees: attendees)
                        Divider().padding(.vertical, 20)
                    }
                    similarArtistsSection
                    sectionLabel("Recent Setlist  ·  via setlist.fm")
                    setlistView
                    journalSection
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, DS.Spacing.pageMargin)
                .padding(.top, 24)
            }
            .background(Color.appBackground)
            .navigationTitle(artist.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.appTextMuted)
                            .font(.system(size: 22))
                    }
                }
            }
            .sheet(item: $selectedSimilarSet) { set in
                ArtistDetailView(festivalSet: set)
                    .environmentObject(scheduleStore)
                    .environmentObject(crewStore)
                    .environmentObject(lineupStore)
                    .environmentObject(journalStore)
            }
            .safeAreaInset(edge: .bottom) {
                bottomActions
            }
        }
    }

    // MARK: - Hero

    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [artist.matchTier.color.opacity(0.35), Color.appBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 160)
            .padding(.horizontal, -DS.Spacing.pageMargin)  // bleed to edges

            VStack(alignment: .leading, spacing: DS.Spacing.sectionGap) {
                Text(artist.matchTier.rawValue.uppercased())
                    .font(DS.Font.label)
                    .foregroundColor(artist.matchTier.color)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(artist.matchTier.backgroundColor)
                    .clipShape(Capsule())

                Text(artist.genres.joined(separator: "  ·  "))
                    .font(DS.Font.listItem)
                    .foregroundColor(.appTextMuted)

                if let label = artist.spotifyLabel {
                    Label(label, systemImage: "music.note")
                        .font(DS.Font.listItem)
                        .foregroundColor(artist.matchTier.color)
                } else if !artist.soundsLike.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Not in your library yet — sounds like:")
                            .font(DS.Font.metadata)
                            .foregroundColor(.appTextMuted)
                        Text(artist.soundsLike.joined(separator: ", "))
                            .font(DS.Font.listItem)
                            .foregroundColor(.appTextPrimary)
                    }
                }
            }
            .padding(.bottom, 8)
        }
    }

    // MARK: - Set Info

    private var setInfoRow: some View {
        HStack(spacing: 0) {
            infoCell(label: "Stage", value: festivalSet.stageName)
            Divider().frame(height: 40)
            infoCell(label: "Day",   value: festivalSet.day.fullName)
            Divider().frame(height: 40)
            infoCell(label: "Time",  value: festivalSet.timeRangeLabel)
        }
        .padding(.vertical, 12)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
    }

    private func infoCell(label: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(DS.Font.label)
                .foregroundColor(.appTextMuted)
                .textCase(.uppercase)
            Text(value)
                .font(DS.Font.listItem)
                .foregroundColor(.appTextPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Crew

    private func crewRow(attendees: [CrewMember]) -> some View {
        HStack(spacing: 8) {
            ForEach(attendees) { member in
                ZStack {
                    Circle().fill(member.color).frame(width: 36, height: 36)
                    Text(member.initials)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color.appBackground)
                }
            }
            Text("\(attendees.count) friend\(attendees.count == 1 ? "" : "s") going")
                .font(DS.Font.listItem)
                .foregroundColor(.appTextMuted)
            Spacer()
        }
        .padding(.bottom, 4)
    }

    // MARK: - Setlist

    private var setlistView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(recentSetlist.enumerated()), id: \.offset) { index, song in
                HStack {
                    Text("\(index + 1)")
                        .font(DS.Font.metadata)
                        .foregroundColor(.appTextMuted)
                        .frame(width: 24, alignment: .trailing)
                    Text(song)
                        .font(DS.Font.listItem)
                        .foregroundColor(.appTextPrimary)
                    Spacer()
                }
                .padding(.vertical, 10)
                if index < recentSetlist.count - 1 { Divider() }
            }
        }
    }

    // MARK: - Bottom actions

    private var bottomActions: some View {
        let isScheduled = scheduleStore.isScheduled(festivalSet)
        let conflictingSet = isScheduled ? nil : scheduleStore.scheduledSets.first {
            festivalSet.overlaps(with: $0)
        }

        return VStack(spacing: 8) {
            if let conflict = conflictingSet {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.appWarn)
                        .font(.system(size: 13))
                    Text("Conflicts with \(conflict.artist.name)")
                        .font(DS.Font.metadata)
                        .foregroundColor(.appWarn)
                    Spacer()
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Color.appWarn.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
            }

            Button(action: { scheduleStore.toggle(festivalSet) }) {
                HStack {
                    Image(systemName: isScheduled ? "checkmark" : "plus")
                    Text(isScheduled ? "Added to Schedule" : "Add to My Schedule")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isScheduled ? Color.appSurface : Color.appCTA)
                .foregroundColor(isScheduled ? .appTextPrimary : Color.appBackground)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
            }

            HStack {
                Image(systemName: "mappin.and.ellipse")
                Text(festivalSet.stageName)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.appSurface)
            .foregroundColor(.appTextMuted)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        }
        .padding(.horizontal, DS.Spacing.pageMargin)
        .padding(.vertical, 12)
        .background(Color.appBackground)
    }

    // MARK: - Similar Artists

    private var similarArtistsSection: some View {
        let names = Set(artist.soundsLike)
        let matchingSets = lineupStore.allSets.filter { names.contains($0.artist.name) }
        guard !matchingSets.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: 0) {
                sectionLabel("Similar on Lineup")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(matchingSets) { matchSet in
                            Button(action: { selectedSimilarSet = matchSet }) {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(matchSet.artist.matchTier.color)
                                        .frame(width: 8, height: 8)
                                    Text(matchSet.artist.name)
                                        .font(DS.Font.metadata)
                                        .foregroundColor(.appTextPrimary)
                                }
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(Color.appSurface)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 4)
                }
                Divider().padding(.vertical, 20)
            }
        )
    }

    // MARK: - Journal

    private var journalSection: some View {
        let hasSeen = journalStore.hasSeenArtist(artist.id)
        let isPast  = festivalSet.startTime < Date()
        if hasSeen {
            return AnyView(
                Button(action: {}) {
                    Label("View your notes →", systemImage: "book")
                        .font(DS.Font.listItem)
                        .foregroundColor(.appAccent)
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            )
        } else if isPast {
            return AnyView(
                Button(action: {}) {
                    Label("Log this set →", systemImage: "plus.circle")
                        .font(DS.Font.listItem)
                        .foregroundColor(.appCTA)
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            )
        } else {
            return AnyView(EmptyView())
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(DS.Font.label)
            .foregroundColor(.appTextMuted)
            .textCase(.uppercase)
            .tracking(0.8)
            .padding(.bottom, DS.Spacing.sectionGap)
    }
}

#Preview {
    ArtistDetailView(festivalSet: FestivalSet.mockSets[0])
        .environmentObject(ScheduleStore())
        .environmentObject(CrewStore())
        .environmentObject(LineupStore())
        .environmentObject(JournalStore())
        .preferredColorScheme(.dark)
}
