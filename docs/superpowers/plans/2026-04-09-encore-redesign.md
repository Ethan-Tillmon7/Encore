# Encore Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Encore's 4-tab app with a 2-tab (Home + Profile) structure, a new forest-green/mint color system, a full timetable grid Lineup screen, and a simplified Home hub with group card, trip card, and embedded schedule.

**Architecture:** Keep the three existing `@EnvironmentObject` stores (renaming `DiscoverStore` → `LineupStore`). Replace all views. Add an `AppColors.swift` token layer. Theme preference stored via `@AppStorage` — no forced dark mode.

**Tech Stack:** SwiftUI, iOS 16, MapKit, XcodeGen (`project.yml`). No test target is configured — verification is build success (`Cmd+B`) + SwiftUI `#Preview` + simulator run.

---

## File Map

### Create
| Path | Responsibility |
|------|---------------|
| `Encore/AppColors.swift` | All adaptive color tokens as `Color` + `UIColor` extensions |
| `Encore/Views/RootView.swift` | 2-tab `TabView` (Home + Profile) — replaces `MainTabView` |
| `Encore/Views/Home/HomeView.swift` | Full home hub: header, group card, trip card, lineup button, schedule |
| `Encore/Views/Lineup/LineupView.swift` | Day picker + `TimetableGridView` shell |
| `Encore/Views/Lineup/TimetableGridView.swift` | Scrollable 2-axis timetable grid with positioned set blocks |
| `Encore/Views/Lineup/SetBlockView.swift` | Individual set block rendered inside the grid |
| `Encore/Views/Profile/ProfileView.swift` | Settings list: theme picker, notifications, legal, sign out |
| `Encore/Stores/LineupStore.swift` | Renamed copy of `DiscoverStore` with class name `LineupStore` |

### Modify
| Path | Changes |
|------|---------|
| `Encore/EncoreApp.swift` | Use `LineupStore`, add `@AppStorage` theme, drive `preferredColorScheme` |
| `Encore/Models/Artist.swift` | Update `MatchTier.color`, `backgroundColor` to use app tokens |
| `Encore/Views/Shared/ArtistDetailView.swift` | Token colors, add "Directions to [Stage]" `NavigationLink` |
| `Encore/Views/Shared/ArtistCardView.swift` | Token colors only |
| `Encore/Views/Schedule/ConflictResolverView.swift` | Token colors only |
| `Encore/Views/Map/FestivalMapView.swift` | Add `initialStage: String?` param, token colors |

### Delete (after all other tasks pass build)
| Path |
|------|
| `Encore/Views/Discover/DiscoverView.swift` |
| `Encore/Views/Schedule/MyScheduleView.swift` |
| `Encore/Views/Crew/CrewView.swift` |
| `Encore/Views/MainTabView.swift` |
| `Encore/Stores/DiscoverStore.swift` |

---

## Task 1: Color Token System

**Files:**
- Create: `Encore/AppColors.swift`

- [ ] **Step 1: Create `AppColors.swift`**

```swift
// Encore/AppColors.swift
import SwiftUI

// MARK: - SwiftUI Color tokens

extension Color {
    static let appBackground  = Color(uiColor: .appBackground)
    static let appSurface     = Color(uiColor: .appSurface)
    static let appAccent      = Color(uiColor: .appAccent)
    static let appCTA         = Color(uiColor: .appCTA)
    static let appTeal        = Color(uiColor: .appTeal)
    static let appTextPrimary = Color(uiColor: .appTextPrimary)
    static let appTextMuted   = Color(uiColor: .appTextMuted)
}

// MARK: - UIColor adaptive tokens

extension UIColor {
    static let appBackground = UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(appHex: "1C2522") : UIColor(appHex: "FAFDE6")
    }
    static let appSurface = UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(appHex: "2A332F") : UIColor(appHex: "FFFFF0")
    }
    static let appAccent      = UIColor(appHex: "A8BFB2")
    static let appCTA         = UIColor(appHex: "E8F7D0")
    static let appTeal        = UIColor(appHex: "D4ECEC")
    static let appTextPrimary = UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(appHex: "EAEAEF") : UIColor(appHex: "202030")
    }
    static let appTextMuted   = UIColor(appHex: "A8BFB2")

    convenience init(appHex: String) {
        let val = UInt64(appHex, radix: 16) ?? 0
        let r = CGFloat((val & 0xFF0000) >> 16) / 255
        let g = CGFloat((val & 0x00FF00) >> 8)  / 255
        let b = CGFloat(val & 0x0000FF)          / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
```

- [ ] **Step 2: Build to verify no errors**

Open the project in Xcode and press `Cmd+B`. Expected: build succeeds. The `UIColor(appHex:)` convenience init has a different name from the existing `Color(hex:)` in `Crew.swift` so there is no conflict.

- [ ] **Step 3: Commit**

```bash
git add Encore/AppColors.swift
git commit -m "feat: add adaptive color token system"
```

---

## Task 2: Update `MatchTier` colors to use tokens

**Files:**
- Modify: `Encore/Models/Artist.swift`

- [ ] **Step 1: Replace the `color` and `backgroundColor` computed properties**

In `Artist.swift`, replace the entire `MatchTier` enum's `color` and `backgroundColor` properties:

```swift
// Replace the existing color and backgroundColor properties with:

var color: Color {
    switch self {
    case .mustSee:       return .appCTA
    case .worthChecking: return .appAccent
    case .explore:       return .appTeal
    case .unknown:       return .appTextMuted
    }
}

var backgroundColor: Color {
    color.opacity(0.18)
}

// Add these two new properties for the timetable grid blocks:

var blockFill: Color   { color.opacity(0.18) }
var blockBorder: Color { color.opacity(0.32) }
```

