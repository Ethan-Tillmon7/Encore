# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Encore is an iOS festival companion app (targeting Bonnaroo) built with SwiftUI. It helps festival-goers discover artists, build a personal schedule, coordinate with a crew, and navigate the venue. The app currently runs entirely on mock data.

## Build & Run

This project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) — the `.xcodeproj` is generated, not committed.

```bash
# Install XcodeGen (one-time)
brew install xcodegen

# Regenerate the Xcode project after changing project.yml
xcodegen generate

# Open in Xcode
open Encore.xcodeproj
```

Run via Xcode: select an iPhone simulator and press `Cmd+R`. There is no CLI build or test runner configured.

> **After any change to `project.yml`** (adding files, packages, build settings), run `xcodegen generate` before building in Xcode.

## Architecture

**Stores → Views pattern** using `@EnvironmentObject`. All three stores are instantiated in `EncoreApp.swift` and injected at the root — any view can access them without prop drilling.

| Store | Owns |
|-------|------|
| `ScheduleStore` | User's scheduled sets, conflict detection/resolution |
| `DiscoverStore` | Full lineup, filters (day/tier/search), Spotify connection state |
| `CrewStore` | Crew membership, meetup pins, merged timeline helpers |

**Models** are plain value types (`struct`), all `Codable` and `Hashable`. Core types:
- `FestivalSet` — a set has one `Artist`, a `FestivalDay`, a stage, and start/end `Date`s
- `Artist` — carries a `MatchTier` (mustSee / worthChecking / explore / unknown) and optional Spotify match score (0–100)
- `SetConflict` — computed from `ScheduleStore.conflicts`; wraps two overlapping `FestivalSet`s

**Mock data** lives entirely in `MockData.swift` (12 artists, 10 sets, 4 crew members). `DiscoverStore.allSets` is initialized from `FestivalSet.mockSets`. `CrewStore.crew` is initialized from `Crew.mockCrew`.

## Key Constraints

- **iOS 16 target** — use `@ObservableObject`/`@Published` (not `@Observable`), and `Map(coordinateRegion:)` (not the iOS 17 Map API). Do not upgrade to iOS 17+ APIs without changing the deployment target in `project.yml`.
- **Dark mode only** — forced in `EncoreApp.swift` via `.preferredColorScheme(.dark)`. Do not add light-mode styling.
- **No persistence yet** — `ScheduleStore.scheduledSets` is in-memory only. Persistence (UserDefaults or SQLite) is a planned Phase 1 item.
- **No backend yet** — Spotify OAuth (`connectSpotify()`) and Supabase integration (`joinCrew(code:)`) are stubbed with `TODO` comments. Do not add real network calls without first wiring up the backend infrastructure.
- **No SPM packages yet** — `project.yml` has Supabase commented out. Add packages there (not via Xcode's UI) so XcodeGen can manage them.

## What's Next

**Phase 1 (local):** Spotify OAuth via `ASWebAuthenticationSession`, real Bonnaroo lineup data via Supabase, persist `scheduledSets`, real setlist.fm API calls, offline map tile caching.

**Phase 2 (realtime):** `CrewStore` → Supabase Realtime for live schedule sync, `CoreLocation` + Supabase presence for location sharing, QR code invite flow, group chat.
