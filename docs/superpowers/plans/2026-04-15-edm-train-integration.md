# EDM Train Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate EDM Train API to surface upcoming electronic music events alongside Supabase festivals in the Fests tab, with a source badge and in-app detail sheet linking back to EDM Train per their ToS.

**Architecture:** `FestivalSource` enum + two new fields on `Festival` let EDM Train events flow through the existing store/filter/card/detail pipeline unchanged. A new `EDMTrainService` actor fetches events by location ID derived from the active festival's coordinates. `FestivalListView` triggers the fetch via `.task(id:)` and appends results to `FestivalDiscoveryStore.allFestivals`.

**Tech Stack:** Swift 5.9, SwiftUI (iOS 16), URLSession (no new SPM packages), XcodeGen

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `Encore/Models/Festival.swift` | Modify | Add `FestivalSource` enum, `source` + `eventURL` fields |
| `Encore/Utilities/APIKeys.swift` | Modify | Add `edmTrain` key |
| `Encore/Services/EDMTrainService.swift` | Create | DTOs, Haversine location mapping, `fetchEvents` |
| `Encore/Stores/FestivalDiscoveryStore.swift` | Modify | Add `loadEDMTrainEvents(latitude:longitude:)` |
| `Encore/Views/Discover/FestivalListView.swift` | Modify | Trigger EDM Train fetch on active festival change |
| `Encore/Views/Discover/FestivalCardView.swift` | Modify | Source badge for `.edmTrain` events |
| `Encore/Views/Discover/FestivalDetailView.swift` | Modify | Conditional CTA + source badge + hide Travel row |

---

## Task 1: Add `FestivalSource` enum and new fields to `Festival`

**Files:**
- Modify: `Encore/Models/Festival.swift`

- [ ] **Step 1: Add `FestivalSource` enum and new fields**

Open `Encore/Models/Festival.swift`. Add the enum before `FestivalStatus` and add two new fields to `Festival` with defaults so all existing initialisers continue to compile:

```swift
// Encore/Models/Festival.swift
import Foundation

enum FestivalSource: String, Codable {
    case supabase
    case edmTrain
}

enum FestivalStatus: String, Codable {
    case upcoming, active, past
}

struct Festival: Identifiable, Codable {
    var id: UUID
    var name: String
    var slug: String
    var location: String
    var latitude: Double
    var longitude: Double
    var startDate: Date
    var endDate: Date
    var status: FestivalStatus
    var isCamping: Bool
    var genres: [String]
    var imageColorHex: String
    var lineup: [Artist]
    var sets: [FestivalSet]
    var source: FestivalSource = .supabase   // ← new; default keeps all existing inits working
    var eventURL: URL?                        // ← new; nil for Supabase festivals

    var region: RegionFilter {
        guard latitude >= 24 && latitude <= 72 && longitude >= -180 && longitude <= -67 else {
            return .international
        }
        if longitude <= -114 { return .west }
        if latitude < 37 && longitude > -114 && longitude <= -93 { return .southwest }
        if latitude >= 36 && longitude > -104 && longitude <= -80 { return .midwest }
        if latitude < 37 && longitude > -93 { return .southeast }
        if latitude >= 37 && longitude > -80 { return .northeast }
        return .west
    }
}
```

- [ ] **Step 2: Build and verify no compile errors**

In Xcode press `Cmd+B`. Expected: Build Succeeded. All existing call sites that construct `Festival` still compile because both new fields have default values.

- [ ] **Step 3: Commit**

```bash
git add Encore/Models/Festival.swift
git commit -m "feat: add FestivalSource enum and source/eventURL fields to Festival"
```

---

## Task 2: Add EDM Train API key

**Files:**
- Modify: `Encore/Utilities/APIKeys.swift`

- [ ] **Step 1: Add the key**

```swift
// Encore/Utilities/APIKeys.swift
import Foundation

enum APIKeys {
    static let setlistFM    = "B0c_6tV4uMm2FhVpkSPIjfemh6HGeUwKSSRe"
    static let supabaseURL  = "https://ktauirvbnaluzwmaiynu.supabase.co"
    static let supabaseAnon = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt0YXVpcnZibmFsdXp3bWFpeW51Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYxMzc0MzcsImV4cCI6MjA5MTcxMzQzN30.UjZlVasXYBJoVKXrI2qLIJPT7rMJjGbLeRKZ90FufPM"
    static let edmTrain     = "b1b7e0c7-ac07-4885-a201-3a20f484d466"   // ← new
}
```

