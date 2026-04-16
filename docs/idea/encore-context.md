# Encore — App Context & Design Reference

> This document is the canonical reference for understanding Encore's current state, architecture, and design language. Use it when planning new features, views, or systems.
>
> **See also:** `docs/ux-roadmap.md` — living to-do list of UX gaps, new views to build, nav architecture decisions, and phased roadmap.

---

## What Encore Is

A multi-festival companion app for iOS. It helps attendees:
1. **Discover** festivals and build a personal schedule
2. **Coordinate** with their friend group (crew)
3. **Log** the artists they've seen (journal)
4. **Manage** trip logistics (travel, packing, expenses)

The app fetches live data from Supabase (festivals + lineup) and setlist.fm, with mock data fallback. No user accounts yet.

---

## Project Structure

```
Encore/
├── App/
│   ├── EncoreApp.swift          — App entry point; stores, theme, onboarding gate
│   └── RootView.swift           — 5-tab TabView (Journal · Crew · Home · Fests · Profile)
│
├── DesignSystem/
│   ├── DesignSystem.swift       — DS.Spacing / DS.RowHeight / DS.Radius / DS.Font / DS.WalkSeverity / DS.Journal
│   └── AppColors.swift          — Adaptive UIColor + SwiftUI Color token extensions
│
├── Models/
│   ├── Artist.swift             — Artist, MatchTier
│   ├── FestivalSet.swift        — FestivalSet, FestivalDay, SetConflict
│   ├── Festival.swift           — Festival, FestivalStatus, RegionFilter (slug, lat/lon, isCamping, region computed)
│   ├── GenreTaxonomy.swift      — GenreCategory, GenreTaxonomy (10 top-level buckets + subcategories)
│   ├── JournalEntry.swift       — JournalEntry, WouldSeeAgain
│   ├── TravelDetails.swift      — TravelDetails, PackingItem (+ category), ExpenseItem (+ paidBy, date)
│   ├── StageWalkTime.swift      — Static walk-time lookup for Bonnaroo stage pairs
│   ├── Crew.swift               — Crew, CrewMember (MeetupPin retained for Phase 2 map)
│   └── MockData.swift           — 9 mock festivals (3 Bonnaroo + 6 real), 12 artists, 10 sets, 4 crew, 3 journal entries
│
├── Services/
│   ├── LineupService.swift      — Supabase actor; fetchFestivals, fetchAllFestivals, fetchLineup, scheduleSet stubs
│   └── EDMTrainService.swift    — EDM Train actor; nearestLocationId (Haversine), fetchEvents, maps events to Festival
│
├── Stores/
│   ├── ScheduleStore.swift      — User schedule, conflict detection, walk-time warnings, UserDefaults persistence
│   ├── LineupStore.swift        — Lineup (loaded via Supabase), filters, Spotify connection state
│   ├── CrewStore.swift          — Crew membership, merged timeline helpers
│   ├── FestivalStore.swift      — Active festival context, travel details, UserDefaults persistence
│   ├── FestivalDiscoveryStore.swift — Full festival catalog, all discovery filters (status/text/artist/genre/camping/region)
│   ├── JournalStore.swift       — Journal entries, UserDefaults persistence
│   └── NotificationScheduler.swift — UNUserNotificationCenter set-reminder helpers
│
├── Utilities/
│   ├── SetlistService.swift     — setlist.fm actor; MusicBrainz MBID lookup + setlist fetch, in-memory cache
│   ├── StorageKey.swift         — Typed UserDefaults key constants
│   └── APIKeys.swift            — Supabase URL/anon key + setlist.fm key (GITIGNORED)
│
└── Views/
    ├── Home/
    │   └── HomeView.swift
    ├── Discover/
    │   ├── FestivalListView.swift
    │   ├── FestivalCardView.swift
    │   ├── FestivalDetailView.swift
    │   ├── ArtistSearchView.swift
    │   └── DiscoveryFilterSheet.swift  — artist name + camping + region + genre filter sheet
    ├── Lineup/
    │   ├── LineupView.swift
    │   ├── TimetableGridView.swift
    │   ├── SetBlockView.swift
    │   └── GroupPlannerView.swift
    ├── Journal/
    │   ├── SeenTrackerView.swift
    │   ├── ArtistGridCell.swift        — private subview inside SeenTrackerView
    │   ├── QuickLogView.swift          — two-step festival → artist picker sheet
    │   ├── JournalEntryRowView.swift
    │   ├── SetJournalEntryView.swift
    │   ├── ArtistHistoryView.swift
    │   └── RatePastSetsView.swift
    ├── Artist/
    │   ├── ArtistCardView.swift
    │   ├── ArtistDetailView.swift
    │   └── ArtistProfileView.swift     — lightweight sheet for artists without confirmed set times
    ├── Schedule/
    │   ├── ConflictResolverView.swift
    │   └── WalkTimeView.swift
    ├── Onboarding/
    │   └── OnboardingView.swift
    ├── Crew/
    │   └── CrewTabView.swift
    ├── Profile/
    │   ├── ProfileView.swift
    │   ├── EditProfileView.swift
    │   ├── NotificationsView.swift
    │   ├── TravelDetailsView.swift
    │   ├── CrewManageView.swift
    │   └── CrewInviteView.swift
    └── Components/
        └── CrewAvatarBubble.swift
```