- [ ] **Step 2: Build (`Cmd+B`)**

Expected: build succeeds. `MatchTier.color` is used in `ArtistCardView`, `ArtistDetailView`, `ConflictResolverView` — all should still compile since the property name is unchanged.

- [ ] **Step 3: Commit**

```bash
git add Encore/Models/Artist.swift
git commit -m "feat: map MatchTier colors to app token system"
```

---

## Task 3: Create `LineupStore`

**Files:**
- Create: `Encore/Stores/LineupStore.swift`

- [ ] **Step 1: Create `LineupStore.swift`** (copy of `DiscoverStore` with the class renamed)

```swift
// Encore/Stores/LineupStore.swift
import Foundation
import Combine

class LineupStore: ObservableObject {

    @Published var allSets: [FestivalSet] = FestivalSet.mockSets

    @Published var selectedDay: FestivalDay? = nil
    @Published var selectedTier: MatchTier? = nil
    @Published var searchText: String = ""

    @Published var isSpotifyConnected: Bool = false

    var filteredSets: [FestivalSet] {
        allSets
            .filter { set in
                if let day = selectedDay { return set.day == day }
                return true
            }
            .filter { set in
                if let tier = selectedTier { return set.artist.matchTier == tier }
                return true
            }
            .filter { set in
                guard !searchText.isEmpty else { return true }
                return set.artist.name.localizedCaseInsensitiveContains(searchText)
            }
            .sorted { a, b in
                let scoreA = a.artist.spotifyMatchScore ?? -1
                let scoreB = b.artist.spotifyMatchScore ?? -1
                if scoreA != scoreB { return scoreA > scoreB }
                return a.artist.name < b.artist.name
            }
    }

    func connectSpotify() {
        // TODO: Implement Spotify OAuth (Phase 1)
        isSpotifyConnected = true
    }

    func disconnectSpotify() {
        isSpotifyConnected = false
        allSets = allSets.map { set in
            var updated = set
            updated.artist.spotifyMatchScore = nil
            updated.artist.playCountLastSixMonths = nil
            updated.artist.matchTier = .unknown
            return updated
        }
    }
}
```

- [ ] **Step 2: Build (`Cmd+B`)**

Expected: build succeeds. `DiscoverStore` still exists — no conflicts yet.

- [ ] **Step 3: Commit**

```bash
git add Encore/Stores/LineupStore.swift
git commit -m "feat: add LineupStore (renamed DiscoverStore)"
```

---

## Task 4: Update `EncoreApp.swift`

**Files:**
- Modify: `Encore/EncoreApp.swift`

- [ ] **Step 1: Replace the entire file contents**

```swift
// Encore/EncoreApp.swift
import SwiftUI

@main
struct EncoreApp: App {

    @StateObject private var scheduleStore = ScheduleStore()
    @StateObject private var lineupStore   = LineupStore()
    @StateObject private var crewStore     = CrewStore()

    @AppStorage("appTheme") private var appTheme: String = "system"

    private var preferredColorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil   // system
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(scheduleStore)
                .environmentObject(lineupStore)
                .environmentObject(crewStore)
                .preferredColorScheme(preferredColorScheme)
        }
    }
}
```

`RootView` does not exist yet — the build will fail until Task 5 is complete. That's fine; keep going.

- [ ] **Step 2: Commit**

```bash
git add Encore/EncoreApp.swift
git commit -m "feat: wire LineupStore and AppStorage theme in EncoreApp"
```

---

## Task 5: Create `RootView` (2-tab nav)

**Files:**
- Create: `Encore/Views/RootView.swift`

- [ ] **Step 1: Create `RootView.swift`**

```swift
// Encore/Views/RootView.swift
import SwiftUI

struct RootView: View {

    @State private var selectedTab: Tab = .home

    enum Tab: Int { case home, profile }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }
                .tag(Tab.home)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.circle") }
                .tag(Tab.profile)
        }
        .tint(.appCTA)
    }
}

#Preview {
    RootView()
        .environmentObject(ScheduleStore())
        .environmentObject(LineupStore())
        .environmentObject(CrewStore())
}
```

`HomeView` and `ProfileView` don't exist yet — build will still fail. Continue.

- [ ] **Step 2: Commit**

```bash
git add Encore/Views/RootView.swift
git commit -m "feat: add 2-tab RootView shell"
```

---

## Task 6: Create `ProfileView`

**Files:**
- Create: `Encore/Views/Profile/ProfileView.swift`

- [ ] **Step 1: Create the directory and file**

```bash
mkdir -p /path/to/Encore/Encore/Views/Profile
```

```swift
// Encore/Views/Profile/ProfileView.swift
import SwiftUI

struct ProfileView: View {

    @AppStorage("appTheme") private var appTheme: String = "system"

    var body: some View {
        NavigationView {
            List {

                // Profile header
                Section {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.appSurface)
                            .frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.appAccent)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Your Name")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.appTextPrimary)
                            Button("Edit Profile") {}
                                .font(.system(size: 13))
                                .foregroundColor(.appAccent)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .listRowBackground(Color.appSurface)

                // Preferences
                Section("Preferences") {
                    HStack {
                        Label("Theme", systemImage: "circle.lefthalf.filled")
                            .foregroundColor(.appTextPrimary)
                        Spacer()
                        Picker("Theme", selection: $appTheme) {
                            Text("System").tag("system")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                    }

                    Label("Notifications", systemImage: "bell")
                        .foregroundColor(.appTextPrimary)
                }
                .listRowBackground(Color.appSurface)

                // Legal & Support
                Section("Legal & Support") {
                    Label("Privacy & Security", systemImage: "lock.shield")
                        .foregroundColor(.appTextPrimary)
                    Label("Help Center", systemImage: "questionmark.circle")
                        .foregroundColor(.appTextPrimary)
                    Label("Terms of Service", systemImage: "doc.text")
                        .foregroundColor(.appTextPrimary)
                }
                .listRowBackground(Color.appSurface)

                // Sign out
                Section {
                    Button(role: .destructive, action: {}) {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
                .listRowBackground(Color.appSurface)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .tint(.appCTA)
        }
    }
}

#Preview {
    ProfileView()
        .preferredColorScheme(.dark)
}
```

