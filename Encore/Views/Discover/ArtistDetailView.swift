// Encore/Views/Discover/ArtistDetailView.swift
import SwiftUI

struct ArtistDetailView: View {

    let festivalSet: FestivalSet
    @EnvironmentObject var scheduleStore: ScheduleStore
    @EnvironmentObject var crewStore:     CrewStore
    @Environment(\.dismiss) private var dismiss

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
                    sectionLabel("Recent Setlist  ·  via setlist.fm")
                    setlistView
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
            .safeAreaInset(edge: .bottom) {
                bottomActions
            }
        }
    }

    // MARK: - Hero

    private var heroHeader: some View {
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
        return VStack(spacing: 8) {
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

            NavigationLink(destination:
                FestivalMapView(initialStage: festivalSet.stageName)
                    .environmentObject(scheduleStore)
                    .environmentObject(crewStore)
            ) {
                HStack {
                    Image(systemName: "map")
                    Text("Directions to \(festivalSet.stageName)")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.appSurface)
                .foregroundColor(.appAccent)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DS.Spacing.pageMargin)
        .padding(.vertical, 12)
        .background(Color.appBackground)
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
        .preferredColorScheme(.dark)
}