**Build system:** XcodeGen (`project.yml` → `Encore.xcodeproj`). Run `xcodegen generate` after any structural change to `project.yml` or the file tree. The sources entry excludes `supabase/**` and `*.ts` so Supabase Edge Function files in `Encore/supabase/` are not bundled into the iOS app.

---

## Navigation Architecture

```
EncoreApp
├── .fullScreenCover  →  OnboardingView  (shown when hasCompletedOnboarding == false)
│
└── RootView (TabView, 5 tabs, .tint(.appCTA))
    ├── Tab: Journal (book.fill)
    │   └── NavigationStack → SeenTrackerView
    │       ├── → ArtistHistoryView (NavigationLink on entry tap)
    │       ├── ↑ SetJournalEntryView (sheet, tap artist grid cell → edit mode)
    │       ├── ↑ QuickLogView (sheet, "Log a Set" toolbar button → two-step picker)
    │       └── ↑ SetJournalEntryView (sheet, after QuickLogView artist selection → create mode)
    │
    ├── Tab: Crew (person.2.fill)
    │   └── NavigationStack → CrewTabView → CrewManageView
    │       └── ↑ CrewInviteView (sheet, toolbar)
    │
    ├── Tab: Home (house.fill)
    │   └── NavigationStack → HomeView
    │       ├── ↑ TravelDetailsView (sheet)
    │       └── ↑ CrewInviteView (sheet)
    │
    ├── Tab: Fests (sparkles)
    │   └── NavigationStack → FestivalListView
    │       ├── → FestivalDetailView (NavigationLink)
    │       │   └── ↑ TravelDetailsView (sheet)
    │       ├── ↑ ArtistSearchView (sheet, toolbar magnifying glass)
    │       │   └── ↑ ArtistDetailView (sheet on artist tap)
    │       └── ↑ DiscoveryFilterSheet (sheet, toolbar filter button)
    │
    └── Tab: Profile (person.circle.fill)
        └── NavigationStack → ProfileView
            ├── ↑ EditProfileView (sheet)
            ├── ↑ NotificationsView (sheet)
            ├── ↑ CrewManageView (sheet)
            │   └── ↑ CrewInviteView (sheet)
            └── ↑ TravelDetailsView (sheet)

Note: LineupView is accessible from HomeView "Browse Lineup" row (NavigationLink within the Home NavigationStack).
FestivalMapView exists but is not a top-level tab yet (Phase 1 promotion planned).
```

Key patterns:
- Each tab is wrapped in its own `NavigationStack` in `RootView`.
- Sheets use `.sheet(item:)` or `.sheet(isPresented:)`.
- `ArtistDetailView` wraps its own `NavigationView` to support potential push navigation within the sheet.

---

## Screens

### OnboardingView — First-launch onboarding
Shown as `.fullScreenCover` from `EncoreApp` when `@AppStorage(StorageKey.hasCompletedOnboarding) == false`. Setting this key to `true` on the Done step dismisses the cover.

5 pages in a `TabView` with `.tabViewStyle(.page(indexDisplayMode: .never))`. Dot-style page indicator at bottom.

