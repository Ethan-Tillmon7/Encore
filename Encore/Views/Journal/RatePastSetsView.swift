// Encore/Views/Journal/RatePastSetsView.swift
import SwiftUI

struct RatePastSetsView: View {

    @EnvironmentObject var festivalStore: FestivalStore
    @EnvironmentObject var journalStore:  JournalStore
    @Environment(\.dismiss) private var dismiss

    private var pastFestivals: [Festival] {
        festivalStore.festivals
            .filter { $0.status == .past && !$0.lineup.isEmpty }
            .sorted { $0.startDate > $1.startDate }
    }

    var body: some View {
        NavigationStack {
            Group {
                if pastFestivals.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: DS.Spacing.cardGap) {
                            ForEach(pastFestivals) { festival in
                                festivalSection(festival: festival)
                            }
                        }
                        .padding(.horizontal, DS.Spacing.pageMargin)
                        .padding(.vertical, DS.Spacing.cardGap)
                    }
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Rate Your History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.appCTA)
                }
            }
        }
    }

    // MARK: - Festival Section

    private func festivalSection(festival: Festival) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sectionGap) {
            Text(festival.name.uppercased())
                .font(DS.Font.caps)
                .foregroundColor(.appTextMuted)
                .tracking(0.6)

            ForEach(festival.lineup) { artist in
                artistRatingRow(artist: artist, festival: festival)
            }
        }
        .padding(DS.Spacing.cardPadding)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card)
            .stroke(Color.appAccent.opacity(0.18), lineWidth: 1))
    }

    // MARK: - Artist Rating Row

    private func artistRatingRow(artist: Artist, festival: Festival) -> some View {
        let existing = journalStore.entries.first {
            $0.artistID == artist.id && $0.festivalID == festival.id
        }
        let currentRating = existing?.rating ?? 0

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(artist.name)
                    .font(DS.Font.listItem)
                    .foregroundColor(.appTextPrimary)
                Text(artist.stageName)
                    .font(DS.Font.metadata)
                    .foregroundColor(.appTextMuted)
            }
            Spacer()
            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { star in
                    Button(action: {
                        rate(artist: artist, festival: festival, existing: existing, rating: star)
                    }) {
                        Image(systemName: star <= currentRating ? "star.fill" : "star")
                            .font(.system(size: 18))
                            .foregroundColor(star <= currentRating ? .appCTA : Color.appTextMuted.opacity(0.35))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Rating Action

    private func rate(artist: Artist, festival: Festival, existing: JournalEntry?, rating: Int) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if var entry = existing {
            entry.rating = rating
            journalStore.upsert(entry)
        } else {
            journalStore.upsert(JournalEntry(
                id: UUID(),
                artistID: artist.id,
                festivalID: festival.id,
                setID: UUID(),
                dateAttended: festival.endDate,
                rating: rating,
                notes: "",
                highlights: [],
                wouldSeeAgain: nil
            ))
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DS.Spacing.sectionGap) {
            Image(systemName: "star.slash")
                .font(.system(size: 40))
                .foregroundColor(Color.appTextMuted.opacity(0.3))
                .padding(.top, 80)
            Text("No past festivals with lineups yet.")
                .font(DS.Font.listItem)
                .foregroundColor(.appTextMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let journal = JournalStore()
    let festivals = FestivalStore()
    return RatePastSetsView()
        .environmentObject(journal)
        .environmentObject(festivals)
        .preferredColorScheme(.dark)
}