- [ ] **Step 2: Commit**

```bash
git add Encore/Views/Profile/ProfileView.swift
git commit -m "feat: add ProfileView with theme picker and settings list"
```

---

## Task 7: Create `HomeView`

**Files:**
- Create: `Encore/Views/Home/HomeView.swift`

- [ ] **Step 1: Create the directory and file**

```bash
mkdir -p /path/to/Encore/Encore/Views/Home
```

```swift
// Encore/Views/Home/HomeView.swift
import SwiftUI

struct HomeView: View {

    @EnvironmentObject var scheduleStore: ScheduleStore
    @EnvironmentObject var lineupStore:   LineupStore
    @EnvironmentObject var crewStore:     CrewStore

    @State private var selectedDay:   FestivalDay  = .thursday
    @State private var activeConflict: SetConflict? = nil
    @State private var selectedSet:   FestivalSet? = nil
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    festivalHeader
                    groupCard
                    tripCard
                    lineupButton
                    scheduleSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(Color.appBackground)
            .navigationDestination(for: String.self) { destination in
                if destination == "lineup" {
                    LineupView()
                        .environmentObject(lineupStore)
                        .environmentObject(scheduleStore)
                        .environmentObject(crewStore)
                }
            }
            .sheet(item: $selectedSet) { set in
                ArtistDetailView(festivalSet: set)
                    .environmentObject(scheduleStore)
                    .environmentObject(crewStore)
            }
            .sheet(item: $activeConflict) { conflict in
                ConflictResolverView(conflict: conflict)
                    .environmentObject(scheduleStore)
                    .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Festival Header

    private var festivalHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Bonnaroo '25")
                .font(.system(size: 28, weight: .heavy))
                .foregroundColor(.appCTA)
            Text("June 12–15  ·  Manchester, TN")
                .font(.system(size: 13))
                .foregroundColor(.appTextMuted)
        }
        .padding(.top, 4)
    }

    // MARK: - Group Card

    @ViewBuilder
    private var groupCard: some View {
        if let crew = crewStore.crew {
            crewCardView(crew: crew)
        } else {
            noCrewCardView
        }
    }

    private var noCrewCardView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FESTIVAL GROUP")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.appTextMuted)
                .tracking(0.6)
            Text("No group yet")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.appTextPrimary)
            HStack(spacing: 10) {
                Button("Start a Group") {}
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Color.appCTA.opacity(0.15))
                    .foregroundColor(.appCTA)
                    .clipShape(Capsule())
                Button("Join with Code") {}
                    .font(.system(size: 13))
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Color.appSurface)
                    .foregroundColor(.appTextMuted)
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(Color.appAccent.opacity(0.18), lineWidth: 1))
    }

    private func crewCardView(crew: Crew) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("FESTIVAL GROUP")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.appTextMuted)
                        .tracking(0.6)
                    Text(crew.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.appCTA)
                }
                Spacer()
                Button(action: {}) {
                    Text("+ Invite")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.appAccent)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .overlay(RoundedRectangle(cornerRadius: 7)
                            .stroke(Color.appAccent.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            HStack(spacing: 14) {
                ForEach(crew.members) { member in
                    memberBubble(member: member)
                }
            }
        }
        .padding(14)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(Color.appAccent.opacity(0.18), lineWidth: 1))
    }

    private func memberBubble(member: CrewMember) -> some View {
        VStack(spacing: 4) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(member.color)
                    .frame(width: 38, height: 38)
                    .overlay(
                        Text(member.initials)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.appBackground)
                    )
                Circle()
                    .fill(member.isOnline ? Color.appCTA : Color.appTextMuted.opacity(0.4))
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(Color.appSurface, lineWidth: 1.5))
            }
            Text(member.name)
                .font(.system(size: 9))
                .foregroundColor(.appTextMuted)
        }
    }

    // MARK: - Trip Card

    private var tripCard: some View {
        HStack(spacing: 0) {
            tripColumn(icon: "airplane",          label: "Travel",   detail: "Fri 8 AM")
            Divider().frame(height: 36)
            tripColumn(icon: "backpack",           label: "Packing",  detail: "0 / 0")
            Divider().frame(height: 36)
            tripColumn(icon: "dollarsign.circle",  label: "Expenses", detail: "$0 / person")
        }
        .padding(.vertical, 12)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(Color.appAccent.opacity(0.18), lineWidth: 1))
    }

    private func tripColumn(icon: String, label: String, detail: String) -> some View {
        Button(action: {}) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(.appAccent)
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                Text(detail)
                    .font(.system(size: 10))
                    .foregroundColor(.appTextMuted)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Lineup Button

    private var lineupButton: some View {
        Button(action: { navigationPath.append("lineup") }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Browse Full Lineup")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appCTA)
                    Text("\(lineupStore.allSets.count) artists")
                        .font(.system(size: 12))
                        .foregroundColor(.appTextMuted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.appCTA)
            }
            .padding(14)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(Color.appCTA.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Schedule Section

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("MY SCHEDULE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.appTextMuted)
                    .tracking(0.8)
                Spacer()
                dayPicker
            }

            if scheduleStore.hasConflicts {
                conflictBanner
            }

            let sets = scheduleStore.sets(for: selectedDay)
            if sets.isEmpty {
                emptySchedule
            } else {
                ForEach(sets) { set in
                    scheduleRow(set: set)
                }
            }
        }
    }

    private var dayPicker: some View {
        HStack(spacing: 4) {
            ForEach(FestivalDay.allCases) { day in
                Button(action: { selectedDay = day }) {
                    Text(day.rawValue)
                        .font(.system(size: 11, weight: selectedDay == day ? .bold : .regular))
                        .foregroundColor(selectedDay == day ? .appCTA : .appTextMuted)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(selectedDay == day
                            ? Color.appCTA.opacity(0.15) : Color.clear)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var conflictBanner: some View {
        let conflicts = scheduleStore.conflicts
        return Button(action: { activeConflict = conflicts.first }) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("\(conflicts.count) conflict\(conflicts.count == 1 ? "" : "s") — tap to resolve")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.appTextPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.appTextMuted)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Color.orange.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func scheduleRow(set: FestivalSet) -> some View {
        let isConflicted = scheduleStore.conflicts.contains {
            $0.setA.id == set.id || $0.setB.id == set.id
        }
        return Button(action: { selectedSet = set }) {
            HStack(spacing: 12) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(timeLabel(set.startTime))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.appTextMuted)
                    Text(timeLabel(set.endTime))
                        .font(.system(size: 10))
                        .foregroundColor(Color.appTextMuted.opacity(0.6))
                }
                .frame(width: 44, alignment: .trailing)

                RoundedRectangle(cornerRadius: 2)
                    .fill(isConflicted ? Color.orange : set.artist.matchTier.color)
                    .frame(width: 3, height: 44)

                VStack(alignment: .leading, spacing: 3) {
                    Text(set.artist.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appTextPrimary)
                    Text(set.stageName)
                        .font(.system(size: 12))
                        .foregroundColor(.appTextMuted)
                }
                Spacer()

                if isConflicted {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 15))
                }

                Button(action: { scheduleStore.remove(set) }) {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 20))
                        .foregroundColor(Color.appTextMuted.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 13).padding(.vertical, 11)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(isConflicted ? Color.orange.opacity(0.4) : Color.clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var emptySchedule: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 32))
                .foregroundColor(Color.appTextMuted.opacity(0.4))
            Text("Nothing scheduled for \(selectedDay.fullName)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.appTextMuted)
            Text("Browse the lineup to add sets")
                .font(.system(size: 12))
                .foregroundColor(Color.appTextMuted.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private func timeLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm"
        return f.string(from: date)
    }
}

#Preview {
    let schedule = ScheduleStore()
    schedule.add(FestivalSet.mockSets[4])
    schedule.add(FestivalSet.mockSets[5])
    return HomeView()
        .environmentObject(schedule)
        .environmentObject(LineupStore())
        .environmentObject(CrewStore())
        .preferredColorScheme(.dark)
}
```