| Page | Content |
|------|---------|
| 1 — Welcome | App name + tagline + "Get Started" CTA |
| 2 — Spotify | Description + "Connect Spotify" (stub) + "Skip for now" |
| 3 — Profile | Live avatar preview, display name TextField, 12-color avatar grid; writes to `@AppStorage` on Continue |
| 4 — Crew | Create crew / Join crew / Skip; create shows invite code after success |
| 5 — Done | Confirmation + "Let's Go" → sets `hasCompletedOnboarding = true` |

---

### HomeView — Festival Hub
Shows the user's current festival context at a glance.

| Section | Content |
|---------|---------|
| Festival Header | Selected festival name + dates/location |
| Group Card | Crew name, member bubbles, "+ Invite" → `CrewInviteView` sheet |
| Trip Card | "Travel Details" full-width row → `TravelDetailsView` sheet |
| Browse Lineup | Full-width row → pushes `LineupView` (via NavigationPath) |
| My Schedule | Day picker (day tabs) + list of user's sets; conflict banner if applicable |

---

### FestivalListView — Discover Tab Root
Browse all festivals.

- Reads from `FestivalDiscoveryStore.filteredFestivals` (status, text, artist, genre, camping filters)
- Status filter pills (All / Upcoming / Active / Past) bound to `discoveryStore.selectedStatus`
- `LazyVStack` of `FestivalCardView` cells wrapped in `NavigationLink`
- Toolbar: filter button (with active-count badge) → `DiscoveryFilterSheet`, magnifying glass → `ArtistSearchView`

### FestivalCardView
- 4pt colored left accent bar (from `festival.imageColorHex`)
- Name + status badge (pulsing dot for `.active`, countdown for `.upcoming`)
- Date range + location + horizontal genre chip scroll

### FestivalDetailView
- Hero: status pill, date/location, genre chips
- "Set as my festival" CTA → `festivalStore.selectFestival(_:)`
- Horizontal artist chip scroll (tappable when a `FestivalSet` exists)
- Your History: stats from `journalStore.entries(for: festivalID)`
- Travel Details row → `TravelDetailsView` sheet

### DiscoveryFilterSheet

Sheet presented from `FestivalListView` toolbar. Writes directly into `FestivalDiscoveryStore`.

| Section | Control | Store property |
| ------- | ------- | -------------- |
| Find festivals featuring | `TextField` | `artistNameFilter` |
| Type | 3 camping pills (Any / Camping / No Camping) | `campingFilter` |
| Genre | Expandable category rows + sub-genre chip grid | `selectedGenres: Set<String>` |

- Category row: tap name/icon = select entire top-level category; chevron = expand sub-genres
- Sub-genre chip grid: `LazyVGrid` adaptive columns, each chip toggles individual sub-genre
- Active selection shown as count badge (sub-genres) or checkmark (top-level only)
- "Clear all" toolbar button → `discoveryStore.clearFilters()`

### ArtistSearchView

- Deduplicated artists sourced from `discoveryStore.allFestivals` (all 9 festivals)
- De-duplication by artist name (same artist at multiple festivals = one row)
- `.searchable` bound to search text
- `MatchTier` filter chips
- List rows: tier dot, "Seen" badge from `journalStore`, genre subtitle
- Tapping a row → `ArtistDetailView` sheet

---

### LineupView — Full Timetable
Browse all artists by day; grid and list modes.

**Grid mode (default):** `TimetableGridView` with the full timetable. "Now" line auto-scrolls on appear.

**List mode:** `ArtistCardView` rows filtered by `lineupStore.filteredSets` for the selected day. Search bar + tier filter chips appear in list mode.

Toolbar button "Group Plan" → `GroupPlannerView` sheet.

### TimetableGridView
A `ScrollView([.horizontal, .vertical])` wrapping a `ZStack` with absolutely positioned elements.

- 44pt per 30-min row, 110pt column width, 36pt time column
- Horizontal grid stripes, vertical stage dividers
- Stage name headers across top row
- Hourly time labels on left
- `SetBlockView` elements for each set; tapping → `ArtistDetailView` sheet
- Walk-time gap pills between consecutive scheduled sets on different stages; tapping → `WalkTimeView` sheet
- "Now" line (1.5pt `appCTA` rectangle + 7pt circle, `.id("now-line")`) auto-scrolled to on appear

### SetBlockView
Per-set block inside the grid.

- Tier color fill + border
- 2pt `appCTA` border when `isAdded`
- Checkmark at `.topTrailing` when added
- `CrewAvatarBubble` stack at `.bottomLeading` showing which crew members are going

