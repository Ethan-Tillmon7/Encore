// Encore/Stores/FestivalStore.swift
import Foundation
import Combine

class FestivalStore: ObservableObject {
    @Published var festivals: [Festival] = []
    @Published var selectedFestival: Festival?
    @Published var travelDetails: [UUID: TravelDetails] = [:]

    func festivals(for status: FestivalStatus) -> [Festival] {
        festivals.filter { $0.status == status }
    }

    func selectFestival(_ festival: Festival) {
        selectedFestival = festival
    }

    func saveTravelDetails(_ details: TravelDetails, for festivalID: UUID) {
        travelDetails[festivalID] = details
    }
}
