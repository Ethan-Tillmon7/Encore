// Encore/Stores/FestivalStore.swift
import Foundation
import Combine

class FestivalStore: ObservableObject {
    @Published var festivals: [Festival] = []

    @Published var selectedFestival: Festival? {
        didSet {
            if let id = selectedFestival?.id.uuidString {
                UserDefaults.standard.set(id, forKey: StorageKey.selectedFestivalID)
            } else {
                UserDefaults.standard.removeObject(forKey: StorageKey.selectedFestivalID)
            }
        }
    }

    @Published var travelDetails: [UUID: TravelDetails] = [:] {
        didSet { persistTravelDetails() }
    }

    init() {
        // Seed festivals from mock data — in the future, swap for a real data source
        festivals = Festival.mockFestivals

        // Restore selected festival
        if let savedID = UserDefaults.standard.string(forKey: StorageKey.selectedFestivalID),
           let uuid = UUID(uuidString: savedID) {
            selectedFestival = festivals.first { $0.id == uuid }
        }

        // Restore travel details
        if let data = UserDefaults.standard.data(forKey: StorageKey.travelDetails),
           let decoded = try? JSONDecoder().decode([String: TravelDetails].self, from: data) {
            travelDetails = Dictionary(uniqueKeysWithValues: decoded.compactMap { k, v in
                guard let uuid = UUID(uuidString: k) else { return nil }
                return (uuid, v)
            })
        }
    }

    // MARK: - Persistence

    private func persistTravelDetails() {
        let stringKeyed = Dictionary(uniqueKeysWithValues: travelDetails.map { ($0.key.uuidString, $0.value) })
        guard let data = try? JSONEncoder().encode(stringKeyed) else { return }
        UserDefaults.standard.set(data, forKey: StorageKey.travelDetails)
    }

    // MARK: - API

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