- [ ] **Step 2: Build (`Cmd+B`)**

`LineupView` doesn't exist yet — the build will fail on that reference. That's expected. Comment out the `navigationDestination` block temporarily if you want an incremental build check:

```swift
// .navigationDestination(for: String.self) { destination in
//     if destination == "lineup" { ... }
// }
```

- [ ] **Step 3: Commit**

```bash
git add Encore/Views/Home/HomeView.swift
git commit -m "feat: add HomeView with group card, trip card, lineup button, and schedule"
```

---

## Task 8: Create `SetBlockView`

**Files:**
- Create: `Encore/Views/Lineup/SetBlockView.swift`

- [ ] **Step 1: Create the directory and file**

```bash
mkdir -p /path/to/Encore/Encore/Views/Lineup
```

```swift
// Encore/Views/Lineup/SetBlockView.swift
import SwiftUI

struct SetBlockView: View {

    let set: FestivalSet
    let height: CGFloat
    let isAdded: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 6)
                .fill(set.artist.matchTier.blockFill)
            RoundedRectangle(cornerRadius: 6)
                .stroke(set.artist.matchTier.blockBorder,
                        lineWidth: isAdded ? 1.5 : 0.8)

            VStack(alignment: .leading, spacing: 2) {
                Text(set.artist.name)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(set.artist.matchTier.color)
                    .lineLimit(2)

                if height > 52 {
                    Text(timeLabel(set.startTime))
                        .font(.system(size: 8))
                        .foregroundColor(set.artist.matchTier.color.opacity(0.7))
                }
            }
            .padding(4)

            if isAdded {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(set.artist.matchTier.color)
                    .frame(maxWidth: .infinity, maxHeight: .infinity,
                           alignment: .bottomTrailing)
                    .padding(3)
            }
        }
        .frame(height: max(height - 4, 20))
    }

    private func timeLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm"
        return f.string(from: date)
    }
}
```

- [ ] **Step 2: Build (`Cmd+B`)**

Expected: succeeds. `blockFill` and `blockBorder` were added to `MatchTier` in Task 2.

- [ ] **Step 3: Commit**

```bash
git add Encore/Views/Lineup/SetBlockView.swift
git commit -m "feat: add SetBlockView for timetable grid"
```

---

## Task 9: Create `TimetableGridView`

**Files:**
- Create: `Encore/Views/Lineup/TimetableGridView.swift`

- [ ] **Step 1: Create `TimetableGridView.swift`**

