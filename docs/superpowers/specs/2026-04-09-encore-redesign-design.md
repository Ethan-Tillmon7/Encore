# Encore — Redesign Spec
Date: 2026-04-09

## Overview

Simplify Encore from a 4-tab app (Discover, Schedule, Crew, Map) to a 2-tab app (Home, Profile). Home becomes the festival hub: group presence, trip logistics, lineup access, and personal schedule — all on one screen. The Lineup screen replaces Discover with a full timetable grid. Map becomes contextual, not a persistent tab. A new color system replaces the current purple-on-system-background palette.

The UI/UX checklist in `UI-UX.txt` governs every screen: one job per screen, one dominant action, content over chrome, 44pt tap targets, no emojis (SF Symbols only).

---

## 1. Navigation

### Structure
- **2-tab bar**: Home (house SF Symbol) + Profile (person.circle SF Symbol)
- `MainTabView` is simplified to two cases: `.home` and `.profile`
- Tab bar background: `surface` color token (no blur/translucency needed)
- Active tab icon tint: `cta` (`#E8F7D0` dark / `#E8F7D0` light)
- Inactive tab icon tint: `accent` (`#A8BFB2`)

### Removed tabs
- Discover → replaced by Lineup (accessed from Home)
- Schedule → embedded in Home
- Crew → embedded in Home (group card)
- Map → contextual, accessed from Lineup and artist detail

### Contextual Map access
- Lineup grid: tap a stage column header → pushes `FestivalMapView` pre-centered on that stage
- Artist detail sheet: "Directions to [Stage]" button → same map view

---

## 2. Color System

A `Theme` enum drives the color scheme. Remove the forced `.preferredColorScheme(.dark)` from `EncoreApp.swift` and replace with the user's stored preference (default: `.system`).

### Tokens

| Token name    | Dark mode  | Light mode |
|---------------|------------|------------|
| `background`  | `#1C2522`  | `#FAFDE6`  |
| `surface`     | `#2A332F`  | `#FFFFF0`  |
| `accent`      | `#A8BFB2`  | `#A8BFB2`  |
| `cta`         | `#E8F7D0`  | `#E8F7D0`  |
| `teal`        | `#D4ECEC`  | `#D4ECEC`  |
| `textPrimary` | `#EAEAEF`  | `#202030`  |
| `textMuted`   | `#A8BFB2`  | `#A8BFB2`  |

### Implementation
- Add `AppColors.swift` with a `Color` extension exposing each token as a static computed property using `colorScheme` environment value
- Replace all hardcoded `.purple`, `Color(uiColor: .systemBackground)`, `Color(uiColor: .secondarySystemBackground)`, and `Color(uiColor: .tertiaryLabel)` references across all view files
- `MatchTier.color` for must-see maps to `cta`, worth-checking maps to `accent`, explore maps to `teal`, unknown maps to `textMuted`

---

## 3. Home Screen (`HomeView`)

**One job:** Give the user a full picture of their festival — crew, logistics, and today's schedule — without navigating anywhere.

### Layout (top to bottom)

#### Festival Header
- Large title: festival name (e.g. "Bonnaroo '25"), font weight heavy, color `cta`
- Subtitle: dates + location, color `textMuted`

#### Group Card
- Surface card (`surface` background, `accent` border at 18% opacity)
- Header row: section label "FESTIVAL GROUP" + crew name on the left; "+ Invite" pill button on the right
- Member row: horizontal stack of avatar bubbles
  - Each avatar: circle filled with member's `colorHex`, initials (max 2 letters) in `background` color
  - Online indicator: small `cta`-colored dot bottom-right of avatar; offline = `surface`-dark dot
  - Member name label beneath each avatar, `textMuted`, 9pt
- No other content on this card

#### Trip Card
- Surface card, same styling
- Three equal columns separated by 1pt `accent`-opacity dividers: Travel | Packing | Expenses
- Each column: SF Symbol icon (system `accent` tint) + label + status detail (`textMuted`)
  - Travel: `airplane` icon, departure summary
  - Packing: `backpack` icon, "X of Y packed"
  - Expenses: `dollarsign.circle` icon, "$ / person"
- Each column is individually tappable → opens a detail sheet for that section
- Trip detail sheets are new modal views (not implemented in the current codebase)

#### Browse Full Lineup Button
- Full-width row, `surface` background, `cta`-opacity border
- Left: "Browse Full Lineup" label (`cta` color, semibold) + subtitle "X artists" (`textMuted`)
- Right: chevron.right icon
- Taps → pushes `LineupView` via NavigationStack

#### My Schedule
- Section label "MY SCHEDULE" + day picker (Thu/Fri/Sat/Sun pills)
  - Active pill: `cta` text + subtle `cta`-opacity background
  - Inactive: `textMuted`
- Scrollable list of `FestivalSet` rows for the selected day, sorted by start time
  - Each row: time column (start/end, `textMuted`) + 3pt left color bar (`cta` for normal, amber `#F59E0B` for conflict) + artist name + stage name
  - Conflict indicator: amber border + `exclamationmark.triangle` icon
  - Tap → artist detail sheet (same `ArtistDetailView`, restyled)
- Empty state: "Nothing scheduled for [Day] — browse the lineup to add sets"

