# setlist.fm Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the hardcoded setlist in `ArtistDetailView` with real song data fetched from the setlist.fm REST API, with in-memory caching and graceful fallbacks.

**Architecture:** `APIKeys.swift` (gitignored) holds the credential. `SetlistService` is a Swift `actor` that performs two sequential API calls (artist search → setlist fetch) and caches results by artist name. `ArtistDetailView` calls it via `.task` and renders a loading/error/empty/loaded state.

**Tech Stack:** SwiftUI, iOS 16, `async/await`, `URLSession`, `JSONDecoder`, `actor`. No CLI test runner — verify with Xcode build (Cmd+B). Run `xcodegen generate` after adding new Swift files.

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `.gitignore` | Exclude `APIKeys.swift` from version control |
| Create | `Encore/Utilities/APIKeys.swift` | setlist.fm API key constant |
| Create | `Encore/Utilities/SetlistService.swift` | API calls + in-memory cache |
| Modify | `Encore/Views/Artist/ArtistDetailView.swift` | Replace hardcoded list with live data |

---

## Task 1: Create .gitignore and APIKeys

**Files:**
- Create: `.gitignore`
- Create: `Encore/Utilities/APIKeys.swift`

- [ ] **Step 1: Create .gitignore**

Create `.gitignore` at the project root with:

```
# Xcode
*.xcuserstate
xcuserdata/

# API Keys — never commit
Encore/Utilities/APIKeys.swift

# macOS
.DS_Store
```

- [ ] **Step 2: Create APIKeys.swift**

Create `Encore/Utilities/APIKeys.swift` with:

```swift
// Encore/Utilities/APIKeys.swift
// ⚠️ This file is gitignored — never commit credentials.
import Foundation

enum APIKeys {
    static let setlistFM = "B0c_6tV4uMm2FhVpkSPIjfemh6HGeUwKSSRe"
}
```

- [ ] **Step 3: Run xcodegen generate**

```bash
cd /Users/ethantillmon/Desktop/Encore
xcodegen generate
```

Expected: `Created project at .../Encore.xcodeproj`

- [ ] **Step 4: Build**

In Xcode, press Cmd+B. Expected: build succeeds.

- [ ] **Step 5: Commit (without APIKeys.swift)**

```bash
git add .gitignore Encore.xcodeproj/project.pbxproj
git commit -m "chore: add .gitignore and APIKeys stub (key stored locally, gitignored)"
```

Note: `APIKeys.swift` must NOT appear in `git status` after this — the `.gitignore` excludes it. Verify with `git status` before committing.

---

## Task 2: Create SetlistService

**Files:**
- Create: `Encore/Utilities/SetlistService.swift`

- [ ] **Step 1: Create the file**

Create `Encore/Utilities/SetlistService.swift` with:

```swift
// Encore/Utilities/SetlistService.swift
import Foundation

actor SetlistService {

    static let shared = SetlistService()

    private let base = "https://api.setlist.fm/rest/1.0"
    private var cache: [String: [String]] = [:]

    // MARK: - Public

    func fetchRecentSetlist(for artistName: String) async throws -> [String] {
        if let hit = cache[artistName] { return hit }

        let mbid = try await searchMBID(for: artistName)
        guard let mbid else {
            cache[artistName] = []
            return []
        }

        let songs = try await fetchSongs(mbid: mbid)
        cache[artistName] = songs
        return songs
    }

    // MARK: - Private

    private func searchMBID(for artistName: String) async throws -> String? {
        guard let encoded = artistName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(base)/search/artists?artistName=\(encoded)&p=1&sort=relevance")
        else { return nil }

        do {
            let data = try await fetch(url: url)
            let result = try JSONDecoder().decode(ArtistSearchResponse.self, from: data)
            return result.artist?.first?.mbid
        } catch is NotFound { return nil }
    }

    private func fetchSongs(mbid: String) async throws -> [String] {
        guard let url = URL(string: "\(base)/artist/\(mbid)/setlists?p=1") else { return [] }

        do {
            let data = try await fetch(url: url)
            let result = try JSONDecoder().decode(SetlistResponse.self, from: data)
            return result.setlist?.first.map { item in
                item.sets.set.flatMap { $0.song ?? [] }.map { $0.name }
            } ?? []
        } catch is NotFound { return [] }
    }

    private func fetch(url: URL) async throws -> Data {
        var req = URLRequest(url: url)
        req.setValue(APIKeys.setlistFM, forHTTPHeaderField: "x-api-key")
        req.setValue("application/json",  forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if http.statusCode == 404 { throw NotFound() }
        guard http.statusCode == 200 else { throw URLError(.badServerResponse) }
        return data
    }

    private struct NotFound: Error {}
}

// MARK: - Decodable models (private to this file)

private struct ArtistSearchResponse: Decodable {
    let artist: [ArtistResult]?
}
private struct ArtistResult: Decodable {
    let mbid: String
}
private struct SetlistResponse: Decodable {
    let setlist: [SetlistItem]?
}
private struct SetlistItem: Decodable {
    let sets: SetContainer
}
private struct SetContainer: Decodable {
    let set: [SetGroup]
}
private struct SetGroup: Decodable {
    let song: [Song]?
}
private struct Song: Decodable {
    let name: String
}
```