### GroupPlannerView
Shows the crew's combined schedule for a selected day.

- Day picker tabs
- "My schedule only" toggle
- Rows: artist info + crew avatar stack (You bubble + `CrewAvatarBubble`s); `appCTA`-tinted background when user has also scheduled the set

---

### SeenTrackerView — Journal Tab Root
- Stats strip: sets seen, festivals, avg rating
- "Rate your history" banner (shown when unrated past-festival sets exist)
- Festival filter chips
- 2-column `LazyVGrid` of `ArtistGridCell` — one cell per unique artist seen (deduped by `artistID`), sorted alphabetically; shows artist name + small star badge (or "—" if unrated)
- Artist name resolution: `seenArtists` reads `entry.artistName`; if empty (legacy entries saved before the field was added), falls back to matching `artist.id` in `festivalStore.festivals.flatMap(\.lineup)`
- Outer `VStack` uses `.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)` to prevent vertical centering when the empty state is shown
- Tap cell → `SetJournalEntryView` in edit mode (most recent entry for that artist)
- "Log a Set" toolbar button → `QuickLogView` sheet

### QuickLogView

Two-step state-driven sheet (no NavigationStack). Local `Step` enum: `.festival` / `.artist(Festival)`.

- Step 1: scrollable list of **all** festivals from `FestivalStore`, sorted by start date descending (no lineup-empty filter — festivals from Supabase arrive with `lineup: []`)
- Step 2: alphabetical artist list for the selected festival. Uses local `@State` (`loadedArtists`, `isLoadingArtists`) — does **not** touch `LineupStore`. If `festival.lineup` is non-empty, artists populate instantly; otherwise calls `LineupService.shared.fetchLineup(for: festival.slug)` directly, deduplicates by `artist.id`, and shows a `ProgressView` while loading. Errors silently leave the list empty.
- Back button resets `loadedArtists` and `isLoadingArtists` before returning to the festival step.
- `SeenTrackerView` receives the `onSelect(Artist, Festival)` callback, stores the artist + festival, then presents `SetJournalEntryView(artist:festival:)` after a 0.6s delay (required for iOS sheet sequencing)

### JournalEntryRowView
- Green dot + artist name + festival + date + note preview + 5-star mini rating
- Names read from `entry.artistName` / `entry.festivalName` (no mock-data lookup)

### SetJournalEntryView

Three init overloads:

- `init(entry: JournalEntry)` — edit existing entry (starts notes expanded if entry has notes)
- `init(artist: Artist, festival: Festival)` — create from quick-log flow
- `init(festivalSet: FestivalSet, festival: Festival?)` — create from artist detail page

Features: 5-star tap rating with spring animation, highlight chips with `FlowLayout` (iOS 16 `Layout`), collapsible notes behind "+ Add notes" toggle row (2000-char `TextEditor` with counter), WouldSeeAgain 3-pill toggle, Delete with `confirmationDialog` in edit mode. Attendance toggle removed. Saves `artistName` and `festivalName` onto the entry at save time.

### ArtistHistoryView
- Artist tier badge + genres header
- Stats: times seen, avg rating
- `LazyVStack` grouped by festival with `JournalEntryRowView` entries

---

### ArtistDetailView — Artist Detail Sheet
Presented as a sheet from any screen.

Sections:
- Hero: `LinearGradient` (tier color → `appBackground`), tier badge, genres, Spotify match or "sounds like"
- Set Info: Stage / Day / Time (3-cell grid)
- Your Crew: attendees from `CrewStore` (shown only if any)
- Similar on Lineup: horizontal chip scroll of `soundsLike` artists that exist on the lineup
- Recent Setlist: 7 hardcoded placeholder songs
- Journal section: "View your notes →" if seen; "Log this set →" if past
- Bottom actions (safeAreaInset): conflict warning banner + "Add to My Schedule" / "Added" + static stage row with `mappin.and.ellipse`

---

### WalkTimeView — Walk Time Detail Sheet
`.presentationDetents([.medium, .large])`.

- From/to stage header
- 42pt walk time number in severity color
- Severity status text (safe / close / tight / over)
- `GeometryReader` timeline bar (gap block + walk block)
- Leave-early suggestion chip when shortfall > 0
- FROM/TO set info cards with end time label
- Disclaimer footer

---

