// Encore/Views/Journal/QuickLogView.swift
import SwiftUI

struct QuickLogView: View {

    @EnvironmentObject var festivalStore: FestivalStore
    @Environment(\.dismiss) private var dismiss

    /// Called when the user picks an artist. Receiver dismisses QuickLogView first.
    let onSelect: (Artist, Festival) -> Void

    private enum Step {
        case festival
        case artist(Festival)
    }

    @State private var step: Step = .festival

    private var festivalsWithLineup: [Festival] {
        festivalStore.festivals
            .filter { !$0.lineup.isEmpty }
            .sorted { $0.startDate > $1.startDate }
    }

    var body: some View {
        NavigationView {
            Group {
                switch step {
                case .festival:
                    festivalList
                case .artist(let festival):
                    artistList(for: festival)
                }
            }
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if case .artist = step {
                        Button(action: { step = .festival }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Festivals")
                            }
                            .foregroundColor(.appCTA)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.appTextMuted)
                }
            }
        }
    }

    // MARK: - Step 1: Festival list

    private var festivalList: some View {
        Group {
            if festivalsWithLineup.isEmpty {
                VStack(spacing: DS.Spacing.sectionGap) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 40))
                        .foregroundColor(Color.appTextMuted.opacity(0.3))
                        .padding(.top, 80)
                    Text("No festivals with a lineup yet.")
                        .font(DS.Font.listItem)
                        .foregroundColor(.appTextMuted)
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: DS.Spacing.cardGap) {
                        ForEach(festivalsWithLineup) { festival in
                            festivalRow(festival)
                        }
                    }
                    .padding(.horizontal, DS.Spacing.pageMargin)
                    .padding(.vertical, DS.Spacing.cardGap)
                }
            }
        }
        .navigationTitle("Log a Set")
    }

    private func festivalRow(_ festival: Festival) -> some View {
        Button(action: { step = .artist(festival) }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(festival.name)
                        .font(DS.Font.listItem)
                        .foregroundColor(.appTextPrimary)
                    Text(dateRangeString(festival))
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
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 2: Artist list

    private func artistList(for festival: Festival) -> some View {
        ScrollView {
            LazyVStack(spacing: DS.Spacing.cardGap) {
                ForEach(festival.lineup.sorted { $0.name < $1.name }) { artist in
                    artistRow(artist, festival: festival)
                }
            }
            .padding(.horizontal, DS.Spacing.pageMargin)
            .padding(.vertical, DS.Spacing.cardGap)
        }
        .navigationTitle(festival.name)
    }

    private func artistRow(_ artist: Artist, festival: Festival) -> some View {
        Button(action: {
            dismiss()
            onSelect(artist, festival)
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(artist.name)
                        .font(DS.Font.listItem)
                        .foregroundColor(.appTextPrimary)
                    Text(artist.stageName)
                        .font(DS.Font.metadata)
                        .foregroundColor(.appTextMuted)
                }
                Spacer()
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.appCTA)
            }
            .padding(DS.Spacing.cardPadding)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func dateRangeString(_ festival: Festival) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        let g = DateFormatter()
        g.dateFormat = "MMM d, yyyy"
        return "\(f.string(from: festival.startDate)) – \(g.string(from: festival.endDate))"
    }
}

#Preview {
    let store = FestivalStore()
    store.festivals = Festival.mockFestivals
    return QuickLogView { artist, festival in
        print("Selected: \(artist.name) at \(festival.name)")
    }
    .environmentObject(store)
    .preferredColorScheme(.dark)
}