- [ ] **Step 2: Build**

`Cmd+B`. Expected: Build Succeeded.

- [ ] **Step 3: Commit**

```bash
git add Encore/Utilities/APIKeys.swift
git commit -m "feat: add EDM Train API key to APIKeys"
```

---

## Task 3: Create `EDMTrainService`

**Files:**
- Create: `Encore/Services/EDMTrainService.swift`

- [ ] **Step 1: Discover EDM Train location IDs**

Run this in Terminal to fetch the full location list:

```bash
curl -s "https://edmtrain.com/api/locations?client=b1b7e0c7-ac07-4885-a201-3a20f484d466" | python3 -m json.tool | grep -E '"id"|"name"' | paste - -
```

Look for the IDs of these metro areas in the response: Los Angeles, San Francisco, New York, Chicago, Miami, Las Vegas, Denver, Seattle, Austin, Atlanta, Nashville, New Orleans. You will use these exact integer IDs in Step 2.

- [ ] **Step 2: Create `EDMTrainService.swift`**

Create `Encore/Services/EDMTrainService.swift` with the IDs you found in Step 1 filled into `metroLocations`. The file below shows the complete implementation — replace the placeholder IDs in `metroLocations` with the real ones from the curl output:

```swift
// Encore/Services/EDMTrainService.swift
import Foundation

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Response DTOs
// ─────────────────────────────────────────────────────────────────────────────

private struct EDMTrainResponse: Decodable {
    let success: Bool
    let data: [EDMTrainEventRow]?
}

private struct EDMTrainEventRow: Decodable {
    let id: Int
    let link: String?
    let date: String?           // "YYYY-MM-DD"
    let name: String?
    let artists: [EDMTrainArtistRow]?
    let venue: EDMTrainVenueRow?
}

private struct EDMTrainArtistRow: Decodable {
    let name: String
}

private struct EDMTrainVenueRow: Decodable {
    let name: String?
    let location: String?       // "City, State"
    let latitude: Double?
    let longitude: Double?
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - EDMTrainService
// ─────────────────────────────────────────────────────────────────────────────

actor EDMTrainService {

    static let shared = EDMTrainService()

    // ── Location mapping ─────────────────────────────────────────────────────

    /// Metro areas mapped to their EDM Train location IDs.
    /// Populate IDs from: GET https://edmtrain.com/api/locations?client=<key>
    private static let metroLocations: [(name: String, lat: Double, lon: Double, id: Int)] = [
        ("Los Angeles",   34.0522, -118.2437, 0),   // TODO: replace 0 with real ID
        ("San Francisco", 37.7749, -122.4194, 0),
        ("New York",      40.7128,  -74.0060, 0),
        ("Chicago",       41.8781,  -87.6298, 0),
        ("Miami",         25.7617,  -80.1918, 0),
        ("Las Vegas",     36.1699, -115.1398, 0),
        ("Denver",        39.7392, -104.9903, 0),
        ("Seattle",       47.6062, -122.3321, 0),
        ("Austin",        30.2672,  -97.7431, 0),
        ("Atlanta",       33.7490,  -84.3880, 0),
        ("Nashville",     36.1627,  -86.7816, 0),
        ("New Orleans",   29.9511,  -90.0715, 0),
    ]

    private static let defaultLocationId = metroLocations[0].id  // Los Angeles fallback

    /// Returns the EDM Train location ID nearest to the given coordinates.
    /// Falls back to Los Angeles if coordinates are (0, 0) or no metros are defined.
    static func nearestLocationId(latitude: Double, longitude: Double) -> Int {
        // (0, 0) is the Festival default when Supabase omits coordinates
        guard latitude != 0 || longitude != 0 else { return defaultLocationId }
        guard !metroLocations.isEmpty else { return defaultLocationId }

        var closest = metroLocations[0]
        var minDist = haversineKm(lat1: latitude, lon1: longitude,
                                  lat2: closest.lat, lon2: closest.lon)
        for metro in metroLocations.dropFirst() {
            let dist = haversineKm(lat1: latitude, lon1: longitude,
                                   lat2: metro.lat, lon2: metro.lon)
            if dist < minDist {
                minDist = dist
                closest = metro
            }
        }
        return closest.id
    }

    // ── Event fetch ──────────────────────────────────────────────────────────

    func fetchEvents(locationId: Int) async throws -> [Festival] {
        guard locationId != 0 else { return [] }   // guard against unfilled placeholder IDs

        var components = URLComponents(string: "https://edmtrain.com/api/events")!
        components.queryItems = [
            URLQueryItem(name: "locationIds", value: "\(locationId)"),
            URLQueryItem(name: "client",      value: APIKeys.edmTrain),
        ]
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let response  = try JSONDecoder().decode(EDMTrainResponse.self, from: data)
        return (response.data ?? []).compactMap { toFestival($0) }
    }

    // ── Mapping ──────────────────────────────────────────────────────────────

    private func toFestival(_ row: EDMTrainEventRow) -> Festival? {
        guard let dateStr = row.date, let date = parseDate(dateStr) else { return nil }

        let artistNames = (row.artists ?? []).map(\.name)
        let eventName   = row.name?.isEmpty == false ? row.name! :
                          artistNames.isEmpty ? "Electronic Event" :
                          artistNames.prefix(3).joined(separator: " & ")

        // Deterministic UUID: version-4 shaped UUID where the last 12 hex chars encode the EDM Train event ID.
        let paddedHex  = String(format: "%012x", row.id)
        let uuidString = "00000000-0000-4000-8000-\(paddedHex)"
        let eventId    = UUID(uuidString: uuidString) ?? UUID()

        return Festival(
            id:            eventId,
            name:          eventName,
            slug:          "edmtrain-\(row.id)",
            location:      row.venue?.location ?? "",
            latitude:      row.venue?.latitude  ?? 0,
            longitude:     row.venue?.longitude ?? 0,
            startDate:     date,
            endDate:       date,        // single-day events: start == end
            status:        festivalStatus(for: date),
            isCamping:     false,
            genres:        ["Electronic"],
            imageColorHex: "4ECDC4",    // .appTeal default
            lineup:        [],
            sets:          [],
            source:        .edmTrain,
            eventURL:      row.link.flatMap { URL(string: $0) }
        )
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    private func parseDate(_ string: String) -> Date? {
        dateFormatter.date(from: String(string.prefix(10)))
    }

    private func festivalStatus(for date: Date) -> FestivalStatus {
        let now = Date()
        let cal = Calendar.current
        if cal.isDateInToday(date) { return .active }
        return date > now ? .upcoming : .past
    }

    private static func haversineKm(lat1: Double, lon1: Double,
                                    lat2: Double, lon2: Double) -> Double {
        let R  = 6371.0
        let φ1 = lat1 * .pi / 180
        let φ2 = lat2 * .pi / 180
        let Δφ = (lat2 - lat1) * .pi / 180
        let Δλ = (lon2 - lon1) * .pi / 180
        let a  = sin(Δφ/2) * sin(Δφ/2) + cos(φ1) * cos(φ2) * sin(Δλ/2) * sin(Δλ/2)
        return R * 2 * atan2(sqrt(a), sqrt(1-a))
    }
}
```

