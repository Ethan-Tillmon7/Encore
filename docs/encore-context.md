# Encore — App Context & Design Reference

> This document is the canonical reference for understanding Encore's current state, architecture, and design language. Use it when planning new features, views, or systems.

---

## What Encore Is

A festival companion app for iOS, targeting Bonnaroo. It helps attendees:
1. **Discover** the lineup and build a personal schedule
2. **Coordinate** with their friend group (crew)
3. **Navigate** the venue to stages and amenities
4. **Manage** trip logistics (travel, packing, expenses — planned)

The app is fully functional on mock data. No backend or real accounts exist yet.

---

## Project Structure

```
Encore/
├── App/
│   ├── EncoreApp.swift          — App entry point; instantiates stores, handles theme
│   └── RootView.swift           — 2-tab TabView (Home, Profile)
│
├── DesignSystem/
│   ├── DesignSystem.swift       — DS.Spacing / DS.RowHeight / DS.Radius / DS.Font constants
│   └── AppColors.swift          — Color token extensions (appBackground, appSurface, etc.)
│
├── Models/
│   ├── Artist.swift             — Artist struct + MatchTier enum
│   ├── FestivalSet.swift        — FestivalSet, FestivalDay, SetConflict
│   ├── Crew.swift               — Crew, CrewMember, MeetupPin + Color(hex:) extension
│   └── MockData.swift           — 12 artists, 10 sets, 4 crew members (all Bonnaroo-themed)
│
├── Stores/
│   ├── ScheduleStore.swift      — User's personal schedule + conflict detection
│   ├── LineupStore.swift        — Full lineup, filters, Spotify connection state
│   └── CrewStore.swift          — Crew membership, meetup pins, merged timeline helpers
│
└── Views/
    ├── Home/
    │   └── HomeView.swift       — Festival hub (group, trip, schedule, lineup entry)
    ├── Lineup/
    │   ├── LineupView.swift     — Day picker + timetable grid shell
    │   ├── TimetableGridView.swift — 2-axis scrollable timetable grid
    │   └── SetBlockView.swift   — Individual set block rendered inside the grid
    ├── Artist/
    │   ├── ArtistCardView.swift — List-item card (add/remove, tier bar, crew indicator)
    │   └── ArtistDetailView.swift — Full artist detail sheet (set info, crew, setlist, CTA)
    ├── Schedule/
    │   └── ConflictResolverView.swift — Side-by-side conflict resolver modal
    ├── Map/
    │   └── FestivalMapView.swift — MapKit map with stage and amenity markers
    └── Profile/
        └── ProfileView.swift    — Settings: theme, notifications, legal, sign out
```

**Build system:** XcodeGen (`project.yml` → `Encore.xcodeproj`). Run `xcodegen generate` after any structural change to `project.yml` or the file tree.

---

## Navigation Architecture

```
RootView (TabView)
├── Tab: Home (house)
│   └── HomeView (NavigationStack)
│       ├── → LineupView (push via navigationPath.append("lineup"))
│       │   └── TimetableGridView
│       │       ├── → ArtistDetailView (sheet on set tap)
│       │       │   └── → FestivalMapView (push via NavigationLink "Directions to Stage")
│       │       └── → FestivalMapView (push on stage header tap)
│       ├── ↑ ArtistDetailView (sheet from schedule row tap)
│       └── ↑ ConflictResolverView (sheet from conflict banner tap)
└── Tab: Profile (person.circle)
    └── ProfileView
```

Key patterns:
- `HomeView` owns a `NavigationStack` with `NavigationPath`. All push navigation for the Home flow goes through it.
- Modal content (artist details, conflict resolver) uses `.sheet(item:)`.
- `FestivalMapView` is always pushed (never presented as a sheet) and accepts `initialStage: String?` to auto-center on a stage.
- `ArtistDetailView` is a sheet and wraps its own `NavigationView` to support the Directions → Map push internally.

---

## Screens

### HomeView — Festival Hub
**One job:** Show the user their full festival context at a glance.

Sections (scrollable, no sticky headers):
| Section | Content |
|---------|---------|
| Festival Header | "Bonnaroo '25" + dates/location |
| Group Card | Crew name, member bubbles with online indicators, "+ Invite" button |
| Trip Card | 3 columns: Travel / Packing / Expenses (each tappable, sheets are stubs) |
| Browse Lineup | Full-width row → pushes LineupView |
| My Schedule | Day picker (Thu–Sun) + list of user's sets for selected day; conflict banner if applicable |

