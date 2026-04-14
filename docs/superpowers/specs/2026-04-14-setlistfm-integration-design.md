# setlist.fm Integration — Design Spec

**Date:** 2026-04-14
**Scope:** Replace the hardcoded setlist in `ArtistDetailView` with real data fetched from the setlist.fm REST API.

---

## Goal

When a user opens `ArtistDetailView`, the "Recent Setlist" section fetches the artist's most recent live setlist from setlist.fm and displays it as a numbered song list. Results are cached in memory so re-opening the same artist is instant. Empty or missing setlists show a graceful fallback message.

---

## Architecture

### New file: `Encore/Utilities/APIKeys.swift` (gitignored)

Holds the setlist.fm API key as a static constant. Added to `.gitignore` to keep credentials out of version control.

```swift
enum APIKeys {
    static let setlistFM = "B0c_6tV4uMm2FhVpkSPIjfemh6HGeUwKSSRe"
}
```

### New file: `Encore/Utilities/SetlistService.swift`

A lightweight actor with one public method and an internal cache. Using `actor` ensures the cache dictionary is safe to write from concurrent `Task` calls.

```
actor SetlistService {
    static let shared = SetlistService()
    private var cache: [String: [String]] = [:]
    func fetchRecentSetlist(for artistName: String) async throws -> [String]
}
```

**`fetchRecentSetlist` logic:**

1. Check cache — return immediately if hit.
2. `GET https://api.setlist.fm/rest/1.0/search/artists?artistName={encoded}&p=1&sort=relevance`
   - Headers: `x-api-key: <APIKeys.setlistFM>`, `Accept: application/json`
   - Decode response → take `artist[0].mbid`. If array is empty, cache `[]` and return `[]`.
3. `GET https://api.setlist.fm/rest/1.0/artist/{mbid}/setlists?p=1`
   - Headers: same
   - Decode response → take `setlist[0]`. Flatten all `set[].song[].name` values into a `[String]`.
   - If no setlists, cache `[]` and return `[]`.
4. Cache result under `artistName`, return it.

**Error handling:**
- HTTP 404 on either request → cache `[]`, return `[]` (not found is not an error)
- Network failure / non-200 → `throw` so the caller can show an error state
- JSON decode failure → `throw`

### Decodable models (private to SetlistService.swift)

```swift
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

### Modified: `Encore/Views/Artist/ArtistDetailView.swift`

**Remove:**
```swift
private let recentSetlist: [String] = [
    "Someone Great", "All My Friends", ...
]
```

**Add state:**
```swift
@State private var setlist:        [String] = []
@State private var setlistLoading: Bool     = false
@State private var setlistError:   Bool     = false
```

**Add `.task` on the root ScrollView:**
```swift
.task { await loadSetlist() }
```

**Add `loadSetlist()` method:**
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

**Update `setlistView`:**
- If `setlistLoading`: show `ProgressView()` centered
- Else if `setlistError`: show "Couldn't load setlist" in muted text
- Else if `setlist.isEmpty`: show "No recent setlist found" in muted text
- Else: existing numbered list using `setlist` instead of `recentSetlist`

---

## Files changed

| Action | Path |
|--------|------|
| Create | `.gitignore` (new — exclude `APIKeys.swift`) |
| Create | `Encore/Utilities/APIKeys.swift` |
| Create | `Encore/Utilities/SetlistService.swift` |
| Modify | `Encore/Views/Artist/ArtistDetailView.swift` |

No `project.yml` changes needed — `sources: path: Encore` already discovers all Swift files recursively. Run `xcodegen generate` after adding the two new Swift files to regenerate `project.pbxproj`.

---

## Edge cases

| Case | Behavior |
|------|----------|
| Artist not found on setlist.fm | Returns `[]` → "No recent setlist found" |
| Artist found but no setlists | Returns `[]` → "No recent setlist found" |
| Network offline | `setlistError = true` → "Couldn't load setlist" |
| Same artist opened twice | Cache hit — no second network request |
| Artist name has special characters | URL-encoded via `addingPercentEncoding` before request |
