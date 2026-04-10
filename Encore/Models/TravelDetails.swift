// Encore/Models/TravelDetails.swift
import Foundation

struct PackingItem: Identifiable, Codable {
    var id: UUID
    var name: String
    var isPacked: Bool
    var category: String
}

struct ExpenseItem: Identifiable, Codable {
    var id: UUID
    var description: String
    var amount: Double
    var paidBy: String
    var date: Date
}

struct TravelDetails: Codable {
    var festivalID: UUID
    var arrivalDate: Date?
    var departureDate: Date?
    var transportMode: String?
    var accommodationType: String?
    var campsite: String?
    var packingItems: [PackingItem]
    var expenses: [ExpenseItem]
}
