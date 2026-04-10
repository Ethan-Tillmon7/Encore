// Encore/Views/Discover/FestivalCardView.swift
import SwiftUI

struct FestivalCardView: View {
    let festival: Festival

    var body: some View {
        Text("TODO: FestivalCardView")
            .foregroundColor(.primary)
    }
}

#Preview {
    let dummyFestival = Festival(
        id: UUID(),
        name: "Bonnaroo",
        location: "Manchester, TN",
        startDate: Date(),
        endDate: Date().addingTimeInterval(86400 * 3),
        status: .upcoming,
        genres: ["Rock", "Indie", "Hip-Hop"],
        imageColorHex: "#FF6B6B",
        lineup: [],
        sets: []
    )
    FestivalCardView(festival: dummyFestival)
}