```swift
// Encore/Views/Lineup/TimetableGridView.swift
import SwiftUI

struct TimetableGridView: View {

    let sets: [FestivalSet]
    let stages: [String]
    let scheduledSetIDs: Set<UUID>
    var onSetTap: (FestivalSet) -> Void
    var onStageTap: (String) -> Void

    // Layout constants
    private let rowHeight:       CGFloat = 44   // per 30-min slot
    private let columnWidth:     CGFloat = 110
    private let timeColumnWidth: CGFloat = 36
    private let headerHeight:    CGFloat = 30

    // MARK: - Derived geometry

    private var dayStart: Date {
        guard let earliest = sets.map(\.startTime).min() else { return Date() }
        // Floor to the nearest hour
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour], from: earliest)
        return Calendar.current.date(from: comps) ?? earliest
    }

    private var dayEnd: Date {
        sets.map(\.endTime).max() ?? Date()
    }

    private var totalMinutes: Int {
        max(Int(dayEnd.timeIntervalSince(dayStart)) / 60, 30)
    }

    private var rowCount: Int {
        Int(ceil(Double(totalMinutes) / 30.0))
    }

    private var totalWidth: CGFloat {
        timeColumnWidth + CGFloat(stages.count) * columnWidth
    }

    private var totalHeight: CGFloat {
        headerHeight + CGFloat(rowCount) * rowHeight
    }

    // MARK: - Body

    var body: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                // Canvas background
                Color.appBackground
                    .frame(width: totalWidth, height: totalHeight)

                // Horizontal grid lines (one per 30-min row)
                ForEach(0 ..< rowCount, id: \.self) { row in
                    Rectangle()
                        .fill(Color.appAccent.opacity(row % 2 == 0 ? 0.08 : 0.04))
                        .frame(width: totalWidth, height: 1)
                        .offset(y: headerHeight + CGFloat(row) * rowHeight)
                }

                // Vertical stage dividers
                ForEach(0 ..< stages.count, id: \.self) { col in
                    Rectangle()
                        .fill(Color.appAccent.opacity(0.08))
                        .frame(width: 1, height: totalHeight)
                        .offset(x: timeColumnWidth + CGFloat(col) * columnWidth)
                }

                // Stage column headers (tappable → map)
                ForEach(Array(stages.enumerated()), id: \.offset) { idx, stage in
                    Button(action: { onStageTap(stage) }) {
                        Text(stage)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.appCTA)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(width: columnWidth, height: headerHeight)
                    }
                    .buttonStyle(.plain)
                    .offset(x: timeColumnWidth + CGFloat(idx) * columnWidth)
                }

                // Time labels (every hour)
                ForEach(0 ..< rowCount, id: \.self) { row in
                    if row % 2 == 0 {
                        Text(hourLabel(minuteOffset: row * 30))
                            .font(.system(size: 8))
                            .foregroundColor(.appTextMuted)
                            .frame(width: timeColumnWidth - 4, alignment: .trailing)
                            .offset(x: 0,
                                    y: headerHeight + CGFloat(row) * rowHeight - 6)
                    }
                }

                // Set blocks
                ForEach(sets) { set in
                    let pos = blockOrigin(for: set)
                    let h   = blockHeight(for: set)
                    let added = scheduledSetIDs.contains(set.id)

                    Button(action: { onSetTap(set) }) {
                        SetBlockView(set: set, height: h, isAdded: added)
                    }
                    .buttonStyle(.plain)
                    .frame(width: columnWidth - 4)
                    .offset(x: pos.x + 2, y: pos.y + 2)
                }
            }
            .frame(width: totalWidth, height: totalHeight)
        }
    }

    // MARK: - Helpers

    private func blockOrigin(for set: FestivalSet) -> CGPoint {
        let stageIdx = stages.firstIndex(of: set.stageName) ?? 0
        let x = timeColumnWidth + CGFloat(stageIdx) * columnWidth
        let minsFromStart = Int(set.startTime.timeIntervalSince(dayStart)) / 60
        let y = headerHeight + CGFloat(minsFromStart) / 30.0 * rowHeight
        return CGPoint(x: x, y: y)
    }

    private func blockHeight(for set: FestivalSet) -> CGFloat {
        CGFloat(set.durationMinutes) / 30.0 * rowHeight
    }

    private func hourLabel(minuteOffset: Int) -> String {
        let date = Date(timeInterval: Double(minuteOffset * 60), since: dayStart)
        let f = DateFormatter()
        f.dateFormat = "h a"
        return f.string(from: date)
    }
}

#Preview {
    let sets = FestivalSet.mockSets.filter { $0.day == .saturday }
    let stages = Array(Set(sets.map { $0.stageName })).sorted()
    return TimetableGridView(
        sets: sets,
        stages: stages,
        scheduledSetIDs: [sets[0].id],
        onSetTap: { _ in },
        onStageTap: { _ in }
    )
    .frame(height: 500)
    .preferredColorScheme(.dark)
}
```

- [ ] **Step 2: Build (`Cmd+B`)**

Expected: succeeds.

- [ ] **Step 3: Check the `#Preview`**

Open `TimetableGridView.swift` in Xcode and verify the preview renders: stage headers across the top, time labels on the left, set blocks positioned as colored rectangles. Saturday data shows LCD Soundsystem and ODESZA overlapping — both should appear as distinct blocks in their respective columns.

- [ ] **Step 4: Commit**

```bash
git add Encore/Views/Lineup/TimetableGridView.swift
git commit -m "feat: add TimetableGridView with 2-axis scroll and positioned set blocks"
```

---

## Task 10: Create `LineupView`

**Files:**
- Create: `Encore/Views/Lineup/LineupView.swift`

- [ ] **Step 1: Create `LineupView.swift`**

