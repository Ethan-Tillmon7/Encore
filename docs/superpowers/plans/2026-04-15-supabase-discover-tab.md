# Supabase Discover Tab Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire `FestivalDiscoveryStore` to fetch live festival data from Supabase instead of `Festival.mockFestivals`, so the Discover tab shows real data.

**Architecture:** Add `fetchAllFestivals()` to `LineupService` (no date filter, for discovery use case), then update `FestivalDiscoveryStore` to call it asynchronously on init with a mock fallback on failure. No other files change.

**Tech Stack:** Swift, SwiftUI, Supabase Swift SDK (`SupabaseClient` via `SupabaseConfig.client`)

---

> **Note on testing:** This project has no XCTest target configured. All verification is done by building and running in the iOS simulator. Steps marked "Verify in simulator" are the test equivalent.

---

## File Map

| File | Change |
|------|--------|
| `Encore/Services/LineupService.swift` | Add `fetchAllFestivals()` method |
| `Encore/Stores/FestivalDiscoveryStore.swift` | Replace mock init with async Supabase load |

---

### Task 1: Add `fetchAllFestivals()` to `LineupService`

**Files:**
- Modify: `Encore/Services/LineupService.swift`

`fetchFestivals()` (used by `FestivalStore`) filters out past festivals with `.gte("end_date", ...)`. The discovery store needs all festivals including past ones, so we add a separate method without that filter.

- [ ] **Step 1: Add `fetchAllFestivals()` inside the `LineupService` actor, directly after `fetchFestivals()`**

Open `Encore/Services/LineupService.swift`. After the closing brace of `fetchFestivals()` (around line 183), insert:

```swift
/// Returns all festivals regardless of date — used by FestivalDiscoveryStore
/// so past festivals still appear in the browse catalog.
func fetchAllFestivals() async throws -> [Festival] {
    let rows: [SupabaseFestivalRow] = try await db
        .from("festivals")
        .select("id, name, slug, city, state, start_date, end_date, genre_tags, cover_image_url, latitude, longitude, is_camping")
        .eq("is_active", value: true)
        .order("start_date")
        .execute()
        .value

    return rows.map { row in
        Festival(
            id:           UUID(uuidString: row.id) ?? UUID(),
            name:         row.name,
            slug:         row.slug,
            location:     [row.city, row.state].compactMap { $0 }.joined(separator: ", "),
            latitude:     row.latitude  ?? 0,
            longitude:    row.longitude ?? 0,
            startDate:    parseDate(row.start_date),
            endDate:      parseDate(row.end_date),
            status:       festivalStatus(start: row.start_date, end: row.end_date),
            isCamping:    row.is_camping ?? false,
            genres:       row.genre_tags,
            imageColorHex: "8B5CF6",
            lineup:       [],
            sets:         []
        )
    }
}
```

- [ ] **Step 2: Build to confirm no compile errors**

In Xcode press `Cmd+B`. Expected: Build Succeeded with 0 errors.

- [ ] **Step 3: Commit**

```bash
git add Encore/Services/LineupService.swift
git commit -m "feat: add fetchAllFestivals to LineupService for discovery use case"
```

---

### Task 2: Wire `FestivalDiscoveryStore` to Supabase

**Files:**
- Modify: `Encore/Stores/FestivalDiscoveryStore.swift`

Replace the synchronous mock-seeded init with an async load. Keep mock data as a silent fallback so the app stays usable if Supabase is unreachable.

- [ ] **Step 1: Add `isLoading` published property**

Open `Encore/Stores/FestivalDiscoveryStore.swift`. In the `// MARK: - Source data` section, change:

```swift
// MARK: - Source data
@Published var allFestivals: [Festival]
```

to:

```swift
// MARK: - Source data
@Published var allFestivals: [Festival] = []
@Published var isLoading: Bool = false
```

- [ ] **Step 2: Replace the `init` with an async-loading version**

Find the existing `init`:

```swift
init(festivals: [Festival] = Festival.mockFestivals) {
    allFestivals = festivals
}
```

Replace it with:

```swift
init() {
    Task { await loadFestivals() }
}

@MainActor
func loadFestivals() async {
    isLoading = true
    do {
        allFestivals = try await LineupService.shared.fetchAllFestivals()
    } catch {
        print("FestivalDiscoveryStore: fetch failed — \(error)")
        allFestivals = Festival.mockFestivals
    }
    isLoading = false
}
```

- [ ] **Step 3: Build to confirm no compile errors**

Press `Cmd+B`. Expected: Build Succeeded with 0 errors.

If you see "extra argument 'festivals' in call" it means somewhere in the codebase `FestivalDiscoveryStore(festivals:)` is being called with mock data. Search for that and remove the argument — the fallback is now internal.

- [ ] **Step 4: Commit**

```bash
git add Encore/Stores/FestivalDiscoveryStore.swift
git commit -m "feat: wire FestivalDiscoveryStore to Supabase with mock fallback"
```

---

### Task 3: Verify in Simulator

- [ ] **Step 1: Run the app**

In Xcode select an iPhone simulator and press `Cmd+R`.

- [ ] **Step 2: Check Discover tab shows real festivals**

Navigate to the Discover tab. Expected: 5 festivals appear —
- Coachella 2026 (upcoming)
- Project Glow 2026 (upcoming)
- EDC Las Vegas 2026 (upcoming)
- Bonnaroo 2026 (upcoming)
- Ultra Miami 2026 (past)

They may take ~1 second to load; the list starts empty and populates.

- [ ] **Step 3: Check status filter pills**

Tap "Upcoming" pill — only Coachella, Project Glow, EDC, Bonnaroo appear.
Tap "Past" pill — only Ultra Miami appears.
Tap "All" — all 5 appear.

- [ ] **Step 4: Check camping filter**

Open the filter sheet. Set Type = "Camping". Expected: only Bonnaroo appears.
Set Type = "No Camping". Expected: Ultra Miami, EDC, Project Glow, Coachella appear.

- [ ] **Step 5: Check region filter**

Set Region = "West". Expected: EDC Las Vegas (NV) and Coachella (CA) appear.
Set Region = "Southeast". Expected: Bonnaroo (TN) appears.
Set Region = "Midwest". Expected: nothing (no midwest festivals seeded yet).

- [ ] **Step 6: Verify mock fallback (optional)**

In `FestivalDiscoveryStore.loadFestivals()`, temporarily throw before the fetch:
```swift
throw NSError(domain: "test", code: 0)
```
Run the app — Discover tab should show mock festivals instead of crashing. Revert after confirming.

- [ ] **Step 7: Final commit**

```bash
git add .
git commit -m "chore: verify Supabase Discover tab wiring complete"
```