Empty state for schedule: shown when no sets are added for the selected day.

---

### LineupView — Full Timetable
**One job:** Browse all artists and add sets to your schedule.

- Day picker controls which day's sets appear in `TimetableGridView`
- `TimetableGridView` is a `ScrollView([.horizontal, .vertical])` with a `ZStack` of absolutely positioned `SetBlockView` elements — NOT a `LazyVGrid`
- Block position = offset from day start in 30-min increments (44pt per row)
- Block height = duration in minutes / 30 × 44pt
- Tapping a stage header in the grid → pushes `FestivalMapView` for that stage
- Tapping a set block → presents `ArtistDetailView` as a sheet

---

### ArtistDetailView — Artist Detail
**One job:** See full detail for an artist and decide whether to add them.

Presented as a sheet from both HomeView (schedule row tap) and LineupView (set block tap).

Sections:
- Hero: tier badge, genres, Spotify match or "sounds like" fallback
- Set Info: Stage / Day / Time (3-cell grid)
- Your Crew: attendees from CrewStore (shown only if any)
- Recent Setlist: 7 hardcoded placeholder songs (setlist.fm integration is Phase 1)
- Bottom actions (safeAreaInset): "Add to My Schedule" / "Added to Schedule" + "Directions to [Stage]"

---

### ArtistCardView — List Item
**One job:** Compact artist card for list-based browse views (e.g. a future Discover tab or search results).

Not currently used in any screen — `DiscoverView` was removed in the redesign. The card exists for Phase 1 Discover/search use.

---

### ConflictResolverView — Conflict Resolution
**One job:** Help the user choose between two overlapping sets.

Presented as `.sheet` with `.presentationDetents([.medium])`. Shows side-by-side cards for the two conflicting sets with Keep A / Keep B / Decide Later actions.

---

### FestivalMapView — Venue Map
**One job:** Navigate to a stage or find amenities.

Always pushed (never a sheet). Accepts `initialStage: String?` — on `onAppear`, finds the matching `StageAnnotation` and centers the map on it.

- 5 stages: What, Which, This Tent, That Tent, Other Stage
- 3 amenity types: Water, Medical, Charging (hidden by default, toggle in toolbar)
- Stage info card slides up when a marker is tapped (shows current act, next act, walk time)
- Location sharing toggle in toolbar (currently a stub)

---

### ProfileView — Settings
**One job:** Account settings and preferences.

Sections: Profile header | Account (Edit Profile) | Preferences (Theme + Notifications) | Legal & Support | Sign Out

Theme picker writes to `@AppStorage("appTheme")` which is read in `EncoreApp` and passed as `preferredColorScheme` to the root `WindowGroup`.

---

## Data Models

### Artist
```swift
struct Artist {
    id: UUID
    name: String
    genres: [String]
    spotifyMatchScore: Int?         // 0–100; nil if Spotify not connected
    playCountLastSixMonths: Int?
    matchTier: MatchTier            // mustSee | worthChecking | explore | unknown
    soundsLike: [String]            // fallback display when no Spotify data
    stageName: String               // primary stage
    isHeadliner: Bool
    var spotifyLabel: String?       // computed: "X% match · Y plays last 6 mo"
}
```

### MatchTier
```swift
enum MatchTier: String {
    case mustSee       = "Must-see"
    case worthChecking = "Worth checking out"
    case explore       = "Explore"
    case unknown       = "Unknown"
}
```
Color mapping:
| Tier | `.color` | Usage |
|------|----------|-------|
| mustSee | `.appCTA` | Badges, set blocks, tier bars |
| worthChecking | `.appAccent` | Same |
| explore | `.appTeal` | Same |
| unknown | `.appTextMuted` | Same |

Additional computed colors: `.backgroundColor` = `color.opacity(0.18)`, `.blockFill` = `color.opacity(0.18)`, `.blockBorder` = `color.opacity(0.32)`.

### FestivalSet
```swift
struct FestivalSet {
    id: UUID
    artist: Artist
    stageName: String
    day: FestivalDay                // .thursday | .friday | .saturday | .sunday
    startTime: Date
    endTime: Date
    var durationMinutes: Int        // computed
    var timeRangeLabel: String      // "h:mm a – h:mm a"
    func overlaps(with other: FestivalSet) -> Bool
}
```