```swift
// Encore/Views/Lineup/LineupView.swift
import SwiftUI

struct LineupView: View {

    @EnvironmentObject var lineupStore:   LineupStore
    @EnvironmentObject var scheduleStore: ScheduleStore
    @EnvironmentObject var crewStore:     CrewStore

    @State private var selectedDay:   FestivalDay = .thursday
    @State private var selectedSet:   FestivalSet? = nil
    @State private var selectedStage: String?      = nil

    private var stages: [String] {
        Array(Set(lineupStore.allSets.map { $0.stageName })).sorted()
    }

    private var setsForDay: [FestivalSet] {
        lineupStore.allSets.filter { $0.day == selectedDay }
    }

    private var scheduledIDs: Set<UUID> {
        Set(scheduleStore.scheduledSets.map { $0.id })
    }

    var body: some View {
        VStack(spacing: 0) {
            dayPicker
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.appBackground)

            TimetableGridView(
                sets: setsForDay,
                stages: stages,
                scheduledSetIDs: scheduledIDs,
                onSetTap:   { selectedSet   = $0 },
                onStageTap: { selectedStage = $0 }
            )
        }
        .background(Color.appBackground)
        .navigationTitle("Lineup")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedSet) { set in
            ArtistDetailView(festivalSet: set)
                .environmentObject(scheduleStore)
                .environmentObject(crewStore)
        }
        .navigationDestination(
            isPresented: Binding(
                get: { selectedStage != nil },
                set: { if !$0 { selectedStage = nil } }
            )
        ) {
            FestivalMapView(initialStage: selectedStage)
                .environmentObject(scheduleStore)
                .environmentObject(crewStore)
        }
    }

    private var dayPicker: some View {
        HStack(spacing: 0) {
            ForEach(FestivalDay.allCases) { day in
                Button(action: { selectedDay = day }) {
                    Text(day.fullName)
                        .font(.system(size: 13, weight: selectedDay == day ? .bold : .regular))
                        .foregroundColor(selectedDay == day ? .appCTA : .appTextMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selectedDay == day
                            ? Color.appCTA.opacity(0.12) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    NavigationStack {
        LineupView()
            .environmentObject(LineupStore())
            .environmentObject(ScheduleStore())
            .environmentObject(CrewStore())
    }
    .preferredColorScheme(.dark)
}
```

- [ ] **Step 2: Re-enable the `navigationDestination` in `HomeView`**

Open `HomeView.swift` and uncomment (or restore) the `navigationDestination` block if it was temporarily commented out in Task 7 Step 2.

- [ ] **Step 3: Build (`Cmd+B`)**

`FestivalMapView` now needs an `initialStage` parameter — the build may fail here. That's addressed in Task 12. Temporarily add a default value to the existing `FestivalMapView` init if you need an incremental build:

In `FestivalMapView.swift`, add at the top of the struct:
```swift
var initialStage: String? = nil
```

This won't crash because `onAppear` logic hasn't been added yet.

- [ ] **Step 4: Commit**

```bash
git add Encore/Views/Lineup/LineupView.swift
git commit -m "feat: add LineupView with day picker and timetable grid"
```

---

## Task 11: Update `FestivalMapView`

**Files:**
- Modify: `Encore/Views/Map/FestivalMapView.swift`

- [ ] **Step 1: Add `initialStage` parameter and token colors**

Replace the entire file content:

```swift
// Encore/Views/Map/FestivalMapView.swift
import SwiftUI
import MapKit

private let bonnarooCenter = CLLocationCoordinate2D(latitude: 35.4897, longitude: -86.0814)

struct FestivalMapView: View {

    var initialStage: String? = nil

    @EnvironmentObject var scheduleStore: ScheduleStore
    @EnvironmentObject var crewStore:     CrewStore

    @State private var region = MKCoordinateRegion(
        center: bonnarooCenter,
        span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
    )
    @State private var showAmenities  = false
    @State private var selectedStage: StageAnnotation? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(coordinateRegion: $region, annotationItems: visibleAnnotations) { ann in
                MapAnnotation(coordinate: ann.coordinate) {
                    stageMarker(annotation: ann)
                }
            }
            .ignoresSafeArea(edges: .top)

            VStack(spacing: 0) {
                mapControls
                if let stage = selectedStage {
                    stageInfoCard(stage: stage)
                }
            }
            .padding(.bottom, 8)
        }
        .navigationTitle("Map")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { crewStore.isLocationSharingEnabled.toggle() }) {
                    Image(systemName: crewStore.isLocationSharingEnabled
                          ? "location.fill" : "location")
                        .foregroundColor(crewStore.isLocationSharingEnabled
                                         ? .appCTA : .appTextMuted)
                }
            }
        }
        .onAppear {
            if let name = initialStage,
               let match = StageAnnotation.bonnarooStages.first(where: {
                   $0.name == name || $0.shortName == name
               }) {
                region.center = match.coordinate
                selectedStage = match
            }
        }
    }

    private var visibleAnnotations: [StageAnnotation] {
        var list = StageAnnotation.bonnarooStages
        if showAmenities { list += StageAnnotation.amenities }
        return list
    }

    private func stageMarker(annotation: StageAnnotation) -> some View {
        Button(action: {
            selectedStage = selectedStage?.id == annotation.id ? nil : annotation
        }) {
            VStack(spacing: 3) {
                ZStack {
                    Circle()
                        .fill(annotation.kind == .stage ? Color.appCTA : Color.appTeal)
                        .frame(width: annotation.kind == .stage ? 36 : 24,
                               height: annotation.kind == .stage ? 36 : 24)
                    Image(systemName: annotation.kind.icon)
                        .font(.system(size: annotation.kind == .stage ? 14 : 10))
                        .foregroundColor(Color.appBackground)
                }
                Text(annotation.shortName)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                    .shadow(radius: 2)
            }
        }
        .buttonStyle(.plain)
    }

    private var mapControls: some View {
        HStack {
            Button(action: { showAmenities.toggle() }) {
                Label(showAmenities ? "Hide Amenities" : "Show Amenities",
                      systemImage: showAmenities ? "eye.slash" : "mappin.and.ellipse")
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 14).padding(.vertical, 9)
                    .background(Color.appSurface)
                    .foregroundColor(.appTextPrimary)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            Spacer()
            if let crew = crewStore.crew {
                HStack(spacing: -6) {
                    ForEach(crew.members.filter { $0.isOnline }.prefix(4)) { member in
                        Circle()
                            .fill(member.color)
                            .frame(width: 26, height: 26)
                            .overlay(Circle().stroke(Color.appBackground, lineWidth: 1.5))
                            .overlay(
                                Text(String(member.initials.prefix(1)))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color.appBackground)
                            )
                    }
                }
            }
        }
        .padding(.horizontal, 16).padding(.bottom, 8)
    }

    private func stageInfoCard(stage: StageAnnotation) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(stage.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                Spacer()
                Button(action: { selectedStage = nil }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.appTextMuted)
                }
            }
            if let current = stage.currentAct {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("NOW PLAYING")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.appCTA)
                        Text(current)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.appTextPrimary)
                    }
                    Spacer()
                    Label("~8 min walk", systemImage: "figure.walk")
                        .font(.system(size: 12))
                        .foregroundColor(.appTextMuted)
                }
            }
            if let next = stage.nextAct {
                Text("Up next: \(next)")
                    .font(.system(size: 13))
                    .foregroundColor(.appTextMuted)
            }
        }
        .padding(16)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
        .shadow(color: .black.opacity(0.2), radius: 8, y: 2)
    }
}

#Preview {
    FestivalMapView(initialStage: "What Stage")
        .environmentObject(ScheduleStore())
        .environmentObject(CrewStore())
        .preferredColorScheme(.dark)
}
```

