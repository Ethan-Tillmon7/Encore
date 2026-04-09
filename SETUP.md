# Encore — iOS App Setup

## Prerequisites

- macOS with Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) installed

```bash
brew install xcodegen
```

## First-time Setup

1. **Generate the Xcode project**

```bash
cd Encore/
xcodegen generate
```

This creates `Encore.xcodeproj` from `project.yml`.

2. **Open in Xcode**

```bash
open Encore.xcodeproj
```

3. **Set your signing team**

In Xcode: Select the `Encore` target → Signing & Capabilities → Team.

(Or add `DEVELOPMENT_TEAM: YOUR_TEAM_ID` in `project.yml` and re-run `xcodegen generate`.)

4. **Run on the simulator**

Select an iPhone simulator and press `Cmd + R`. The app will launch with mock Bonnaroo lineup data.

---

## Project Structure

```
Encore/
├── project.yml                      ← XcodeGen config
└── Encore/
    ├── EncoreApp.swift              ← App entry point, injects all stores
    ├── Info.plist                   ← Permissions (location, Spotify OAuth URL scheme)
    │
    ├── Models/
    │   ├── Artist.swift             ← Artist, MatchTier
    │   ├── FestivalSet.swift        ← FestivalSet, FestivalDay, SetConflict
    │   ├── Crew.swift               ← Crew, CrewMember, MeetupPin
    │   └── MockData.swift           ← Dev/preview data (12 artists, 10 sets, 4 crew members)
    │
    ├── Stores/
    │   ├── ScheduleStore.swift      ← Add/remove sets, conflict detection
    │   ├── DiscoverStore.swift      ← Lineup + filters + Spotify connection
    │   └── CrewStore.swift          ← Crew management, meetup pins
    │
    └── Views/
        ├── MainTabView.swift
        ├── Discover/
        │   ├── DiscoverView.swift   ← Ranked artist list + filters + Spotify banner
        │   ├── ArtistCardView.swift ← Individual artist card with add button
        │   └── ArtistDetailView.swift ← Full artist detail sheet
        ├── Schedule/
        │   ├── MyScheduleView.swift       ← Day-picker timeline with conflict alerts
        │   └── ConflictResolverView.swift ← Side-by-side conflict resolution sheet
        ├── Crew/
        │   └── CrewView.swift       ← Member bubbles + merged timeline + create/join flows
        └── Map/
            └── FestivalMapView.swift ← MapKit map with stage markers + amenity layer
```

---

## What's Built vs. What's Next

### Built (scaffold)
- All 4 tabs with real UI and mock data
- Full Discover tab: filter by day/tier, search, Spotify banner, artist detail sheet
- Full Schedule tab: day-picker timeline, conflict detection, conflict resolver sheet
- Crew tab: create/join flows, member presence bubbles, merged timeline view
- Map tab: MapKit with Bonnaroo stage markers, amenity toggle, stage info card

### Next steps (Phase 1)
- [ ] Implement Spotify OAuth via `ASWebAuthenticationSession`
- [ ] Fetch real Bonnaroo lineup (scrape or partner API → store in Supabase)
- [ ] Persist `scheduledSets` to local storage (UserDefaults or SQLite)
- [ ] Replace mock `setlist.fm` data with real API calls
- [ ] Add offline map tile caching via MapKit local overlays

### Next steps (Phase 2)
- [ ] Wire `CrewStore` to Supabase Realtime for live schedule sync
- [ ] Implement location sharing with `CoreLocation` + Supabase presence
- [ ] QR code invite flow
- [ ] Group chat (Supabase Realtime channels)

---

## Key Design Decisions

**Dark mode forced** — `EncoreApp.swift` sets `.preferredColorScheme(.dark)`. Festival apps are used at night.

**Offline-first** — Add persistence layer before Phase 2. Bonnaroo cell service is poor; schedules must survive airplane mode.

**iOS 16 target** — Uses `@ObservableObject` (not `@Observable`), `Map(coordinateRegion:)` (not iOS 17 Map API). Change to iOS 17 when ready to drop iOS 16 support.

**Stores as `@EnvironmentObject`** — All three stores are injected at the root so any view can access them without prop drilling.
