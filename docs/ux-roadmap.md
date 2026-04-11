# Encore — UX Roadmap & Design Audit

> Living document. Update whenever a to-do is resolved, a new view is added, or priorities shift.
> Cross-reference with `docs/encore-context.md` for API details.

---

## App Pillars

| # | Pillar | Description |
|---|--------|-------------|
| 1 | **Discover** | Multi-festival browse, Spotify matching, artist deep-dives |
| 2 | **Schedule** | Personal timetable, conflict resolution, day planning |
| 3 | **Crew** | Group coordination, shared schedule, live presence |
| 4 | **Navigate** | Venue map, stage routing, amenity discovery |

---

## Current View Inventory

### Exists
| View | Status | Notes |
|------|--------|-------|
| `HomeView` | ✅ built | Festival hub — crew card, trip card, schedule entry |
| `LineupView` + `TimetableGridView` | ✅ built | Day-by-day timetable grid |
| `ArtistDetailView` | ✅ built | Full artist sheet with set info + schedule actions |
| `ArtistCardView` | ✅ built | List card — now used in lineup list mode (was orphaned) |
| `ArtistProfileView` | ✅ built | Lightweight sheet for artists without confirmed set times |
| `ConflictResolverView` | ✅ built | Side-by-side conflict picker |
| `FestivalMapView` | ✅ built | MapKit — stage pins, amenity toggles, stage card, meetup pins |
| `ProfileView` | ✅ built | Theme, notifications, account settings, Journal link |
| `FestivalListView` | ✅ built | Festival catalog with search + status pills (reachable from HomeView) |
| `FestivalDetailView` | ✅ built | Festival detail — lineup, history, travel, camping |
| `FestivalCardView` | ✅ built | Card with camping badge, accent color, genre chips |
| `ArtistSearchView` | ✅ built | Cross-festival artist search with tier filter |
| `DiscoveryFilterSheet` | ✅ built | Artist / camping / region / hierarchical genre filters |
| `SeenTrackerView` | ✅ built | Past set log (reachable from ProfileView → Sets I've Seen) |
| `OnboardingView` | ✅ built | 5-screen first-launch flow, wired in EncoreApp |
| `CrewInviteView` | ✅ built | Create / join crew sheet |
| `CrewManageView` | ✅ built | Crew hub — now the Crew tab destination |
| `NotificationsView` | ✅ built | Set reminders + crew/conflict alert toggles |
| `EditProfileView` | ✅ built | Name + avatar color picker |
| `TravelDetailsView` | ✅ built | Arrival, campsite, transit details |

### Missing / Stub
| View | Priority | Notes |
|------|----------|-------|
| `PackingView` | 🟡 P1 | Not yet built |
| `ExpensesView` | 🟡 P1 | Not yet built |
| `GroupChatView` | 🔵 P2 | Phase 2 — Supabase Realtime |
| `StageDetailView` | 🔵 P2 | Slide-up from map pin (inline detent) |

---

## Tab Structure

### Current (5 tabs — implemented ✅)
```
Home  ·  Lineup  ·  Map  ·  Crew  ·  Profile
```
- Discover Festivals accessible from HomeView → "Discover Festivals" row
- Sets I've Seen (Journal) accessible from Profile → "Sets I've Seen" row

---

## Screen-by-Screen Audit

### HomeView
**What works**
- Single-screen festival context — crew, trip, schedule at a glance
- Day picker for schedule is a strong pattern
- Conflict banner surfaced inline

**Problems**
- 🔴 No dominant action — tries to be everything
- 🔴 Trip card rows (Travel / Packing / Expenses) tap to nothing — dead taps undermine trust
- 🔴 No onboarding hook — new users see empty crew and empty schedule with no guidance
- 🟡 Festival header is static — no countdown, no live day context
- 🟡 "Browse Lineup" row could be replaced by a "Next up" card during the festival

**To-do**
- [ ] Add live countdown to festival header ("3 days until gates open" / "Day 2 of 4")
- [ ] Replace "Browse Lineup" row with a "Next up" card showing the user's next scheduled set
- [ ] Add empty states with action CTAs: "Invite your squad →" / "Browse the lineup →"
- [ ] Either implement TravelView/PackingView/ExpensesView or disable the trip card rows visually

---

### LineupView / TimetableGridView
**What works**
- 2-axis scroll timetable is the correct mental model
- Absolute time positioning is more accurate than a list
- Day picker + stage columns maps to real-world layout

**Problems**
- 🔴 No "now" time indicator — essential for real festival use
- 🔴 No visual differentiation for scheduled vs. unscheduled blocks
- 🟡 No search or filter entry point within the view
- 🟡 No crew overlap indicators on timetable blocks
- 🟡 No list view toggle (ArtistCardView has no home in the current grid)

**To-do**
- [ ] Add "now" horizontal line that auto-scrolls into view on load
- [ ] Highlight user's scheduled blocks (filled border or checkmark overlay)
- [ ] Show crew avatar stacks on blocks where crew members are attending
- [ ] Add search bar + tier filter chips to LineupView toolbar
- [ ] Add list view toggle (grid ↔ list) — list mode finally gives ArtistCardView a home

---

### ArtistDetailView
**What works**
- Clear info hierarchy: tier → set info → crew → setlist → CTA
- `safeAreaInset` bottom bar keeps actions always visible
- Crew attendance section is a strong social hook
- Similar artists section wired to soundsLike data

**Problems**
- 🟡 Setlist is 7 hardcoded songs — no real source
- 🟡 No pre-conflict warning before adding a set (conflict only surfaces after)
- 🟡 Sounds-like list is static — could deep-link to those artists

**To-do**
- [ ] Show pre-conflict warning inline when a set overlaps a scheduled one (before the user taps Add)
- [ ] Wire setlist to setlist.fm API in Phase 1
- [ ] Make soundsLike artist names tappable → open their ArtistDetailView/ArtistProfileView

---

### FestivalMapView
**What works**
- `initialStage` parameter allows deep-linking from artist detail
- Slide-up stage card with current/next act is a strong pattern
- Amenity toggles (water / medical / charging)

**Problems**
- 🔴 Map is NOT in the tab bar — only reachable via the Lineup tab
- 🔴 Location sharing toggle does nothing (CoreLocation not wired)
- 🔴 Walk time is hardcoded "~8 min" regardless of position
- 🟡 No meetup pin UI — `MeetupPin` model and `CrewStore.dropPin/removePin` exist but have no view
- 🟡 No crew member location layer on the map

**To-do**
- [ ] Promote Map to a top-level tab in RootView
- [ ] Add meetup pin drop via long-press gesture + pin management sheet
- [ ] Design crew location stub layer (placeholder avatars) — ready for Phase 2 CoreLocation
- [ ] Replace hardcoded walk time with computed value once CoreLocation is wired

---

### ConflictResolverView
**What works**
- Side-by-side "Keep A / Keep B / Decide Later" is clear and decisive
- `.medium` detent is correct presentation style

**Problems**
- 🟡 No crew context shown — crew attendance should inform the choice
- 🟡 "Decide Later" accumulates unresolved conflicts with no follow-up UI
- 🟡 Only resolves one conflict at a time — no batch review

**To-do**
- [ ] Add crew attendance avatars under each set card in the resolver
- [ ] Add conflict queue indicator ("1 of 3") when multiple conflicts exist

---

### ProfileView
**What works**
- Theme picker → `@AppStorage` → `preferredColorScheme` works correctly

**Problems**
- 🔴 Edit Profile is a stub — tapping does nothing
- 🔴 Notifications row has no action sheet
- 🟡 No Spotify connection status shown
- 🟡 Sign Out does nothing meaningful without a backend

**To-do**
- [ ] Build `EditProfileView` sheet (name + avatar color picker)
- [ ] Build `NotificationsView` sheet (set reminders, crew alerts, conflict alerts)
- [ ] Add Spotify connection card to ProfileView

---

## UX Gaps by Priority

### 🔴 P0 — Must fix before any real usage
- **Map is not tab-accessible.** During a festival, navigation is a primary use case. Buried 3 taps deep is a critical failure.
- **No onboarding or first-launch state.** New user sees empty crew, empty schedule, no Spotify match scores, no guidance on what to do first.
- **No "now" time indicator in timetable.** Without a current-time line, users can't orient to what's happening right now.
- **Dead taps everywhere.** Trip card, Crew Invite, Edit Profile, Notifications — 6+ interactive elements that do nothing. Erodes trust immediately.

### 🟡 P1 — Fix before launch
- **Crew has no dedicated space.** `CrewStore` has rich data but only surfaced in a small HomeView card.
- **Scheduled sets have no visual feedback in timetable.** After adding a set the block looks identical.
- **No pre-conflict warning.** Conflict only surfaced after adding. Should warn inline before the user taps "Add."
- **Schedule persistence is in-memory only.** Every app launch resets the schedule. `UserDefaults` encoding is a must.

### 🔵 P2 — Quality improvements
- **Crew overlap not visible in timetable blocks.** Crew member initials on blocks are a key differentiator.
- **No haptic feedback.** Adding a set, resolving a conflict, dropping a map pin — all warrant `UIImpactFeedbackGenerator`.
- **HomeView festival header is static.** Pre-festival: countdown. During: "Day 2 of 4." Post: recap prompt.
- **No artist image strategy.** Placeholder gradient (derived from tier color + name hash) would add significant polish without real images.

---

## New Views to Build

### 🔴 P0 — Current phase

#### `OnboardingView` (5 screens)
One job: get the user set up before they see the empty home screen.
- Screen 1: Welcome — festival name + dates, "Let's get you ready" CTA
- Screen 2: Connect Spotify (optional skip) — explains match scoring, shows tier distribution preview
- Screen 3: Your name — text field for display name used in crew
- Screen 4: Find your crew — "Create crew" / "Join with code" / "Go solo"
- Screen 5: Done — deep-link to lineup with "Start adding sets"
- Store completion flag in `UserDefaults`. Only shown on first launch.

#### `CrewView` — Crew Hub
One job: full crew management and coordination in one place.
- Header: crew name + member count + invite code
- Members: avatar, name, online indicator, last seen stage, expandable schedule
- Shared schedule: timeline of all sets any member is attending, with overlap indicators
- Meetup pins: list of active pins → tap to open map centered on pin
- Group chat: Phase 2 stub — design the empty state now
- Lives as its own tab. HomeView Group Card becomes a compressed preview.

#### `CrewInviteView`
One job: create or join a crew.
- Mode A — Create: crew name field → generates 6-char invite code → share sheet
- Mode B — Join: 6-field code entry (one char per box) → validate → join
- Presented as sheet from HomeView Group Card or CrewView empty state
- Error state when code is invalid

---

### 🟡 P1 — Before launch

#### `TripDetailViews` (Travel / Packing / Expenses)
Three sheets from the Trip Card on HomeView:
- **TravelView:** Arrival/departure info, campsite location, car/transit details. Form + `UserDefaults`.
- **PackingView:** Checklist with Bonnaroo-specific preloaded defaults (`PackingItem.bonnarooDefaults` exists).
- **ExpensesView:** Simple ledger — line items with amount + description, running total, optional per-person split.

#### `NotificationsView`
- Set reminders: toggle + time picker (15 / 30 / 60 min before)
- Conflict alerts: notify when a newly added set conflicts
- Crew alerts: when a crew member changes their schedule
- `UNUserNotificationCenter` permission request on first toggle
- Sheet from ProfileView Notifications row

#### `EditProfileView`
- Name text field (maps to `CrewMember.name`)
- Color picker — grid of preset hex values matching avatar color system
- Initials preview that updates live as name changes
- Save → updates `CrewStore` + `UserDefaults`

---

### 🔵 P2 — Phase 2

#### `GroupChatView`
- Standard chat bubble layout (sent right, received left)
- System messages: "Marcus added Hozier to their schedule"
- Set block deep-link previews when a set is shared in chat
- Design stub can be built now; wire to Supabase Realtime in Phase 2

---

## Navigation Architecture

### Recommended tab structure
```
RootView (5 tabs)
├── Home               — festival context hub
│   ├── sheet ↑ ArtistDetailView
│   └── sheet ↑ ConflictResolverView
├── Lineup (NavigationStack)
│   ├── TimetableGridView ↔ ListView toggle
│   └── sheet ↑ ArtistDetailView
├── Map
│   └── sheet ↑ StageDetailView (inline detent)
├── Crew (NavigationStack)
│   ├── CrewView
│   └── sheet ↑ CrewInviteView
└── Profile
    ├── sheet ↑ EditProfileView
    └── sheet ↑ NotificationsView
```

### Sheet vs. push rules
| Pattern | When to use | Examples |
|---------|-------------|---------|
| Push (`navigationPath`) | Drilling into sub-context, user needs Back | Map from Lineup |
| Sheet (`.medium`) | Focused decision or detail, swipe-dismissable | Artist, Conflict |
| Full sheet | Full attention, has own navigation | Onboarding |
| Inline detent | Contextual overlay over a map/canvas, background visible | Stage card |

### Deep link paths needed
| Path | Destination |
|------|-------------|
| `artist/{id}` | Open `ArtistDetailView` — from set reminder notifications |
| `map/{stage}` | Open map centered on a specific stage |
| `crew/join/{code}` | Open `CrewInviteView` pre-filled with a code |
| `schedule/conflict` | Open `ConflictResolverView` — from conflict push notification |
| `lineup/day/{day}` | Open timetable on a specific day |

---

## Phased Roadmap

### Phase 0 — Complete the skeleton ← current
**Views to build:**
- [x] `OnboardingView` (5 screens) — wired in EncoreApp, full flow
- [x] `CrewView` — `CrewManageView` promoted to Crew tab
- [x] `CrewInviteView` (sheet) — create/join flow

**Fixes:**
- [x] Promote Map to top-level tab
- [x] Add "now" line to timetable
- [x] Scheduled block visual state in grid (CTA border + checkmark)
- [x] Pre-conflict warning in `ArtistDetailView` (shown above Add button)
- [x] Remove or stub all dead taps (Travel, Notifications, Edit Profile all built)
- [x] Crew avatar stacks on timetable blocks
- [x] Empty states with action CTAs (HomeView crew + schedule empty states)

**Design polish:**
- [ ] Festival header → live countdown
- [ ] Haptic feedback at key moments (add to schedule, resolve conflict, drop pin)
- [ ] Conflict queue indicator ("1 of 3") in `ConflictResolverView`
- [ ] Crew context in conflict resolver
- [x] Meetup pin UI on map (drop via toolbar button + management sheet)
- [ ] Crew location placeholder layer on map

---

### Phase 1 — Local data & persistence
**Views to build:**
- [ ] `TravelView`, `PackingView`, `ExpensesView`
- [ ] `NotificationsView`
- [ ] `EditProfileView`

**Backend stubs → real:**
- [ ] Spotify OAuth via `ASWebAuthenticationSession`
- [ ] Real Bonnaroo lineup via Supabase
- [ ] Persist `scheduledSets` to `UserDefaults`
- [ ] Real setlist.fm API calls
- [ ] `UNUserNotificationCenter` set reminders
- [ ] Offline map tile caching

---

### Phase 2 — Realtime & social
**Views to build:**
- [ ] `GroupChatView` (Supabase Realtime)
- [ ] QR code crew invite flow

**Infrastructure:**
- [ ] `CrewStore` → Supabase Realtime for live schedule sync
- [ ] `CoreLocation` + Supabase presence for crew location sharing
- [ ] Live crew location layer on map
- [ ] Real walk-time estimates from user position

---

### Phase 3 — Discovery & intelligence
- [ ] Multi-festival discovery with real data (Bandsintown / Songkick)
- [ ] Location radius filter (use existing lat/lon model)
- [ ] Budgeting / travel cost calculator
- [ ] Artist recommendations based on Spotify listening history
- [ ] Post-festival recap screen with stats

---

## Design Principles (reference)

From `UI-UX.txt` — the Apple-style checklist to apply to every new screen:

1. **Purpose & Focus** — one screen, one job, one primary action
2. **Clarity** — first-time user understands in < 3 seconds, no clever wording
3. **Visual Hierarchy** — most important element is most visually dominant
4. **Simplicity** — cut 20–30% of elements without breaking experience
5. **Consistency** — same patterns everywhere, no surprises
6. **Feedback** — every action has immediate visual/haptic response
7. **Navigation** — user always knows where they are and how to go back
8. **Touch targets** — ≥ 44pt, primary action reachable by thumb
9. **Content first** — UI steps back when content matters
10. **Typography** — clear hierarchy, readable at a glance
11. **Accessibility** — sufficient contrast, works with screen readers
12. **Micro-interactions** — smooth, purposeful transitions
