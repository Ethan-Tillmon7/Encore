// Encore/Models/StageWalkTime.swift
import Foundation

struct StageWalkTime: Codable {
    var fromStage: String
    var toStage: String
    var walkMinutes: Int

    static func minutes(from: String, to: String) -> Int? {
        let key1 = "\(from)→\(to)"
        let key2 = "\(to)→\(from)"
        return walkTable[key1] ?? walkTable[key2]
    }

    private static let walkTable: [String: Int] = [
        "What Stage→Which Stage": 4,
        "What Stage→This Tent": 8,
        "What Stage→That Tent": 10,
        "What Stage→Other Stage": 7,
        "Which Stage→This Tent": 6,
        "Which Stage→That Tent": 8,
        "Which Stage→Other Stage": 5,
        "This Tent→That Tent": 3,
        "This Tent→Other Stage": 9,
        "That Tent→Other Stage": 7
    ]
}
