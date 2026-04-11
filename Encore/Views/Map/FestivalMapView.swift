// Encore/Views/Map/FestivalMapView.swift
import SwiftUI
import MapKit

// MARK: - Stage (local model)

private struct Stage: Identifiable {
    let id: String   // stage name doubles as stable ID
    let name: String
    let coordinate: CLLocationCoordinate2D

    var shortName: String {
        switch name {
        case "What Stage":  return "WHAT"
        case "Which Stage": return "WHICH"
        case "This Tent":   return "THIS"
        case "That Tent":   return "THAT"
        case "Other Stage": return "OTHER"
        default:            return String(name.prefix(5)).uppercased()
        }
    }

    // Approximate Bonnaroo Centeroo coordinates (Manchester, TN)
    static let bonnarooStages: [Stage] = [
        Stage(id: "What Stage",  name: "What Stage",  coordinate: .init(latitude: 35.4968, longitude: -86.0854)),
        Stage(id: "Which Stage", name: "Which Stage", coordinate: .init(latitude: 35.4985, longitude: -86.0843)),
        Stage(id: "This Tent",   name: "This Tent",   coordinate: .init(latitude: 35.4963, longitude: -86.0829)),
        Stage(id: "That Tent",   name: "That Tent",   coordinate: .init(latitude: 35.4950, longitude: -86.0840)),
        Stage(id: "Other Stage", name: "Other Stage", coordinate: .init(latitude: 35.4975, longitude: -86.0868)),
    ]
}

// MARK: - Festival Amenity (local model)

private struct FestivalAmenity: Identifiable {
    enum Kind { case water, medical, charging }
    let id = UUID()
    let kind: Kind
    let coordinate: CLLocationCoordinate2D

    var icon: String {
        switch kind {
        case .water:    return "drop.fill"
        case .medical:  return "cross.fill"
        case .charging: return "bolt.fill"
        }
    }

    var color: Color {
        switch kind {
        case .water:    return Color(red: 0.2, green: 0.6, blue: 1.0)
        case .medical:  return Color(red: 0.9, green: 0.2, blue: 0.2)
        case .charging: return Color(red: 0.95, green: 0.75, blue: 0.1)
        }
    }

    // Approximate amenity locations within Centeroo
    static let bonnarooAmenities: [FestivalAmenity] = [
        .init(kind: .water,    coordinate: .init(latitude: 35.4972, longitude: -86.0850)),
        .init(kind: .water,    coordinate: .init(latitude: 35.4957, longitude: -86.0835)),
        .init(kind: .water,    coordinate: .init(latitude: 35.4988, longitude: -86.0862)),
        .init(kind: .medical,  coordinate: .init(latitude: 35.4966, longitude: -86.0870)),
        .init(kind: .charging, coordinate: .init(latitude: 35.4976, longitude: -86.0848)),
    ]
}

// MARK: - Combined map annotation item

private struct MapPin: Identifiable {
    enum Kind {
        case stage(Stage)
        case amenity(FestivalAmenity)
        case meetup(MeetupPin)
        case crewMember(CrewMember)
    }
    let id: String
    let coordinate: CLLocationCoordinate2D
    let kind: Kind
}

// MARK: - Downward-pointing triangle for stage pin callout

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

// MARK: - FestivalMapView

struct FestivalMapView: View {

    /// Deep-link: open the map centered on this stage and show its card.
    var initialStage: String? = nil

