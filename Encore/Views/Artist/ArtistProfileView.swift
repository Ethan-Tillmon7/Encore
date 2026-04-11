// Encore/Views/Artist/ArtistProfileView.swift
import SwiftUI

/// Lightweight artist sheet for artists that appear in the discovery catalog
/// but don't have a FestivalSet (no confirmed set time yet).
struct ArtistProfileView: View {

    let artist: Artist
    let festivals: [Festival]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    heroHeader
                    Divider().padding(.vertical, 20)
                    festivalsSection
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
            .padding(.horizontal, -DS.Spacing.pageMargin)

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

    // MARK: - Festival appearances

    private var festivalsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sectionGap) {
            sectionLabel("Appearing at")
            ForEach(festivals) { festival in
                festivalRow(festival)
            }
            Text("Set times not yet announced.")
                .font(DS.Font.metadata)
                .foregroundColor(.appTextMuted)
                .padding(.top, 4)
        }
    }

    private func festivalRow(_ festival: Festival) -> some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color(hex: festival.imageColorHex) ?? .appCTA)
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 3) {
                Text(festival.name)
                    .font(DS.Font.listItem)
                    .foregroundColor(.appTextPrimary)
                Text("\(dateRangeLabel(festival))  ·  \(festival.location)")
                    .font(DS.Font.metadata)
                    .foregroundColor(.appTextMuted)
            }

            Spacer()

            if festival.isCamping {
                Image(systemName: "tent.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.appTextMuted)
            }
        }
        .padding(DS.Spacing.cardPadding)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(DS.Font.label)
            .foregroundColor(.appTextMuted)
            .textCase(.uppercase)
            .tracking(0.8)
            .padding(.bottom, DS.Spacing.sectionGap)
    }

    private func dateRangeLabel(_ festival: Festival) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d"
        let g = DateFormatter(); g.dateFormat = "d, yyyy"
        return "\(f.string(from: festival.startDate))–\(g.string(from: festival.endDate))"
    }
}

#Preview {
    ArtistProfileView(
        artist: Artist(
            id: UUID(),
            name: "Tame Impala",
            genres: ["Psychedelic Rock", "Indie Rock", "Electronic"],
            spotifyMatchScore: nil,
            playCountLastSixMonths: nil,
            matchTier: .unknown,
            soundsLike: ["Unknown Mortal Orchestra", "MGMT"],
            stageName: "Lands End Stage",
            isHeadliner: true
        ),
        festivals: Array(Festival.mockFestivals.prefix(2))
    )
    .preferredColorScheme(.dark)
}