- [ ] **Step 2: Build (`Cmd+B`)**

Expected: succeeds.

- [ ] **Step 3: Commit**

```bash
git add Encore/Views/Map/FestivalMapView.swift
git commit -m "feat: add initialStage param and restyle FestivalMapView"
```

---

## Task 12: Restyle `ArtistDetailView`

**Files:**
- Modify: `Encore/Views/Shared/ArtistDetailView.swift`

- [ ] **Step 1: Apply token colors and add Directions button**

Replace the full file:

```swift
// Encore/Views/Shared/ArtistDetailView.swift
import SwiftUI

struct ArtistDetailView: View {

    let festivalSet: FestivalSet
    @EnvironmentObject var scheduleStore: ScheduleStore
    @EnvironmentObject var crewStore:     CrewStore
    @Environment(\.dismiss) private var dismiss

    var artist: Artist { festivalSet.artist }

    private let recentSetlist: [String] = [
        "Someone Great", "All My Friends", "Dance Yrself Clean",
        "Drunk Girls", "I Can Change", "New York I Love You", "Home"
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    heroHeader
                    Divider().padding(.vertical, 20)
                    sectionLabel("Set Info")
                    setInfoRow
                    Divider().padding(.vertical, 20)
                    let attendees = crewStore.attendees(for: festivalSet)
                    if !attendees.isEmpty {
                        sectionLabel("Your Crew")
                        crewRow(attendees: attendees)
                        Divider().padding(.vertical, 20)
                    }
                    sectionLabel("Recent Setlist  ·  via setlist.fm")
                    setlistView
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
            }
            .background(Color.appBackground)
            .navigationTitle(artist.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.appTextMuted)
                            .font(.system(size: 22))
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomActions
            }
        }
    }

    // MARK: - Hero

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(artist.matchTier.rawValue.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(artist.matchTier.color)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(artist.matchTier.backgroundColor)
                .clipShape(Capsule())

            Text(artist.genres.joined(separator: "  ·  "))
                .font(.system(size: 14))
                .foregroundColor(.appTextMuted)

            if let label = artist.spotifyLabel {
                Label(label, systemImage: "music.note")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(artist.matchTier.color)
            } else if !artist.soundsLike.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Not in your library yet — sounds like:")
                        .font(.system(size: 13))
                        .foregroundColor(.appTextMuted)
                    Text(artist.soundsLike.joined(separator: ", "))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.appTextPrimary)
                }
            }
        }
    }

    // MARK: - Set Info

    private var setInfoRow: some View {
        HStack(spacing: 0) {
            infoCell(label: "Stage", value: festivalSet.stageName)
            Divider().frame(height: 40)
            infoCell(label: "Day",   value: festivalSet.day.fullName)
            Divider().frame(height: 40)
            infoCell(label: "Time",  value: festivalSet.timeRangeLabel)
        }
        .padding(.vertical, 12)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func infoCell(label: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.appTextMuted)
                .textCase(.uppercase)
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.appTextPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Crew

    private func crewRow(attendees: [CrewMember]) -> some View {
        HStack(spacing: 8) {
            ForEach(attendees) { member in
                ZStack {
                    Circle().fill(member.color).frame(width: 36, height: 36)
                    Text(member.initials)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color.appBackground)
                }
            }
            Text("\(attendees.count) friend\(attendees.count == 1 ? "" : "s") going")
                .font(.system(size: 14))
                .foregroundColor(.appTextMuted)
            Spacer()
        }
        .padding(.bottom, 4)
    }

    // MARK: - Setlist

    private var setlistView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(recentSetlist.enumerated()), id: \.offset) { index, song in
                HStack {
                    Text("\(index + 1)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.appTextMuted)
                        .frame(width: 24, alignment: .trailing)
                    Text(song)
                        .font(.system(size: 14))
                        .foregroundColor(.appTextPrimary)
                    Spacer()
                }
                .padding(.vertical, 10)
                if index < recentSetlist.count - 1 { Divider() }
            }
        }
    }

    // MARK: - Bottom actions

    private var bottomActions: some View {
        let isScheduled = scheduleStore.isScheduled(festivalSet)
        return VStack(spacing: 8) {
            // Add / Remove
            Button(action: { scheduleStore.toggle(festivalSet) }) {
                HStack {
                    Image(systemName: isScheduled ? "checkmark" : "plus")
                    Text(isScheduled ? "Added to Schedule" : "Add to My Schedule")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isScheduled ? Color.appSurface : Color.appCTA)
                .foregroundColor(isScheduled ? .appTextPrimary : Color.appBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            // Directions
            NavigationLink(destination:
                FestivalMapView(initialStage: festivalSet.stageName)
                    .environmentObject(scheduleStore)
                    .environmentObject(crewStore)
            ) {
                HStack {
                    Image(systemName: "map")
                    Text("Directions to \(festivalSet.stageName)")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.appSurface)
                .foregroundColor(.appAccent)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.appBackground)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.appTextMuted)
            .textCase(.uppercase)
            .tracking(0.8)
            .padding(.bottom, 10)
    }
}

#Preview {
    ArtistDetailView(festivalSet: FestivalSet.mockSets[0])
        .environmentObject(ScheduleStore())
        .environmentObject(CrewStore())
        .preferredColorScheme(.dark)
}
```

