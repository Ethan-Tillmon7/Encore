// Encore/Views/Journal/JournalEntryRowView.swift
import SwiftUI

struct JournalEntryRowView: View {

    let entry: JournalEntry

    // Resolved from mock data — in real app would come from a store lookup
    private var artistName: String {
        Artist.mockLineup.first(where: { $0.id == entry.artistID })?.name ?? "Unknown Artist"
    }
    private var festivalName: String {
        Festival.mockFestivals.first(where: { $0.id == entry.festivalID })?.name ?? "Unknown Festival"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Seen indicator
            Circle()
                .fill(Color.appCTA)
                .frame(width: 8, height: 8)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(artistName)
                    .font(DS.Font.listItem)
                    .foregroundColor(.appTextPrimary)
                Text("\(festivalName)  ·  \(formattedDate)")
                    .font(DS.Font.metadata)
                    .foregroundColor(.appTextMuted)
                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(DS.Font.metadata)
                        .foregroundColor(Color.appTextMuted.opacity(0.7))
                        .lineLimit(1)
                }
            }

            Spacer()

            // Star rating
            if let rating = entry.rating {
                starRow(rating: rating)
            }
        }
        .padding(DS.Spacing.cardPadding)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
    }

    private func starRow(rating: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.system(size: 10))
                    .foregroundColor(star <= rating ? DS.Journal.starFilled : DS.Journal.starEmpty)
            }
        }
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: entry.dateAttended)
    }
}

#Preview {
    JournalEntryRowView(entry: JournalEntry.mockEntries[0])
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
}