### SetConflict
```swift
struct SetConflict: Identifiable {
    setA: FestivalSet
    setB: FestivalSet
    var overlapMinutes: Int         // computed from time intersection
}
```

### Crew / CrewMember / MeetupPin
```swift
struct CrewMember {
    id: UUID
    name: String
    colorHex: String                // personal avatar color
    scheduledSetIDs: [UUID]         // which sets this member added
    isOnline: Bool
    lastSeenStage: String?          // "What Stage · 4 min ago"
    var color: Color                // computed from colorHex
    var initials: String            // max 2 chars
}

struct Crew {
    id: UUID
    name: String
    inviteCode: String              // 6-char alphanumeric
    members: [CrewMember]
}

struct MeetupPin {
    id: UUID
    label: String
    latitude, longitude: Double
    createdBy: UUID                 // CrewMember.id
}
```

---

## Store Architecture

All stores are `@ObservableObject` with `@Published` state. Instantiated in `EncoreApp` as `@StateObject` and injected via `.environmentObject()` at the root — available to any view without prop drilling.

### ScheduleStore
Owns the user's personal schedule.
```
scheduledSets: [FestivalSet]          // in-memory only, no persistence yet
add/remove/toggle(set:)
isScheduled(set:) → Bool
sets(for day:) → [FestivalSet]        // filtered + sorted by start time
conflicts: [SetConflict]              // all overlapping pairs
hasConflicts: Bool
resolveConflict(_:keep:)              // removes the non-kept set
```

### LineupStore
Owns the full festival lineup and filter state.
```
allSets: [FestivalSet]                // initialized from FestivalSet.mockSets
selectedDay: FestivalDay?
selectedTier: MatchTier?
searchText: String
isSpotifyConnected: Bool
filteredSets: [FestivalSet]           // computed: apply filters, sort by Spotify score
connectSpotify()                      // TODO: OAuth (Phase 1)
disconnectSpotify()                   // clears scores, resets tiers to .unknown
```

### CrewStore
Owns crew membership and meetup pins.
```
crew: Crew?                           // nil until user creates or joins
meetupPins: [MeetupPin]
isLocationSharingEnabled: Bool
createCrew(name:)
joinCrew(code:)                       // TODO: Supabase fetch (Phase 1)
leaveCrew()
dropPin/removePin
mergedSets(allSets:) → [FestivalSet]  // all sets across crew members, deduplicated
attendees(for set:) → [CrewMember]    // which members are seeing this set
```

---

## Design System

All values live in `DesignSystem.swift` under the `DS` namespace.

### Spacing
| Token | Value | Usage |
|-------|-------|-------|
| `DS.Spacing.pageMargin` | 16pt | Horizontal edge padding on all screens |
| `DS.Spacing.cardGap` | 12pt | Vertical gap between cards |
| `DS.Spacing.cardPadding` | 16pt | Inner padding of surface cards |
| `DS.Spacing.sectionGap` | 8pt | Gap between a section label and its content |

### Row Heights
| Token | Value | Usage |
|-------|-------|-------|
| `DS.RowHeight.schedule` | 60pt | minHeight on schedule rows in HomeView |
| `DS.RowHeight.dayPicker` | 44pt | Height of day picker pill buttons |

### Corner Radii
| Token | Value | Usage |
|-------|-------|-------|
| `DS.Radius.card` | 16pt | Surface cards, ArtistDetailView sections |
| `DS.Radius.chip` | 10pt | Small pill buttons, schedule rows, conflict banner |
| `DS.Radius.pill` | 99pt | Capsule/pill shapes (use `.clipShape(Capsule())` instead) |

### Typography
| Token | Size | Weight | Usage |
|-------|------|--------|-------|
| `DS.Font.hero` | 28pt | Black | Festival title in HomeView header |
| `DS.Font.cardTitle` | 16pt | Bold | Card titles, section headers, action buttons |
| `DS.Font.listItem` | 14pt | Semibold | Artist names, row labels, body text |
| `DS.Font.metadata` | 12pt | Regular | Stage names, timestamps, secondary info |
| `DS.Font.label` | 11pt | Bold | Caps labels, crew member names |
| `DS.Font.caps` | 10pt | Bold | Section labels (e.g. "MY SCHEDULE", "FESTIVAL GROUP") |

---

## Color Tokens

Defined in `AppColors.swift` as `Color` extensions backed by adaptive `UIColor`.