### ConflictResolverView — Conflict Resolution Sheet
`.presentationDetents([.medium])`. Side-by-side set cards, Keep A / Keep B / Decide Later.

---

### TravelDetailsView — Trip Logistics
`NavigationView`-wrapped `List` with sections:
- Trip Overview: DatePickers (arrival/departure), Pickers (transport, accommodation), campsite TextField
- Packing List: toggleable items (strikethrough when packed), swipe-to-delete, inline add form, "Load Bonnaroo defaults"
- Expenses: per-item rows with running total header, inline add form, swipe-to-delete

Reads/saves via `festivalStore.saveTravelDetails(_:for:)`.

---

### ProfileView — Settings
Sections: Profile header | Account (Edit Profile) | Crew & Festival (My Crew, Travel Details) | Preferences (Theme, Notifications) | Legal & Support | Sign Out (with `confirmationDialog`)

Navigation: wrapped in `NavigationStack` from `RootView` (no inner `NavigationView`).

### EditProfileView
- Live avatar preview (circle + initials from draft name/color)
- Display name TextField
- 6×2 `LazyVGrid` color swatch picker
- Spotify connect/disconnect card
- Save → writes to `@AppStorage(StorageKey.displayName)` and `@AppStorage(StorageKey.avatarColorHex)`

### NotificationsView
`@AppStorage`-backed `Toggle`s for set reminder, reminder offset (`Picker` 15/30/60 min), conflicts, crew changes, walk time. Each toggle's `onChange` calls `UNUserNotificationCenter.requestAuthorization`.

### CrewManageView
- Crew name + monospaced invite code + copy button
- Members list with `CrewAvatarBubble` + online dot + `lastSeenStage`
- Leave Crew with `confirmationDialog`
- Invite toolbar button → `CrewInviteView` sheet

### CrewInviteView
- Segmented create/join picker
- Create: name TextField → `createCrew()` → success state with invite code + `ShareLink`
- Join: 6-char monospaced TextField (auto-uppercase, max 6) → `joinCrew()` → dismiss or inline error

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
    soundsLike: [String]
    stageName: String
    isHeadliner: Bool
    var spotifyLabel: String?       // computed
}
```

### MatchTier
| Tier | `.color` |
|------|----------|
| `.mustSee` | `.appCTA` |
| `.worthChecking` | `.appAccent` |
| `.explore` | `.appTeal` |
| `.unknown` | `.appTextMuted` |

Additional computed: `.backgroundColor` = `color.opacity(0.18)`, `.blockFill`, `.blockBorder`.

### FestivalSet
```swift
struct FestivalSet {
    id: UUID
    artist: Artist
    stageName: String
    day: FestivalDay                // .thursday | .friday | .saturday | .sunday
    startTime: Date
    endTime: Date
    var durationMinutes: Int
    var timeRangeLabel: String
    func overlaps(with:) -> Bool
}
```

### Festival
```swift
struct Festival: Identifiable, Codable {
    id: UUID
    name: String
    slug: String                    // used as Supabase query key
    location: String
    latitude: Double
    longitude: Double
    startDate: Date
    endDate: Date
    status: FestivalStatus          // .upcoming | .active | .past
    isCamping: Bool
    genres: [String]
    imageColorHex: String
    lineup: [Artist]
    sets: [FestivalSet]
    source: FestivalSource          // .supabase | .edmTrain
    eventURL: URL?                  // non-nil for EDM Train events; ToS link
    var region: RegionFilter        // computed from lat/lon
}

enum FestivalStatus: String, Codable { case upcoming, active, past }
enum RegionFilter: String, CaseIterable { case any, west, southwest, midwest, southeast, northeast, international }
```

### JournalEntry
```swift
struct JournalEntry: Identifiable, Codable {
    id: UUID
    artistID: UUID
    festivalID: UUID
    setID: UUID
    dateAttended: Date
    rating: Int?                    // 1–5
    notes: String
    highlights: [String]
    wouldSeeAgain: WouldSeeAgain?
    artistName: String              // written at save time; fallback "" for legacy entries
    festivalName: String            // written at save time; fallback "" for legacy entries
}

