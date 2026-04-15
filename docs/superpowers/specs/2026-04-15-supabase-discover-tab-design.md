# Supabase Discover Tab — Design Spec
**Date:** 2026-04-15
**Scope:** Wire the Discover tab to fetch real festival data from Supabase instead of `Festival.mockFestivals`.

---

## Goal

The Discover tab (`FestivalDiscoveryStore`) currently loads from `Festival.mockFestivals` hardcoded in Swift. After this change it fetches live data from the `festivals` table in Supabase, with a mock fallback if the network is unavailable.

## Out of Scope

- Artist lineup data (festival.lineup stays `[]` for now — artist name filter in Discover won't match anything)
- Lineup tab / LineupStore wiring
- User auth / user_scheduled_sets
- Edge function deployment / real API ingestion

---

## Database (already done)

Schema created in Supabase project `ktauirvbnaluzwmaiynu`:

| Table | Purpose |
|-------|---------|
| `festivals` | Core festival rows; includes `latitude`, `longitude`, `is_camping` columns added via migration 002 |
| `artists` | Artist catalog (seeded, not yet surfaced in app) |
| `stages` | Per-festival stages (seeded, not yet surfaced in app) |
| `festival_sets` | Artist × festival × time rows (seeded, not yet surfaced in app) |
| `v_festival_sets_full` | Denormalised view for future lineup queries |
| `user_scheduled_sets` | Per-user schedule persistence (Phase 2) |
| `lineup_ingestion_log` | Ingestion audit log (Phase 2) |

Seeded festivals: Ultra Miami 2026, Bonnaroo 2026, EDC Las Vegas 2026, Project Glow 2026, Coachella 2026.

RLS: public anon read on all public tables. App uses the anon key only.

---

## iOS Changes

### `LineupService.swift` — add `fetchAllFestivals()`

`fetchFestivals()` already exists but filters `is_active = true AND end_date >= today`. This is correct for `FestivalStore` (user's active festival context), but `FestivalDiscoveryStore` needs past festivals too (e.g. Ultra Miami, which ended 2026-03-29).

Add a second method `fetchAllFestivals()` that uses the same query but omits the `end_date` filter. Both methods share the same DTO mapping logic.

### `FestivalDiscoveryStore.swift` — wire to Supabase

| Before | After |
|--------|-------|
| `init(festivals: [Festival] = Festival.mockFestivals)` | `init()` starts empty, kicks off async load |
| `allFestivals` seeded synchronously | `allFestivals` populated async from Supabase |
| No loading state | `@Published var isLoading: Bool` |

Behaviour:
- On init: `allFestivals = []`, `isLoading = true`, `Task { await loadFestivals() }`
- On success: `allFestivals = fetched`, `isLoading = false`
- On failure: `allFestivals = Festival.mockFestivals` (silent fallback), `isLoading = false`

`EncoreApp.swift` requires no changes — `discoveryStore` is already injected as `@StateObject`.

---

## Data Flow

```
EncoreApp
  └── @StateObject FestivalDiscoveryStore.init()
        └── Task { await loadFestivals() }
              └── LineupService.shared.fetchAllFestivals()
                    └── Supabase: SELECT * FROM festivals (no date filter)
                          ↓
                    [Festival] mapped from SupabaseFestivalRow
                          ↓
              → allFestivals = result   (or mockFestivals on error)
```

---

## What Stays the Same

- All filter logic in `FestivalDiscoveryStore.filteredFestivals` is unchanged
- `FestivalStore` and its `fetchFestivals()` call are unchanged
- `festival.lineup` stays `[]` — artist name filter in Discover won't match, but doesn't crash
- `festival.sets` stays `[]`
- Mock data remains in `MockData.swift` as fallback

---

## Testing

1. Run app — Discover tab shows 5 real festivals from Supabase
2. Status filter pills (All / Upcoming / Past) correctly categorise festivals by computed `status`
3. Camping filter: Bonnaroo shows under "Camping"; Ultra/EDC/Project Glow/Coachella show under "No Camping"
4. Region filter: festivals land in correct buckets based on lat/lng
5. Kill network → app falls back to mock festivals without crashing
