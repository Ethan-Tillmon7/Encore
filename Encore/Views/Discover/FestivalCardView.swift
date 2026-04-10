// Encore/Views/Discover/FestivalCardView.swift
import SwiftUI

struct FestivalCardView: View {

    let festival: Festival

    private var accentColor: Color {
        Color(hex: festival.imageColorHex) ?? .appCTA
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left accent bar
            Rectangle()
                .fill(accentColor)
                .frame(width: 4)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(festival.name)
                        .font(DS.Font.cardTitle)
                        .foregroundColor(.appTextPrimary)
                    Spacer()
                    statusBadge
                }

                Text("\(dateRangeLabel)  ·  \(festival.location)")
                    .font(DS.Font.metadata)
                    .foregroundColor(.appTextMuted)

                // Genre chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(festival.genres, id: \.self) { genre in
                            Text(genre)
                                .font(DS.Font.caps)
                                .foregroundColor(accentColor)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(accentColor.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(DS.Spacing.cardPadding)
        }
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card)
            .stroke(accentColor.opacity(0.25), lineWidth: 1))
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch festival.status {
        case .active:
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.appCTA)
                    .frame(width: 6, height: 6)
                    .overlay(
                        Circle()
                            .fill(Color.appCTA.opacity(0.4))
                            .frame(width: 12, height: 12)
                    )
                Text("Happening now")
                    .font(DS.Font.caps)
                    .foregroundColor(.appCTA)
            }
        case .upcoming:
            Text(daysUntilLabel)
                .font(DS.Font.caps)
                .foregroundColor(.appAccent)
        case .past:
            EmptyView()
        }
    }

    private var dateRangeLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        let g = DateFormatter()
        g.dateFormat = "d, yyyy"
        return "\(f.string(from: festival.startDate))–\(g.string(from: festival.endDate))"
    }

    private var daysUntilLabel: String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: festival.startDate).day ?? 0
        return days > 0 ? "In \(days) days" : "Soon"
    }
}

#Preview {
    VStack(spacing: 12) {
        FestivalCardView(festival: Festival.mockFestivals[0])
        FestivalCardView(festival: Festival.mockFestivals[1])
        FestivalCardView(festival: Festival.mockFestivals[2])
    }
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
