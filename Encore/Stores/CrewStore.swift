import Foundation
import Combine

class CrewStore: ObservableObject {

    @Published var crew: Crew? = Crew.mockCrew  // nil until user creates/joins
    @Published var meetupPins: [MeetupPin] = []

    // MARK: - Crew management

    func createCrew(name: String) {
        let newCrew = Crew(
            id: UUID(),
            name: name,
            inviteCode: Crew.generateInviteCode(),
            members: [
                CrewMember(id: UUID(), name: "You", colorHex: "8B5CF6",
                           scheduledSetIDs: [], isOnline: true, lastSeenStage: nil)
            ]
        )
        crew = newCrew
    }

    func joinCrew(code: String) {
        // TODO: Fetch crew from Supabase by invite code
        crew = Crew.mockCrew
    }

    func leaveCrew() {
        crew = nil
    }

    // MARK: - Meetup pins

    func removePin(_ pin: MeetupPin) {
        meetupPins.removeAll { $0.id == pin.id }
    }

    // MARK: - Merged timeline helpers

    /// All sets across all crew members, deduplicated and sorted
    func mergedSets(allSets: [FestivalSet]) -> [FestivalSet] {
        guard let crew = crew else { return [] }
        let memberSetIDs = Set(crew.members.flatMap { $0.scheduledSetIDs })
        return allSets.filter { memberSetIDs.contains($0.id) }
                      .sorted { $0.startTime < $1.startTime }
    }

    /// Members attending a specific set
    func attendees(for set: FestivalSet) -> [CrewMember] {
        guard let crew = crew else { return [] }
        return crew.members.filter { $0.scheduledSetIDs.contains(set.id) }
    }
}