> Note on the 404 path: when `fetch` returns `Data()` (empty), decoding `ArtistSearchResponse` will produce `artist: nil` and decoding `SetlistResponse` will produce `setlist: nil` — both return `[]` gracefully.

- [ ] **Step 2: Build**

Cmd+B. Expected: build succeeds with no errors.

- [ ] **Step 3: Commit**

```bash
git add Encore/Utilities/SetlistService.swift
git commit -m "feat: add SetlistService for fetching setlist.fm data"
```

---

## Task 3: Wire ArtistDetailView

**Files:**
- Modify: `Encore/Views/Artist/ArtistDetailView.swift`

- [ ] **Step 1: Replace the hardcoded setlist property with state vars**

Find and remove (lines 16-19):

```swift
private let recentSetlist: [String] = [
    "Someone Great", "All My Friends", "Dance Yrself Clean",
    "Drunk Girls", "I Can Change", "New York I Love You", "Home"
]
```

Replace with:

```swift
@State private var setlist:        [String] = []
@State private var setlistLoading: Bool     = false
@State private var setlistError:   Bool     = false
```

- [ ] **Step 2: Add .task modifier to the ScrollView**

Find:

```swift
            .background(Color.appBackground)
            .navigationTitle(artist.name)
```

Replace with:

```swift
            .background(Color.appBackground)
            .task { await loadSetlist() }
            .navigationTitle(artist.name)
```

- [ ] **Step 3: Add loadSetlist() method**

After the `var artist: Artist { festivalSet.artist }` line, add:

```swift
private func loadSetlist() async {
    setlistLoading = true
    do {
        setlist = try await SetlistService.shared.fetchRecentSetlist(for: artist.name)
    } catch {
        setlistError = true
    }
    setlistLoading = false
}
```

- [ ] **Step 4: Replace setlistView**

Find the entire `setlistView` computed property:

```swift
private var setlistView: some View {
    VStack(alignment: .leading, spacing: 0) {
        ForEach(Array(recentSetlist.enumerated()), id: \.offset) { index, song in
            HStack {
                Text("\(index + 1)")
                    .font(DS.Font.metadata)
                    .foregroundColor(.appTextMuted)
                    .frame(width: 24, alignment: .trailing)
                Text(song)
                    .font(DS.Font.listItem)
                    .foregroundColor(.appTextPrimary)
                Spacer()
            }
            .padding(.vertical, 10)
            if index < recentSetlist.count - 1 { Divider() }
        }
    }
}
```

Replace with:

```swift
private var setlistView: some View {
    VStack(alignment: .leading, spacing: 0) {
        if setlistLoading {
            ProgressView()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 16)
        } else if setlistError {
            Text("Couldn't load setlist")
                .font(DS.Font.metadata)
                .foregroundColor(.appTextMuted)
                .padding(.vertical, 8)
        } else if setlist.isEmpty {
            Text("No recent setlist found")
                .font(DS.Font.metadata)
                .foregroundColor(.appTextMuted)
                .padding(.vertical, 8)
        } else {
            ForEach(Array(setlist.enumerated()), id: \.offset) { index, song in
                HStack {
                    Text("\(index + 1)")
                        .font(DS.Font.metadata)
                        .foregroundColor(.appTextMuted)
                        .frame(width: 24, alignment: .trailing)
                    Text(song)
                        .font(DS.Font.listItem)
                        .foregroundColor(.appTextPrimary)
                    Spacer()
                }
                .padding(.vertical, 10)
                if index < setlist.count - 1 { Divider() }
            }
        }
    }
}
```

- [ ] **Step 5: Build**

Cmd+B. Expected: build succeeds with no errors.

- [ ] **Step 6: Verify in simulator**

Run the app (Cmd+R) on the iOS Simulator. Open any artist detail sheet. Confirm:
- A `ProgressView` spinner appears briefly in the setlist section on first open
- Songs load and display as a numbered list
- Re-opening the same artist shows songs immediately (cache hit — no spinner)

- [ ] **Step 7: Commit**

```bash
git add Encore/Views/Artist/ArtistDetailView.swift
git commit -m "feat: replace hardcoded setlist with live setlist.fm data"
```
