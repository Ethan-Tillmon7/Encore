import SwiftUI
import MapKit

// Bonnaroo is located in Manchester, TN
private let bonnarooCenter = CLLocationCoordinate2D(latitude: 35.4897, longitude: -86.0814)

struct FestivalMapView: View {

    var initialStage: String? = nil

    @EnvironmentObject var scheduleStore: ScheduleStore
    @EnvironmentObject var crewStore: CrewStore

    @State private var region = MKCoordinateRegion(
        center: bonnarooCenter,
        span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
    )
    @State private var showAmenities = false
    @State private var selectedStage: StageAnnotation? = nil

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {

                // Map
                Map(coordinateRegion: $region, annotationItems: visibleAnnotations) { annotation in
                    MapAnnotation(coordinate: annotation.coordinate) {
                        stageMarker(annotation: annotation)
                    }
                }
                .ignoresSafeArea(edges: .top)

                // Bottom overlay
                VStack(spacing: 0) {
                    // Amenity toggle
                    mapControls

                    // Stage info sheet (when a stage is tapped)
                    if let stage = selectedStage {
                        stageInfoCard(stage: stage)
                    }
                }
                .padding(.bottom, 8)
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { crewStore.isLocationSharingEnabled.toggle() }) {
                        Image(systemName: crewStore.isLocationSharingEnabled ? "location.fill" : "location")
                            .foregroundColor(crewStore.isLocationSharingEnabled ? .purple : .secondary)
                    }
                }
            }
        }
    }

    // MARK: - Stage annotations

    private var visibleAnnotations: [StageAnnotation] {
        var annotations = StageAnnotation.bonnarooStages
        if showAmenities {
            annotations += StageAnnotation.amenities
        }
        return annotations
    }

    private func stageMarker(annotation: StageAnnotation) -> some View {
        Button(action: {
            selectedStage = selectedStage?.id == annotation.id ? nil : annotation
        }) {
            VStack(spacing: 3) {
                ZStack {
                    Circle()
                        .fill(annotation.kind == .stage ? Color.purple : Color.blue.opacity(0.8))
                        .frame(width: annotation.kind == .stage ? 36 : 24,
                               height: annotation.kind == .stage ? 36 : 24)
                    Image(systemName: annotation.kind.icon)
                        .font(.system(size: annotation.kind == .stage ? 14 : 10))
                        .foregroundColor(.white)
                }
                Text(annotation.shortName)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Controls

    private var mapControls: some View {
        HStack {
            Button(action: { showAmenities.toggle() }) {
                Label(showAmenities ? "Hide Amenities" : "Show Amenities",
                      systemImage: showAmenities ? "eye.slash" : "mappin.and.ellipse")
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Spacer()

            // Crew location toggle
            if let crew = crewStore.crew {
                HStack(spacing: -6) {
                    ForEach(crew.members.filter { $0.isOnline }.prefix(4)) { member in
                        Circle()
                            .fill(member.color)
                            .frame(width: 26, height: 26)
                            .overlay(Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 1.5))
                            .overlay(Text(String(member.initials.prefix(1))).font(.system(size: 10, weight: .bold)).foregroundColor(.white))
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Stage Info Card

    private func stageInfoCard(stage: StageAnnotation) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(stage.name)
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Button(action: { selectedStage = nil }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }

            if let current = stage.currentAct {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("NOW PLAYING")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.purple)
                        Text(current)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Spacer()
                    // Walking time estimate (placeholder)
                    Label("~8 min walk", systemImage: "figure.walk")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            if let next = stage.nextAct {
                Text("Up next: \(next)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
        .shadow(color: .black.opacity(0.2), radius: 8, y: 2)
    }
}

// MARK: - Stage Annotation Model

struct StageAnnotation: Identifiable {
    let id = UUID()
    var name: String
    var shortName: String
    var coordinate: CLLocationCoordinate2D
    var kind: Kind
    var currentAct: String?
    var nextAct: String?

    enum Kind {
        case stage, bathroom, water, medical, charging

        var icon: String {
            switch self {
            case .stage:    return "music.mic"
            case .bathroom: return "toilet"
            case .water:    return "drop.fill"
            case .medical:  return "cross.fill"
            case .charging: return "bolt.fill"
            }
        }
    }

    // Approximate Bonnaroo stage locations
    static let bonnarooStages: [StageAnnotation] = [
        StageAnnotation(name: "What Stage", shortName: "What", coordinate: CLLocationCoordinate2D(latitude: 35.4905, longitude: -86.0820), kind: .stage, currentAct: "Hozier", nextAct: "LCD Soundsystem"),
        StageAnnotation(name: "Which Stage", shortName: "Which", coordinate: CLLocationCoordinate2D(latitude: 35.4890, longitude: -86.0830), kind: .stage, currentAct: "ODESZA", nextAct: nil),
        StageAnnotation(name: "This Tent", shortName: "This", coordinate: CLLocationCoordinate2D(latitude: 35.4895, longitude: -86.0800), kind: .stage, currentAct: "Japanese Breakfast", nextAct: "MUNA"),
        StageAnnotation(name: "That Tent", shortName: "That", coordinate: CLLocationCoordinate2D(latitude: 35.4880, longitude: -86.0810), kind: .stage, currentAct: nil, nextAct: "Sylvan Esso"),
        StageAnnotation(name: "Other Stage", shortName: "Other", coordinate: CLLocationCoordinate2D(latitude: 35.4870, longitude: -86.0825), kind: .stage, currentAct: "Wet Leg", nextAct: nil),
    ]

    static let amenities: [StageAnnotation] = [
        StageAnnotation(name: "Water Station", shortName: "H2O", coordinate: CLLocationCoordinate2D(latitude: 35.4900, longitude: -86.0815), kind: .water),
        StageAnnotation(name: "Medical", shortName: "Med", coordinate: CLLocationCoordinate2D(latitude: 35.4898, longitude: -86.0808), kind: .medical),
        StageAnnotation(name: "Charging", shortName: "⚡", coordinate: CLLocationCoordinate2D(latitude: 35.4885, longitude: -86.0818), kind: .charging),
    ]
}

#Preview {
    FestivalMapView()
        .environmentObject(ScheduleStore())
        .environmentObject(CrewStore())
        .preferredColorScheme(.dark)
}