enum WouldSeeAgain: String, Codable { case yes, maybe, no }
```

`JournalEntry` has a custom `init(from:)` that uses `decodeIfPresent` for `artistName`/`festivalName`, defaulting to `""` for pre-existing persisted entries (migration-safe).

### TravelDetails / PackingItem / ExpenseItem
```swift
struct TravelDetails: Codable {
    festivalID: UUID
    arrivalDate: Date?
    departureDate: Date?
    transportMode: String?
    accommodationType: String?
    campsite: String?
    packingItems: [PackingItem]
    expenses: [ExpenseItem]
}
struct PackingItem: Identifiable, Codable { id, name, isPacked, category: String }
struct ExpenseItem: Identifiable, Codable { id, description: String, amount: Double, paidBy: String, date: Date }
```

### WalkTimeWarning
```swift
struct WalkTimeWarning: Identifiable {
    id: UUID
    setA, setB: FestivalSet
    gapMinutes, walkMinutes, shortfall: Int
}
```

### Crew / CrewMember
```swift
struct CrewMember {
    id: UUID; name: String; colorHex: String
    scheduledSetIDs: [UUID]; isOnline: Bool; lastSeenStage: String?
    var color: Color; var initials: String
}
struct Crew { id, name, inviteCode, members }
// MeetupPin retained in file for Phase 2 map feature
```

---

## Store Architecture

All stores are `@ObservableObject`, instantiated in `EncoreApp` as `@StateObject`, injected via `.environmentObject()`.

### ScheduleStore
```
scheduledSets: [FestivalSet]           // persisted to UserDefaults on change
add / remove / toggle / isScheduled
sets(for day:) → [FestivalSet]
conflicts: [SetConflict]
hasConflicts: Bool
resolveConflict(_:keep:)
walkTimeWarnings(for day:) → [WalkTimeWarning]
```

### LineupStore
```
allSets: [FestivalSet]                 // loaded via LineupService.fetchLineup(for: slug); falls back to FestivalSet.mockSets on error
isLoading: Bool
selectedDay: FestivalDay?
selectedTier: MatchTier?
searchText: String
isSpotifyConnected: Bool
filteredSets: [FestivalSet]
loadLineup(festivalSlug:) async        // called by LineupView .task on festival change; mock fallback on Supabase error
connectSpotify() / disconnectSpotify() // TODO stubs
```

### CrewStore
```
crew: Crew?
createCrew(name:)
joinCrew(code:completion:)             // TODO Supabase
leaveCrew()
mergedSets(allSets:) → [FestivalSet]
attendees(for set:) → [CrewMember]
```

### FestivalStore
```
festivals: [Festival]                  // loaded via LineupService.fetchFestivals(); mock fallback on error
selectedFestival: Festival?            // persisted as UUID string to UserDefaults
travelDetails: [UUID: TravelDetails]   // persisted to UserDefaults on change
isLoading: Bool
loadFestivals() async                  // called on init; restores selectedFestival from UserDefaults after load
festivals(for status:) → [Festival]
selectFestival(_:)
saveTravelDetails(_:for:)
```

### JournalStore
```
entries: [JournalEntry]                // persisted to UserDefaults on change
entries(forArtist:) → [JournalEntry]
entries(forFestival:) → [JournalEntry]
upsert(_:) / delete(_:)
hasSeenArtist(_:) → Bool
averageRating(for:) → Double?
```

---

## Services

### LineupService
Swift `actor`, singleton `LineupService.shared`. Initialises `SupabaseConfig.client` from `APIKeys`.

| Method | Purpose |
| ------ | ------- |
| `fetchFestivals()` | Upcoming/active festivals (used by `FestivalStore`) |
| `fetchAllFestivals()` | Full catalog including past (used by `FestivalDiscoveryStore`) |
| `fetchLineup(for: slug)` | Confirmed sets for a festival from `v_festival_sets_full` view |
| `fetchLineupByDay(for: slug)` | Same, grouped `[FestivalDay: [FestivalSet]]` |
| `fetchHeadliners(for: slug)` | Headliners only |
| `searchArtist(name:)` | Cross-festival artist search (ilike) |
| `scheduleSet(_:)` / `unscheduleSet(_:)` | Write to `user_scheduled_sets` (requires `db.auth.session`) |
| `fetchScheduledSetIDs()` | Load user's scheduled set UUIDs from Supabase |

Supabase tables/views used: `festivals`, `v_festival_sets_full`, `user_scheduled_sets`.

### SetlistService

Swift `actor`, singleton `SetlistService.shared`. Two-step: MusicBrainz MBID lookup → setlist.fm setlist fetch. Results cached in-memory per artist name.

| Method | Purpose |
| ------ | ------- |
| `fetchRecentSetlist(for artistName:)` | Returns `[String]` song names from most recent setlist |

---

## Utilities

### StorageKey
Typed `UserDefaults` key constants. Never use raw strings — always use `StorageKey.*`.

| Key | Type | Used by |
|-----|------|---------|
| `.scheduledSets` | `Data` (JSON) | `ScheduleStore` |
| `.journalEntries` | `Data` (JSON) | `JournalStore` |
| `.travelDetails` | `Data` (JSON) | `FestivalStore` |
| `.selectedFestivalID` | `String` (UUID) | `FestivalStore` |
| `.displayName` | `String` | `@AppStorage`, `EditProfileView`, `OnboardingView` |
| `.avatarColorHex` | `String` | `@AppStorage`, `EditProfileView`, `OnboardingView` |
| `.hasCompletedOnboarding` | `Bool` | `EncoreApp`, `OnboardingView` |
| `.appTheme` | `String` | `EncoreApp`, `ProfileView` |
| `.notifSetReminder` | `Bool` | `NotificationsView` |
| `.notifReminderOffset` | `Int` | `NotificationsView` |
| `.notifConflicts` | `Bool` | `NotificationsView` |
| `.notifCrewChanges` | `Bool` | `NotificationsView` |
| `.notifWalkTime` | `Bool` | `NotificationsView` |

### StageWalkTime
Static lookup table for Bonnaroo stage pairs.
```swift
StageWalkTime.minutes(from: stageName, to: stageName) -> Int?
```
Returns `nil` if either stage is unknown. Bidirectional.

---

## Design System

### Spacing
| Token | Value |
|-------|-------|
| `DS.Spacing.pageMargin` | 16pt |
| `DS.Spacing.cardGap` | 12pt |
| `DS.Spacing.cardPadding` | 16pt |
| `DS.Spacing.sectionGap` | 8pt |
| `DS.Spacing.sectionHeaderGap` | 20pt |
| `DS.Spacing.inlineGap` | 6pt |

### Row Heights
| Token | Value |
|-------|-------|
| `DS.RowHeight.schedule` | 60pt |
| `DS.RowHeight.dayPicker` | 44pt |

### Corner Radii
| Token | Value |
|-------|-------|
| `DS.Radius.card` | 16pt |
| `DS.Radius.chip` | 10pt |
| `DS.Radius.pill` | 99pt |

### Typography
| Token | Size | Weight | Usage |
|-------|------|--------|-------|
| `DS.Font.display` | 36pt | Black | Onboarding / display |
| `DS.Font.hero` | 28pt | Black | Festival name hero title |
| `DS.Font.stat` | 28pt | Black | Large stat numbers |
| `DS.Font.rating` | 22pt | Bold | Star rating display |
| `DS.Font.cardTitle` | 16pt | Bold | Card section titles |
| `DS.Font.listItem` | 14pt | Semibold | List item primary text |
| `DS.Font.metadata` | 12pt | Regular | Secondary info |
| `DS.Font.label` | 11pt | Bold | Section caps labels |
| `DS.Font.caps` | 10pt | Bold | Tight caps labels |

### Walk Severity Colors
| Token | Meaning |
|-------|---------|
| `DS.WalkSeverity.safe` | Enough time (`appCTA`) |
| `DS.WalkSeverity.close` | Within 5 min of walk time (`appTeal`) |
| `DS.WalkSeverity.tight` | Gap < walk time (`appWarn`) |
| `DS.WalkSeverity.over` | No time at all (`appDanger`) |

### Journal Colors
| Token | Value |
|-------|-------|
| `DS.Journal.starFilled` | `appCTA` |
| `DS.Journal.starEmpty` | `appAccent.opacity(0.3)` |

---

## Color Tokens

| Token | Dark | Light | Usage |
|-------|------|-------|-------|
| `.appBackground` | `#1C2522` | `#FAFDE6` | Screen backgrounds |
| `.appSurface` | `#2A332F` | `#FFFFF0` | Card backgrounds, inputs |
| `.appAccent` | `#A8BFB2` | `#A8BFB2` | Borders, icons, secondary elements |
| `.appCTA` | `#E8F7D0` | `#E8F7D0` | Primary actions, tab tint, mustSee tier |
| `.appTeal` | `#D4ECEC` | `#D4ECEC` | Explore tier, walk-time "close" |
| `.appTextPrimary` | `#EAEAEF` | `#202030` | Main text |
| `.appTextMuted` | `#A8BFB2` | `#A8BFB2` | Secondary text, placeholders |
| `.appDanger` | `#E05555` | `#C03030` | Errors, "over" walk severity |
| `.appWarn` | `#F0A840` | `#C07800` | Conflicts, "tight" walk severity |

