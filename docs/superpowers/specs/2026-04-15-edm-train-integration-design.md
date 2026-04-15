# EDM Train Integration — Design Spec
**Date:** 2026-04-15  
**Branch:** `edm-train-integration`  
**Status:** Approved

---

## Overview

Integrate the EDM Train API to surface upcoming electronic music events alongside Supabase-sourced festivals in the existing Fests tab (`FestivalListView`). Users discover EDM Train events the same way they discover festivals — through filters, search, and card browsing — with a source badge differentiating them. Tapping an EDM Train event opens an in-app detail sheet with a "View on EDM Train" link (required by API ToS).

---

## Scope

**In scope:**
- New `EDMTrainService` actor
- `FestivalSource` enum + `source` and `eventURL` fields on `Festival`
- `FestivalDiscoveryStore` fetching EDM Train events concurrently with Supabase
- Location mapping from active festival coordinates → EDM Train location ID
- `FestivalCardView` source badge
- `FestivalDetailView` conditional rendering for EDM Train events
- `APIKeys` addition

**Out of scope:**
- GPS / CoreLocation-based location detection (future)
- EDM Train lineup/set data (events have `lineup: []`, `sets: []`)
- Schedule/travel features for EDM Train events
- EDM Train events as selectable "active festival" context

---

## Data Layer

### `FestivalSource`
New enum added to `Encore/Models/Festival.swift`:

```swift
enum FestivalSource: String, Codable {
    case supabase
    case edmTrain
}
```

### `Festival` model changes
Two new fields added to `Festival`:

```swift
var source: FestivalSource = .supabase   // default preserves all existing init sites
var eventURL: URL?                        // non-nil only for .edmTrain events; ToS link
```

Both fields are backwards-compatible:
- `source` has a default value — all existing `Festival` initialisers require no changes
- `eventURL` is optional — `Codable` decodes missing field as `nil`

### `EDMTrainService`
New Swift `actor` at `Encore/Services/EDMTrainService.swift`. Mirrors the pattern of `LineupService`.

```swift
actor EDMTrainService {
    static let shared = EDMTrainService()

    func fetchEvents(locationId: Int) async throws -> [Festival]

    static func nearestLocationId(latitude: Double, longitude: Double) -> Int
}
```

**`fetchEvents(locationId:)`**
- URL: `https://edmtrain.com/api/events?locationIds=\(locationId)&client=\(APIKeys.edmTrain)`
- Decodes JSON response into private `EDMTrainEventRow` DTOs
- Maps each event → `Festival` with `source: .edmTrain`, `eventURL` set from the event link in the response
- Field mapping:

| EDM Train field | `Festival` field | Fallback |
|----------------|------------------|----------|
| `name` or artist name | `name` | `"Unknown Event"` |
| venue city + state | `location` | `""` |
| venue latitude | `latitude` | active festival lat |
| venue longitude | `longitude` | active festival lon |
| event date | `startDate` / `endDate` | `Date()` |
| computed from date | `status` | `.upcoming` |
| artist genres | `genres` | `["Electronic"]` |
| `false` | `isCamping` | — |
| default `"4ECDC4"` | `imageColorHex` | — |
| `[]` | `lineup`, `sets` | — |
| event link | `eventURL` | — |

**`nearestLocationId(latitude:longitude:)`**
- Static method — no async needed
- Contains a hardcoded `[String: (lat: Double, lon: Double, id: Int)]` dictionary of major EDM metro areas
- Uses Haversine distance to find the closest metro center
- Returns that metro's EDM Train location ID
- If coordinates are `(0, 0)` (the `Festival` default when Supabase omits lat/lon), returns the Los Angeles location ID as a safe default rather than matching a random metro
- Initial metro coverage (expandable): Los Angeles, San Francisco, New York, Chicago, Miami, Las Vegas, Denver, Seattle, Austin, Atlanta, Nashville, New Orleans

### `APIKeys` addition
```swift
static let edmTrain = "b1b7e0c7-ac07-4885-a201-3a20f484d466"
```

---

## Store Integration

### `FestivalDiscoveryStore`
Two changes:

1. **Concurrent fetch on init** — `loadEDMTrainEvents()` fires concurrently with the existing Supabase fetch inside `loadFestivals()`. The existing `Task { await loadFestivals() }` in `init` is replaced with a task that runs both fetches concurrently using `async let`:

```swift
async let supabaseLoad: Void = loadSupabaseFestivals()   // renamed from loadFestivals()
async let edmLoad: Void = loadEDMTrainEvents()
_ = await (supabaseLoad, edmLoad)
```

The existing `loadFestivals()` body is extracted into a private `loadSupabaseFestivals()` method so the two fetches can run independently and both contribute to `allFestivals`.

2. **New private method:**

```swift
private func loadEDMTrainEvents() async {
    guard let festival = festivalStore.selectedFestival else { return }
    let locationId = EDMTrainService.nearestLocationId(
        latitude: festival.latitude,
        longitude: festival.longitude
    )
    let events = (try? await EDMTrainService.shared.fetchEvents(locationId: locationId)) ?? []
    await MainActor.run { self.allFestivals += events }
}
```

Failures fall back silently (same pattern as Supabase → MockData fallback). If no festival is selected, EDM Train fetch is skipped.

### Filter compatibility
All existing filters work without modification:

| Filter | EDM Train behavior |
|--------|-------------------|
| `selectedStatus` | Computed from `startDate`/`endDate` — same logic |
| `searchText` | Matches on `festival.name` |
| `campingFilter` | `isCamping: false` — shows under "Any" and "No Camping" only |
| `selectedGenres` | Matches `["Electronic"]` or actual artist genres |
| `regionFilter` | Computed from `latitude`/`longitude` — same logic |

No changes to `filteredFestivals` computed property or `DiscoveryFilterSheet`.

---

## UI Changes

### `FestivalCardView`
When `festival.source == .edmTrain`, a small pill badge reading "EDM Train" is shown in the top-right corner of the card:
- Color: `.appTeal` background, `.appBackground` text
- Typography: `DS.Font.caps`
- Corner radius: `DS.Radius.pill`
- No other card layout changes

### `FestivalDetailView`
Conditionals based on `festival.source`:

**Hidden for `.edmTrain`:**
- "Set as my festival" CTA
- Travel Details row

**Shown for `.edmTrain`:**
- "View on EDM Train" full-width button in place of the "Set as my festival" CTA
  - Opens `festival.eventURL` via SwiftUI `openURL` environment
  - Uses `.appCTA` tint, same button style as existing CTAs
- Source badge ("EDM Train" pill) in the hero section alongside the status pill

**Unchanged for `.edmTrain`:**
- Artist chip scroll (renders empty — `lineup: []`)
- Genre chips
- Your History section (renders empty — no journal entries)
- Status pill, date/location header

---

## Error Handling

- Network failure → silent fallback, no EDM Train events shown (consistent with existing Supabase failure behavior)
- No selected festival → EDM Train fetch skipped, no events shown
- Malformed JSON → individual events skipped via `compactMap`, others still shown
- Missing `eventURL` → "View on EDM Train" button is hidden

---

## API Terms of Use Compliance

- Every EDM Train event card links to the EDM Train event URL via the detail sheet "View on EDM Train" button
- `eventURL` is populated from the `link` field in the API response for every event
- The source badge ("EDM Train") on cards and detail views provides visible attribution

---

## Files Changed

| File | Change |
|------|--------|
| `Encore/Models/Festival.swift` | Add `FestivalSource` enum, `source` and `eventURL` fields |
| `Encore/Services/EDMTrainService.swift` | New file — actor, DTOs, location mapping |
| `Encore/Stores/FestivalDiscoveryStore.swift` | Concurrent EDM Train fetch on init |
| `Encore/Utilities/APIKeys.swift` | Add `edmTrain` key |
| `Encore/Views/Discover/FestivalCardView.swift` | Source badge |
| `Encore/Views/Discover/FestivalDetailView.swift` | Conditional CTA, source badge, hide Travel row |
| `project.yml` | No manual changes needed — XcodeGen's sources glob for `Encore/Services/` will auto-include the new file |