| Token | Dark | Light | Usage |
|-------|------|-------|-------|
| `.appBackground` | `#1C2522` | `#FAFDE6` | Screen backgrounds |
| `.appSurface` | `#2A332F` | `#FFFFF0` | Card backgrounds, inputs |
| `.appAccent` | `#A8BFB2` | `#A8BFB2` | Borders, icons, secondary elements |
| `.appCTA` | `#E8F7D0` | `#E8F7D0` | Primary actions, mustSee tier, tab tint |
| `.appTeal` | `#D4ECEC` | `#D4ECEC` | Explore tier, amenity markers |
| `.appTextPrimary` | `#EAEAEF` | `#202030` | Main text |
| `.appTextMuted` | `#A8BFB2` | `#A8BFB2` | Secondary text, placeholders |

---

## Technical Constraints

| Constraint | Detail |
|------------|--------|
| **iOS 16 target** | Use `@ObservableObject`/`@Published` (not iOS 17 `@Observable`). Use `Map(coordinateRegion:)` (not the iOS 17 Map API). Do not add iOS 17+ APIs without bumping deployment target in `project.yml`. |
| **No persistence** | `scheduledSets` is in-memory only. Resets on app launch. UserDefaults or SQLite is Phase 1. |
| **No backend** | `connectSpotify()` and `joinCrew(code:)` are stubs. Do not add real network calls without wiring up backend infrastructure first. |
| **No SPM packages** | `project.yml` has Supabase commented out. Add packages via YAML, not Xcode's UI. |
| **XcodeGen managed** | `.xcodeproj` is generated. Never edit it directly. Run `xcodegen generate` after any change to `project.yml` or the source file tree. |
| **Theme, not forced dark** | `EncoreApp` reads `@AppStorage("appTheme")` (system/light/dark) and passes the result as `preferredColorScheme` to the root `WindowGroup`. All colors must use adaptive tokens — do not hardcode dark-only values. |
| **SF Symbols only** | No emoji in UI per `UI-UX.txt`. Use SF Symbols for all icons. |
| **44pt tap targets** | All interactive elements must meet the minimum 44×44pt tap target. |

---

## What's Real vs. Mocked

| Feature | Current State |
|---------|--------------|
| Lineup data | `MockData.swift` — 12 artists, 10 sets |
| Crew members | `MockData.swift` — 4 members ("Bonnaroo Squad") |
| Stage map | Hardcoded `StageAnnotation` array in `FestivalMapView.swift` |
| Recent setlist | 7 hardcoded songs in `ArtistDetailView.swift` |
| Walk time to stage | Hardcoded "~8 min walk" in `FestivalMapView` |
| Spotify match scores | Hardcoded on artists in `MockData.swift` |
| Trip details (Travel/Packing/Expenses) | UI-only stubs; tapping opens nothing |
| Crew invite | "+ Invite" button is a stub (no action) |
| Edit Profile | Button stub (no action) |
| Notifications setting | Label only, no action |
| Location sharing | Toggle wired to `CrewStore.isLocationSharingEnabled` but no CoreLocation |
| Schedule persistence | In-memory only; cleared on launch |

---

## Phase Roadmap

### Phase 1 — Real Data (local device)
- Spotify OAuth via `ASWebAuthenticationSession` → populate `spotifyMatchScore` and `playCountLastSixMonths` on artists
- Real Bonnaroo lineup via Supabase or scraping → replace `MockData.mockSets`
- Persist `scheduledSets` to UserDefaults or SQLite
- Real setlist.fm API integration → replace hardcoded songs in `ArtistDetailView`
- Offline map tile caching (MapKit tile overlay or custom)
- Trip detail sheets (Travel, Packing, Expenses) with local storage

### Phase 2 — Realtime & Social
- `CrewStore` → Supabase Realtime: live schedule sync across crew members
- CoreLocation + Supabase presence: live location sharing on map
- QR code crew invite flow
- Group chat via Supabase Realtime channels
- Push notifications for upcoming set reminders

### Phase 3 — Personalization
- Recommendation engine based on Spotify listening history
- Cross-festival support (multi-festival data model)
- Social discovery (see what friends outside your crew are watching)

---

## Key Design Principles (from UI-UX.txt)

- **One job per screen** — each screen has a single dominant purpose
- **One dominant action** — the primary CTA is always clear
- **Content over chrome** — minimize structural UI; maximize content density
- **No emojis** — SF Symbols only
- **44pt minimum tap targets** on all interactive elements
- **Dark mode first** — all colors use adaptive tokens; the app looks right in dark mode by default