---

## Technical Constraints

| Constraint | Detail |
|------------|--------|
| **iOS 16 target** | Use `@ObservableObject`/`@Published` (not `@Observable`). Use `Map(coordinateRegion:)` (not iOS 17 API). Do not use iOS 17+ APIs without bumping deployment target in `project.yml`. |
| **Persistence** | `UserDefaults` only — `scheduledSets`, `journalEntries`, `travelDetails`, `selectedFestivalID`. No SQLite or Supabase yet. |
| **No backend** | `connectSpotify()` and `joinCrew(code:)` are stubs. Do not add real network calls without backend infrastructure. |
| **SPM packages** | Supabase Swift (`supabase-swift 2.0.0`) is active. Add packages via `project.yml` only — never via Xcode UI. |
| **XcodeGen managed** | `.xcodeproj` is generated. Never edit directly. Run `xcodegen generate` after changes to the file tree. |
| **Adaptive theming** | `@AppStorage(StorageKey.appTheme)` drives `preferredColorScheme` in `EncoreApp`. All colors must use token extensions — no hardcoded hex or system colors. |
| **SF Symbols only** | No emoji in UI. All icons via SF Symbols. |
| **44pt tap targets** | All interactive elements must meet minimum 44×44pt. |
| **StorageKey** | All `UserDefaults` access must use `StorageKey.*` constants — never raw string literals. |