- [ ] **Step 2: Build (`Cmd+B`)**

Expected: succeeds.

- [ ] **Step 3: Commit**

```bash
git add Encore/Views/Shared/ArtistDetailView.swift
git commit -m "feat: restyle ArtistDetailView and add directions navigation"
```

---

## Task 13: Restyle `ArtistCardView` and `ConflictResolverView`

**Files:**
- Modify: `Encore/Views/Shared/ArtistCardView.swift`
- Modify: `Encore/Views/Schedule/ConflictResolverView.swift`

- [ ] **Step 1: Update `ArtistCardView.swift`**

Make the following targeted replacements (do not change structure or logic):

| Old | New |
|-----|-----|
| `Color(uiColor: .secondarySystemBackground)` | `Color.appSurface` |
| `Color(uiColor: .tertiaryLabel)` | `Color.appTextMuted` |
| `.foregroundColor(.purple)` | `.foregroundColor(.appCTA)` |
| `Color.purple` | `Color.appCTA` |
| `.foregroundColor(.secondary)` | `.foregroundColor(.appTextMuted)` |
| `.foregroundColor(.primary)` | `.foregroundColor(.appTextPrimary)` |

- [ ] **Step 2: Update `ConflictResolverView.swift`**

Make the following targeted replacements:

| Old | New |
|-----|-----|
| `Color(uiColor: .systemBackground)` | `Color.appBackground` |
| `Color(uiColor: .secondarySystemBackground)` | `Color.appSurface` |
| `Color(uiColor: .tertiaryLabel)` | `Color.appTextMuted` |
| `Color.purple` | `Color.appCTA` |
| `.foregroundColor(.white)` (inside action button keep style) | `.foregroundColor(Color.appBackground)` |
| `.foregroundColor(.secondary)` | `.foregroundColor(.appTextMuted)` |
| `.foregroundColor(.primary)` | `.foregroundColor(.appTextPrimary)` |

- [ ] **Step 3: Build (`Cmd+B`)**

Expected: succeeds.

- [ ] **Step 4: Commit**

```bash
git add Encore/Views/Shared/ArtistCardView.swift \
        Encore/Views/Schedule/ConflictResolverView.swift
git commit -m "feat: apply color tokens to ArtistCardView and ConflictResolverView"
```

---

## Task 14: Delete old files and verify full build

- [ ] **Step 1: Delete the replaced files**

```bash
rm Encore/Views/Discover/DiscoverView.swift
rm Encore/Views/Schedule/MyScheduleView.swift
rm Encore/Views/Crew/CrewView.swift
rm Encore/Views/MainTabView.swift
rm Encore/Stores/DiscoverStore.swift
```

- [ ] **Step 2: Regenerate the Xcode project**

```bash
xcodegen generate
```

XcodeGen reads `project.yml` which uses `path: Encore` as the source glob — deleted files are automatically removed from the target. Regenerating ensures the `.xcodeproj` is clean.

- [ ] **Step 3: Build (`Cmd+B`)**

Expected: succeeds with zero errors. If any file still references `DiscoverStore`, the compiler will point to it — replace with `LineupStore`.

- [ ] **Step 4: Run in simulator**

Press `Cmd+R`. Verify:
- App launches on the Home tab
- Group card shows "Bonnaroo Squad" with 4 member avatars
- Trip card shows Travel / Packing / Expenses columns with SF Symbol icons (no emoji)
- "Browse Full Lineup" button navigates to the Lineup timetable grid
- Day picker in Lineup switches between Thu/Fri/Sat/Sun and the grid updates
- Tapping a stage header in the grid opens the map centered on that stage
- Tapping a set block opens the `ArtistDetailView` sheet
- "Directions to [Stage]" in artist detail navigates to the map
- Profile tab shows settings list with theme picker
- Switching theme in Profile changes the color scheme

- [ ] **Step 5: Final commit**

```bash
git add -A
git commit -m "feat: remove legacy tabs and complete Encore redesign"
```

---

## Post-Implementation Checklist (UI/UX.txt)

Before calling this done, walk through each screen and verify:

- [ ] Home: one clear purpose — festival at a glance. Primary action is schedule row tap.
- [ ] Lineup: one clear purpose — browse and add. Primary action is set block tap.
- [ ] Profile: one clear purpose — settings. Primary action is theme selection.
- [ ] All tap targets are at least 44pt tall (schedule rows, set blocks, trip columns, member bubbles).
- [ ] No emoji anywhere — all icons are SF Symbols.
- [ ] Colors pass contrast in both light and dark mode (mint on forest green — verify visually).
- [ ] Back navigation is always obvious (system back button, xmark dismiss).