- [ ] **Step 3: Run `xcodegen generate`**

```bash
cd /Users/ethantillmon/Desktop/Encore && xcodegen generate
```

Expected output ends with: `✅  Created project at Encore.xcodeproj`

- [ ] **Step 4: Build**

`Cmd+B`. Expected: Build Succeeded. If there are type errors around the `Festival` init, verify that Task 1 added both `source` and `eventURL` fields with their defaults.

- [ ] **Step 5: Commit**

```bash
git add Encore/Services/EDMTrainService.swift
git commit -m "feat: add EDMTrainService with location mapping and event fetch"
```

---

## Task 4: Add `loadEDMTrainEvents` to `FestivalDiscoveryStore`

**Files:**
- Modify: `Encore/Stores/FestivalDiscoveryStore.swift`

- [ ] **Step 1: Add the method**

Inside `FestivalDiscoveryStore`, after the closing brace of `loadFestivals()`, add:

```swift
/// Fetches EDM Train events near the given coordinates and merges them into allFestivals.
/// Replaces any previously-loaded EDM Train events to avoid duplicates on refresh.
@MainActor
func loadEDMTrainEvents(latitude: Double, longitude: Double) async {
    let locationId = EDMTrainService.nearestLocationId(latitude: latitude, longitude: longitude)
    let events = (try? await EDMTrainService.shared.fetchEvents(locationId: locationId)) ?? []
    allFestivals = allFestivals.filter { $0.source == .supabase } + events
}
```