---

## What's Real vs. Mocked

| Feature | Current State |
|---------|--------------|
| Festival catalog | **Live** — `LineupService.fetchAllFestivals()` from Supabase; mock fallback |
| Active festival | **Live** — `LineupService.fetchFestivals()` from Supabase; mock fallback |
| Lineup data | **Live** — `LineupService.fetchLineup(for:)` from `v_festival_sets_full`; `LineupStore` falls back to `FestivalSet.mockSets` on error |
| Recent setlist | **Live** — `SetlistService` (MusicBrainz + setlist.fm API); empty array on miss |
| EDM Train events | **Live** — `EDMTrainService.fetchEvents(locationId:)` fetched via active festival location; empty array on failure |
| Set reminders / notifications | **Live** — `NotificationScheduler` wraps `UNUserNotificationCenter` |
| Schedule persistence | **Local** — UserDefaults JSON encoding |
| Journal persistence | **Local** — UserDefaults JSON encoding |
| Travel details persistence | **Local** — UserDefaults JSON encoding |
| Crew members | `MockData.swift` — 4 members (no Supabase user tables yet) |
| Stage walk times | `StageWalkTime.swift` — hardcoded 10 Bonnaroo stage pairings |
| Spotify | `connectSpotify()` is a stub; no OAuth |
| Crew invite | `joinCrew()` is a stub; no Supabase |
| User auth / schedule sync | `LineupService` stubs exist (`scheduleSet`, etc.) but require `db.auth.session` |

---

## Phase Roadmap

### Phase 1 — Remaining
- Spotify OAuth via `ASWebAuthenticationSession` → real match scores
- Supabase user auth → wire `scheduleSet`/`unscheduleSet`/`fetchScheduledSetIDs` to real auth session
- Promote `FestivalMapView` to top-level tab
- Offline map tile caching (MapKit overlay)
- `PackingView` and `ExpensesView` (models + `bonnarooDefaults` exist; views not built)

### Phase 2 — Realtime & Social
- `CrewStore` → Supabase Realtime for live schedule sync
- CoreLocation + Supabase presence for location sharing
- Restore `FestivalMapView` with walk-time navigation context
- QR code crew invite flow
- Group chat via Supabase Realtime channels
- Push notifications for set reminders and crew changes

### Phase 3 — Personalization
- Recommendation engine based on Spotify history
- Social discovery (see what friends outside crew are watching)