### Scroll behavior
The entire Home screen is one `ScrollView`. The festival header is not sticky. Day picker within My Schedule does not need to be sticky (screen is not tall enough to warrant it with just 3 above-the-fold sections).

---

## 4. Lineup Screen (`LineupView`)

**One job:** Browse the full festival lineup and add sets to your personal schedule.

### Structure
- Navigation title: "Lineup" (inline display mode — this is a pushed view, not a tab root)
- Day segmented picker at top: Thu / Fri / Sat / Sun
- Full timetable grid below

### Timetable Grid
- Two-axis scroll: horizontal (stages) + vertical (time)
- **Y axis (time):** 30-minute row increments from first set start to last set end for the selected day. Time labels left column, `textMuted`, 8pt.
- **X axis (stages):** one column per stage. Stage name in fixed header row at top. Tapping a stage header pushes `FestivalMapView` centered on that stage.
- **Set blocks:** positioned by start time, height proportional to duration (1 row = 30 min = 18pt height)
  - Must-see: `cta` tint, `cta` border at 30% opacity
  - Worth checking: `accent` tint, `accent` border
  - Explore: `teal` tint, `teal` border
  - Unknown: `textMuted` tint
  - Added to schedule: solid colored border, checkmark.circle icon overlay
- Tap a set block → presents `ArtistDetailView` as a sheet

### Implementation note
The timetable grid is a `ScrollView` containing a custom `Canvas` or manually positioned `ZStack` of blocks. Do not use `LazyVGrid` — block positioning must be time-accurate (blocks placed by offset from day start, not by row index). A `GeometryReader` provides column widths. Stage headers are a separate fixed `HStack` above the scroll area.

---

## 5. Artist Detail Sheet (`ArtistDetailView`)

Restyled but structurally unchanged from current implementation. Key changes:
- Replace purple accent with `cta` / `accent` tokens
- Replace `Color(uiColor: .secondarySystemBackground)` with `surface`
- "Add to My Schedule" / "Added" CTA button uses `cta` background with `background`-colored text
- "Directions to [Stage]" button added below set info row → pushes `FestivalMapView` centered on the artist's stage

---

## 6. Profile Screen (`ProfileView`)

**One job:** Account settings and app preferences.

### Layout
- Profile photo circle + display name at top (centered, like iOS Settings)
- Plain grouped list sections:
  - **Account:** Edit Profile
  - **Preferences:** Theme (System / Light / Dark — inline segmented picker), Notifications
  - **Legal & Support:** Privacy & Security, Help Center, Terms of Service
  - **Session:** Sign Out (destructive red)
- Theme selection persists to `UserDefaults` and is read at app launch in `EncoreApp`

---

## 7. Map View (`FestivalMapView`)

No structural changes. Restyling only:
- Replace purple tint with `cta`
- Replace `Color(uiColor: .secondarySystemBackground)` with `surface`
- Stage marker circles: `cta` background for stages, `accent` for amenities
- Amenity toggle button uses `surface` card style

Map is presented as a full-screen push (not a sheet) from:
1. Stage header tap in `LineupView`
2. "Directions to [Stage]" button in `ArtistDetailView`

---

## 8. Store Changes

### DiscoverStore → retained as-is
Rename to `LineupStore` for clarity. `allSets` and filter state remain. The filter UI (day/tier chips) moves inside `LineupView`.

### ScheduleStore — no changes
Already well-structured. Used in `HomeView` for My Schedule section.

### CrewStore — no changes
Used in `HomeView` for group card.

### New: ThemeStore (or UserDefaults key)
A lightweight `@AppStorage("appTheme") var theme: ThemePreference = .system` in `EncoreApp` drives `preferredColorScheme` on the root `WindowGroup`. No separate store needed.

---

## 9. Files to Create

| File | Purpose |
|------|---------|
| `AppColors.swift` | Color token extension |
| `HomeView.swift` | Replaces MainTabView as app hub |
| `LineupView.swift` | Timetable grid view |
| `ProfileView.swift` | Settings list |
| `TripDetailSheet.swift` | Detail sheet for Travel / Packing / Expenses (stub — real data in Phase 1) |

## 10. Files to Delete

| File | Reason |
|------|--------|
| `DiscoverView.swift` | Replaced by LineupView |
| `MyScheduleView.swift` | Schedule embedded in HomeView |
| `CrewView.swift` | Crew embedded in HomeView (group card) |
| `MainTabView.swift` | Replaced by HomeView + ProfileView under new nav |

## 11. Files to Modify

| File | Changes |
|------|---------|
| `EncoreApp.swift` | Remove forced dark mode; inject `ThemeStore`/`@AppStorage`; update root view |
| `ArtistDetailView.swift` | Restyle colors; add "Directions to [Stage]" button |
| `ArtistCardView.swift` | Restyle colors; keep logic |
| `FestivalMapView.swift` | Restyle colors; remove tab-based navigation assumption |
| `ScheduleStore.swift` | No logic changes |
| `DiscoverStore.swift` | Rename to `LineupStore` |
| `Artist.swift` | Update `MatchTier.color` to use new tokens |
| `ConflictResolverView.swift` | Restyle colors |

---

## Out of Scope (Phase 2+)

- Real data in Trip Detail sheets (travel itinerary, packing checklist, expense splitting)
- Spotify OAuth
- Supabase backend (crew sync, real lineup)
- Location sharing
- QR code invite flow