- [ ] **Step 2: Build**

`Cmd+B`. Expected: Build Succeeded.

- [ ] **Step 3: Commit**

```bash
git add Encore/Stores/FestivalDiscoveryStore.swift
git commit -m "feat: add loadEDMTrainEvents to FestivalDiscoveryStore"
```

---

## Task 5: Trigger EDM Train fetch from `FestivalListView`

**Files:**
- Modify: `Encore/Views/Discover/FestivalListView.swift`

- [ ] **Step 1: Add `.task(id:)` modifier**

In `FestivalListView.body`, add a `.task(id:)` modifier after the existing `.sheet` modifiers. The task re-runs whenever the selected festival's ID changes, and skips the fetch if no festival is selected or it has no coordinates (latitude/longitude == 0):

```swift
.sheet(isPresented: $showArtistSearch) {
    ArtistSearchView()
        .environmentObject(discoveryStore)
        .environmentObject(festivalStore)
        .environmentObject(journalStore)
        .environmentObject(scheduleStore)
        .environmentObject(crewStore)
}
.task(id: festivalStore.selectedFestival?.id) {
    guard let festival = festivalStore.selectedFestival,
          festival.latitude != 0 || festival.longitude != 0 else { return }
    await discoveryStore.loadEDMTrainEvents(
        latitude: festival.latitude,
        longitude: festival.longitude
    )
}
```

- [ ] **Step 2: Build**

`Cmd+B`. Expected: Build Succeeded.

- [ ] **Step 3: Verify in Simulator**

Run the app (`Cmd+R`) on an iPhone 16 Pro simulator. Navigate to the **Fests** tab. If a festival is selected in `FestivalStore` (one with real coordinates), EDM Train events should appear in the list alongside Supabase festivals. If the EDM Train location IDs in `EDMTrainService.metroLocations` are still `0` (placeholder), no events will appear — this is expected until Task 3 Step 1 is completed.

- [ ] **Step 4: Commit**

```bash
git add Encore/Views/Discover/FestivalListView.swift
git commit -m "feat: trigger EDM Train event fetch from FestivalListView on active festival change"
```

---

## Task 6: Add source badge to `FestivalCardView`

**Files:**
- Modify: `Encore/Views/Discover/FestivalCardView.swift`

- [ ] **Step 1: Add EDM Train badge**

In the `HStack` that contains the festival name, camping tent icon, and `statusBadge`, add a source badge that appears for `.edmTrain` festivals. Replace the existing name row:

```swift
HStack {
    Text(festival.name)
        .font(DS.Font.cardTitle)
        .foregroundColor(.appTextPrimary)
    Spacer()
    if festival.source == .edmTrain {
        Text("EDM Train")
            .font(DS.Font.caps)
            .foregroundColor(.appBackground)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Color.appTeal)
            .clipShape(Capsule())
    }
    if festival.isCamping {
        Image(systemName: "tent.fill")
            .font(.system(size: 11))
            .foregroundColor(accentColor.opacity(0.7))
    }
    statusBadge
}
```

- [ ] **Step 2: Update the Preview to include an EDM Train event**

Add a preview festival to visually verify the badge renders. At the bottom of `FestivalCardView.swift`, update the `#Preview`:

```swift
#Preview {
    let edmEvent = Festival(
        id: UUID(),
        name: "Disclosure",
        slug: "edmtrain-99999",
        location: "Los Angeles, CA",
        latitude: 34.0522,
        longitude: -118.2437,
        startDate: Date().addingTimeInterval(86400 * 7),
        endDate: Date().addingTimeInterval(86400 * 7),
        status: .upcoming,
        isCamping: false,
        genres: ["Electronic"],
        imageColorHex: "4ECDC4",
        lineup: [],
        sets: [],
        source: .edmTrain,
        eventURL: URL(string: "https://edmtrain.com")
    )
    return VStack(spacing: 12) {
        FestivalCardView(festival: Festival.mockFestivals[0])
        FestivalCardView(festival: Festival.mockFestivals[1])
        FestivalCardView(festival: edmEvent)
    }
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
```