    @EnvironmentObject var scheduleStore: ScheduleStore
    @EnvironmentObject var lineupStore:   LineupStore
    @EnvironmentObject var crewStore:     CrewStore

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.4968, longitude: -86.0854),
        span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
    )
    @State private var selectedStage: Stage? = nil
    @State private var showWater    = false
    @State private var showMedical  = false
    @State private var showCharging = false
    @State private var showPinSheet = false
    @State private var newPinLabel  = ""

    private let stages      = Stage.bonnarooStages
    private let allAmenities = FestivalAmenity.bonnarooAmenities

    // MARK: - Visible annotations (filtered by toggle state)

    private var visiblePins: [MapPin] {
        var pins: [MapPin] = []

        for stage in stages {
            pins.append(MapPin(
                id: "stage-\(stage.id)",
                coordinate: stage.coordinate,
                kind: .stage(stage)
            ))
        }

        for amenity in allAmenities {
            let visible: Bool
            switch amenity.kind {
            case .water:    visible = showWater
            case .medical:  visible = showMedical
            case .charging: visible = showCharging
            }
            if visible {
                pins.append(MapPin(
                    id: "amenity-\(amenity.id)",
                    coordinate: amenity.coordinate,
                    kind: .amenity(amenity)
                ))
            }
        }

        for pin in crewStore.meetupPins {
            pins.append(MapPin(
                id: "meetup-\(pin.id)",
                coordinate: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude),
                kind: .meetup(pin)
            ))
        }

        // Crew member location stubs — derived from lastSeenStage
        if let crew = crewStore.crew {
            for (i, member) in crew.members.enumerated() {
                guard let lastSeen = member.lastSeenStage,
                      let stageName = lastSeen.components(separatedBy: " · ").first,
                      let stage = stages.first(where: { $0.name == stageName })
                else { continue }
                // Small per-member offset so avatars don't perfectly stack
                let angle = Double(i) * (.pi / 2)
                let r = 0.00015
                let coord = CLLocationCoordinate2D(
                    latitude:  stage.coordinate.latitude  + r * sin(angle),
                    longitude: stage.coordinate.longitude + r * cos(angle)
                )
                pins.append(MapPin(
                    id: "crew-\(member.id)",
                    coordinate: coord,
                    kind: .crewMember(member)
                ))
            }
        }

        return pins
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            mapContent
            amenityBar
        }
        .navigationTitle("Map")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showPinSheet = true }) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.appCTA)
                }
            }
        }
        .sheet(isPresented: $showPinSheet) {
            pinManagementSheet
        }
        .onAppear {
            if let name = initialStage, let match = stages.first(where: { $0.name == name }) {
                withAnimation(.easeInOut) { region.center = match.coordinate }
                selectedStage = match
            }
        }
    }

    // MARK: - Map

    private var mapContent: some View {
        Map(coordinateRegion: $region,
            showsUserLocation: false,
            annotationItems: visiblePins) { pin in
            MapAnnotation(coordinate: pin.coordinate) {
                annotationView(for: pin)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .safeAreaInset(edge: .bottom) {
            if let stage = selectedStage {
                stageCard(for: stage)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35), value: selectedStage?.id)
    }

    // MARK: - Amenity toggles

    private var amenityBar: some View {
        HStack(spacing: 8) {
            amenityToggle("Water",    icon: "drop.fill",  isOn: $showWater,
                          onColor: Color(red: 0.2, green: 0.6, blue: 1.0))
            amenityToggle("Medical",  icon: "cross.fill", isOn: $showMedical,
                          onColor: Color(red: 0.9, green: 0.2, blue: 0.2))
            amenityToggle("Charging", icon: "bolt.fill",  isOn: $showCharging,
                          onColor: Color(red: 0.95, green: 0.75, blue: 0.1))
            Spacer()
        }
        .padding(.horizontal, DS.Spacing.pageMargin)
        .padding(.top, 8)
    }

    private func amenityToggle(
        _ label: String,
        icon: String,
        isOn: Binding<Bool>,
        onColor: Color
    ) -> some View {
        Button(action: { isOn.wrappedValue.toggle() }) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(label)
                    .font(DS.Font.caps)
            }
            .foregroundColor(isOn.wrappedValue ? onColor : .appTextMuted)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(isOn.wrappedValue ? onColor.opacity(0.15) : Color.appSurface)
            .clipShape(Capsule())
            .overlay(Capsule()
                .stroke(isOn.wrappedValue ? onColor.opacity(0.5) : Color.clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Annotation views

    @ViewBuilder
    private func annotationView(for pin: MapPin) -> some View {
        switch pin.kind {
        case .stage(let stage):
            stagePin(stage: stage)
        case .amenity(let amenity):
            amenityDot(amenity: amenity)
        case .meetup(let meetup):
            meetupDot(meetup: meetup)
        case .crewMember(let member):
            crewMemberDot(member: member)
        }
    }

    private func stagePin(stage: Stage) -> some View {
        let isSelected = selectedStage?.id == stage.id
        return Button(action: {
            withAnimation(.spring(response: 0.3)) {
                if isSelected {
                    selectedStage = nil
                } else {
                    selectedStage = stage
                    withAnimation(.easeInOut(duration: 0.4)) {
                        region.center = stage.coordinate
                    }
                }
            }
        }) {
            VStack(spacing: 2) {
                Text(stage.shortName)
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(isSelected ? Color.appBackground : .appCTA)
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(isSelected ? Color.appCTA : Color.appBackground.opacity(0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .overlay(RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.appCTA, lineWidth: 1.5))
                Triangle()
                    .fill(isSelected ? Color.appCTA : Color.appBackground.opacity(0.92))
                    .frame(width: 8, height: 5)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.15 : 1.0)
        .animation(.spring(response: 0.25), value: isSelected)
    }

    private func amenityDot(amenity: FestivalAmenity) -> some View {
        Image(systemName: amenity.icon)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(amenity.color)
            .padding(6)
            .background(Color.appBackground.opacity(0.92))
            .clipShape(Circle())
            .overlay(Circle().stroke(amenity.color.opacity(0.5), lineWidth: 1))
    }

    private func meetupDot(meetup: MeetupPin) -> some View {
        VStack(spacing: 2) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.appWarn)
            Text(meetup.label)
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(.appWarn)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Color.appBackground.opacity(0.92))
                .clipShape(Capsule())
        }
    }

    private func crewMemberDot(member: CrewMember) -> some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(member.color)
                    .frame(width: 28, height: 28)
                    .overlay(Circle().stroke(Color.appBackground, lineWidth: 2))
                Text(member.initials)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color.appBackground)
            }
            // Online indicator
            if member.isOnline {
                Circle()
                    .fill(Color.appCTA)
                    .frame(width: 6, height: 6)
                    .overlay(Circle().stroke(Color.appBackground, lineWidth: 1))
                    .offset(y: -4)
            }
        }
    }

    // MARK: - Stage card

    private func stageCard(for stage: Stage) -> some View {
        let now = Date()
        let stageSets = lineupStore.allSets
            .filter { $0.stageName == stage.name }
            .sorted { $0.startTime < $1.startTime }
        let currentSet = stageSets.first { $0.startTime <= now && $0.endTime > now }
        let nextSet    = stageSets.first { $0.startTime > now }
        let walkTime   = walkMinutesFromLastSet(to: stage.name)

        return VStack(alignment: .leading, spacing: DS.Spacing.sectionGap) {
            HStack {
                Text(stage.name)
                    .font(DS.Font.cardTitle)
                    .foregroundColor(.appTextPrimary)
                Spacer()
                Button(action: { withAnimation { selectedStage = nil } }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.appTextMuted)
                }
                .buttonStyle(.plain)
            }

            if let set = currentSet {
                HStack(spacing: 8) {
                    Circle().fill(Color.appCTA).frame(width: 8, height: 8)
                    Text("Now: \(set.artist.name)")
                        .font(DS.Font.listItem)
                        .foregroundColor(.appCTA)
                    Spacer()
                    Text(set.timeRangeLabel)
                        .font(DS.Font.metadata)
                        .foregroundColor(.appTextMuted)
                }
            }

            if let set = nextSet {
                HStack(spacing: 8) {
                    Circle().fill(Color.appTextMuted.opacity(0.35)).frame(width: 8, height: 8)
                    Text("Next: \(set.artist.name)")
                        .font(DS.Font.listItem)
                        .foregroundColor(.appTextMuted)
                    Spacer()
                    Text(set.timeRangeLabel)
                        .font(DS.Font.metadata)
                        .foregroundColor(.appTextMuted)
                }
            }

            if currentSet == nil && nextSet == nil {
                Text("No upcoming sets at this stage.")
                    .font(DS.Font.metadata)
                    .foregroundColor(.appTextMuted)
            }

            if let walk = walkTime {
                HStack(spacing: 5) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 11))
                    Text("~\(walk) min walk from your last set")
                        .font(DS.Font.metadata)
                }
                .foregroundColor(.appAccent)
            }
        }
        .padding(DS.Spacing.cardPadding)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card)
            .stroke(Color.appAccent.opacity(0.18), lineWidth: 1))
        .padding(.horizontal, DS.Spacing.pageMargin)
        .padding(.bottom, 8)
        .background(Color.appBackground)
    }

    // MARK: - Pin management sheet

    private var pinManagementSheet: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.sectionGap) {
                    Text("Pins are placed at the center of your current map view. Pan first, then drop.")
                        .font(DS.Font.metadata)
                        .foregroundColor(.appTextMuted)
                        .padding(.top, 8)

                    TextField("Label (e.g. Meet here, Water station…)", text: $newPinLabel)
                        .font(DS.Font.listItem)
                        .foregroundColor(.appTextPrimary)
                        .padding(12)
                        .background(Color.appSurface)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))

                    Button(action: dropPin) {
                        Text("Drop Pin")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(newPinLabel.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color.appSurface : Color.appCTA)
                            .foregroundColor(newPinLabel.trimmingCharacters(in: .whitespaces).isEmpty
                                ? .appTextMuted : Color.appBackground)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
                    }
                    .disabled(newPinLabel.trimmingCharacters(in: .whitespaces).isEmpty)

                    if !crewStore.meetupPins.isEmpty {
                        VStack(alignment: .leading, spacing: DS.Spacing.sectionGap) {
                            Text("ACTIVE PINS")
                                .font(DS.Font.caps)
                                .foregroundColor(.appTextMuted)
                                .tracking(0.8)
                                .padding(.top, DS.Spacing.sectionGap)

                            ForEach(crewStore.meetupPins) { pin in
                                HStack(spacing: 12) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.appWarn)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(pin.label)
                                            .font(DS.Font.listItem)
                                            .foregroundColor(.appTextPrimary)
                                        Text(String(format: "%.4f, %.4f", pin.latitude, pin.longitude))
                                            .font(DS.Font.caps)
                                            .foregroundColor(.appTextMuted)
                                    }
                                    Spacer()
                                    Button(action: { crewStore.removePin(pin) }) {
                                        Image(systemName: "minus.circle")
                                            .font(.system(size: 20))
                                            .foregroundColor(.appTextMuted.opacity(0.6))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(DS.Spacing.cardPadding)
                                .background(Color.appSurface)
                                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
                            }
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.pageMargin)
                .padding(.bottom, 40)
            }
            .background(Color.appBackground)
            .navigationTitle("Meetup Pins")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { showPinSheet = false; newPinLabel = "" }
                        .foregroundColor(.appCTA)
                }
            }
        }
    }

    // MARK: - Helpers

    private func dropPin() {
        let trimmed = newPinLabel.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let pin = MeetupPin(
            id: UUID(),
            label: trimmed,
            latitude: region.center.latitude,
            longitude: region.center.longitude,
            createdBy: UUID()   // Phase 2: use logged-in user ID
        )
        crewStore.meetupPins.append(pin)
        newPinLabel = ""
        showPinSheet = false
    }

    private func walkMinutesFromLastSet(to stageName: String) -> Int? {
        let now = Date()
        guard let lastSet = scheduleStore.scheduledSets
            .filter({ $0.endTime <= now })
            .sorted(by: { $0.endTime > $1.endTime })
            .first,
              lastSet.stageName != stageName
        else { return nil }
        return StageWalkTime.minutes(from: lastSet.stageName, to: stageName) ?? 8
    }
}

#Preview {
    NavigationStack {
        FestivalMapView()
    }
    .environmentObject(ScheduleStore())
    .environmentObject(LineupStore())
    .environmentObject(CrewStore())
    .preferredColorScheme(.dark)
}