- [ ] **Step 3: Verify Preview**

Open the Canvas in Xcode (`Option+Cmd+Enter`). The third card should show a teal "EDM Train" capsule badge in the top-right.

- [ ] **Step 4: Build**

`Cmd+B`. Expected: Build Succeeded.

- [ ] **Step 5: Commit**

```bash
git add Encore/Views/Discover/FestivalCardView.swift
git commit -m "feat: add EDM Train source badge to FestivalCardView"
```

---

## Task 7: Update `FestivalDetailView` for EDM Train events

**Files:**
- Modify: `Encore/Views/Discover/FestivalDetailView.swift`

- [ ] **Step 1: Add `@Environment(\.openURL)` and source badge in hero**

Add the `openURL` environment to the existing environment variables at the top of the struct, and update `festivalHero` to show the source badge:

```swift
// Add after the existing @EnvironmentObject lines:
@Environment(\.openURL) private var openURL
```

In `festivalHero`, add the source badge to the `HStack` that shows `statusPill` and the camping pill:

```swift
private var festivalHero: some View {
    VStack(alignment: .leading, spacing: DS.Spacing.sectionGap) {
        HStack(spacing: 8) {
            statusPill
            if festival.source == .edmTrain {
                Text("EDM Train")
                    .font(DS.Font.caps)
                    .foregroundColor(.appBackground)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color.appTeal)
                    .clipShape(Capsule())
            }
            if festival.isCamping {
                Label("Camping", systemImage: "tent.fill")
                    .font(DS.Font.caps)
                    .foregroundColor(.appTextMuted)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color.appSurface)
                    .clipShape(Capsule())
            }
            Spacer()
        }
        Text("\(dateRangeLabel)  ·  \(festival.location)")
            .font(DS.Font.listItem)
            .foregroundColor(.appTextMuted)
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(festival.genres, id: \.self) { genre in
                    Text(genre)
                        .font(DS.Font.caps)
                        .foregroundColor(accentColor)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(accentColor.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
    }
}
```

- [ ] **Step 2: Replace the CTA section with source-conditional logic**

The existing CTA block reads:
```swift
// "Set as active" CTA
if festival.status == .active || festival.status == .upcoming {
    setActiveCTA
}
```

Replace it with:
```swift
// CTA: EDM Train events get an external link; Supabase festivals get the "Set as my festival" button
if festival.source == .edmTrain {
    if let url = festival.eventURL {
        edmTrainCTA(url: url)
    }
} else if festival.status == .active || festival.status == .upcoming {
    setActiveCTA
}
```

- [ ] **Step 3: Add `edmTrainCTA` view builder**

Add this private view after the existing `setActiveCTA` computed property:

```swift
private func edmTrainCTA(url: URL) -> some View {
    Button(action: { openURL(url) }) {
        HStack {
            Image(systemName: "arrow.up.right.square")
            Text("View on EDM Train")
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.appTeal.opacity(0.15))
        .foregroundColor(Color.appTeal)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card)
            .stroke(Color.appTeal.opacity(0.3), lineWidth: 1))
    }
    .buttonStyle(.plain)
}
```

- [ ] **Step 4: Hide Travel Details row for EDM Train events**

The Travel Details button is currently unconditional. Wrap it in a source check:

```swift
// Travel details row — not applicable for single-night EDM Train events
if festival.source == .supabase {
    Button(action: { showTravelDetails = true }) {
        HStack {
            Label("Travel Details", systemImage: "suitcase")
                .font(DS.Font.listItem)
                .foregroundColor(.appTextPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(DS.Font.metadata)
                .foregroundColor(.appTextMuted)
        }
        .padding(DS.Spacing.cardPadding)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
    }
    .buttonStyle(.plain)
}
```

- [ ] **Step 5: Build**

`Cmd+B`. Expected: Build Succeeded.

- [ ] **Step 6: Verify in Preview and Simulator**

Add an EDM Train event to the `#Preview` at the bottom of `FestivalDetailView.swift` to verify the layout:

```swift
#Preview {
    let festivals = FestivalStore()
    festivals.festivals = Festival.mockFestivals
    festivals.selectedFestival = Festival.mockFestivals[1]
    let journal = JournalStore()
    journal.entries = JournalEntry.mockEntries

    let edmEvent = Festival(
        id: UUID(),
        name: "Disclosure",
        slug: "edmtrain-99999",
        location: "Los Angeles, CA",
        latitude: 34.0522,
        longitude: -118.2437,
        startDate: Date().addingTimeInterval(86400 * 7),
        endDate: Date().addingTimeInterval(86400 * 7),
        status: .upcoming,
        isCamping: false,
        genres: ["Electronic"],
        imageColorHex: "4ECDC4",
        lineup: [],
        sets: [],
        source: .edmTrain,
        eventURL: URL(string: "https://edmtrain.com/events/99999")
    )

    return NavigationStack {
        FestivalDetailView(festival: edmEvent)
            .environmentObject(festivals)
            .environmentObject(journal)
            .environmentObject(ScheduleStore())
            .environmentObject(CrewStore())
    }
    .preferredColorScheme(.dark)
}
```

In the Canvas, verify:
- "EDM Train" teal pill appears in the hero next to the status badge
- "View on EDM Train" teal button appears where "Set as my festival" would be
- Travel Details row is absent
- Lineup and History sections show their empty states without crashing

Run in simulator (`Cmd+R`) and tap an EDM Train event in the Fests tab. Verify "View on EDM Train" opens Safari to the EDM Train event page.

- [ ] **Step 7: Commit**

```bash
git add Encore/Views/Discover/FestivalDetailView.swift
git commit -m "feat: update FestivalDetailView for EDM Train events — source badge, external CTA, hide travel row"
```

---

## Task 8: Fill in real location IDs and end-to-end test

**Files:**
- Modify: `Encore/Services/EDMTrainService.swift`

- [ ] **Step 1: Fetch and fill in the real location IDs** (if not done in Task 3 Step 1)

```bash
curl -s "https://edmtrain.com/api/locations?client=b1b7e0c7-ac07-4885-a201-3a20f484d466" | python3 -m json.tool
```

Find the `id` values for each metro in `metroLocations` and replace all `0` placeholder IDs in `Encore/Services/EDMTrainService.swift`. Also update `defaultLocationId` — it derives from `metroLocations[0].id` automatically.

Also remove the guard at the top of `fetchEvents`:
```swift
// Remove this line once IDs are filled in:
guard locationId != 0 else { return [] }
```

- [ ] **Step 2: Build**

`Cmd+B`. Expected: Build Succeeded.

- [ ] **Step 3: End-to-end test in Simulator**

1. Run app (`Cmd+R`) on iPhone 16 Pro simulator
2. Navigate to **Fests** tab
3. Verify EDM Train events appear in the list with the teal "EDM Train" badge
4. Tap an EDM Train event — detail sheet opens, "View on EDM Train" button is visible
5. Tap "View on EDM Train" — Safari opens to the EDM Train event URL
6. Return to list, apply **Status: Upcoming** pill filter — EDM Train upcoming events remain visible, past events are filtered out
7. Apply **Region** filter matching the active festival's region — EDM Train events in other regions are filtered out

- [ ] **Step 4: Commit**

```bash
git add Encore/Services/EDMTrainService.swift
git commit -m "feat: fill in real EDM Train location IDs, enable live event fetch"
```

---

## Task 9: Update docs

**Files:**
- Modify: `docs/idea/encore-context.md`

- [ ] **Step 1: Update the "What's Real vs. Mocked" table**

In `docs/idea/encore-context.md`, find the `## What's Real vs. Mocked` table and add a new row:

```markdown
| EDM Train events | **Live** — `EDMTrainService.fetchEvents(locationId:)` fetched from active festival location; empty array on failure |
```

Also add `EDMTrainService.swift` to the Services section of the Project Structure code block:
```
├── Services/
│   ├── LineupService.swift      — Supabase actor; fetchFestivals, fetchAllFestivals, fetchLineup, scheduleSet stubs
│   └── EDMTrainService.swift    — EDM Train actor; nearestLocationId, fetchEvents, Haversine location mapping
```

- [ ] **Step 2: Commit**

```bash
git add docs/idea/encore-context.md
git commit -m "docs: update encore-context with EDM Train integration"
```
