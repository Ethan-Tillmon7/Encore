# Local Set Reminders Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire `UNUserNotificationCenter` so the app schedules, updates, and cancels local push notifications for each set in the user's schedule, driven by the existing toggles in `NotificationsView`.

**Architecture:** A stateless `NotificationScheduler` helper centralises all `UNUserNotificationCenter` calls. `ScheduleStore.add/remove` call it on every mutation. `NotificationsView` calls it when the toggle or offset changes. No new stores or models needed.

**Tech Stack:** SwiftUI, iOS 16, `UserNotifications` framework, `@EnvironmentObject`, `@AppStorage`/`UserDefaults`. No CLI test runner — verify each task with Xcode build (Cmd+B). Run `xcodegen generate` after adding the new Swift file in Task 1.

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| **Create** | `Encore/Stores/NotificationScheduler.swift` | All `UNUserNotificationCenter` scheduling logic |
| Modify | `Encore/Stores/ScheduleStore.swift` | Call scheduler on `add` / `remove` |
| Modify | `Encore/Views/Profile/NotificationsView.swift` | Wire toggle + offset changes to scheduler |

---

## Task 1: Create NotificationScheduler

**Files:**
- Create: `Encore/Stores/NotificationScheduler.swift`

- [ ] **Step 1: Create the file**

Create `Encore/Stores/NotificationScheduler.swift` with the following content:

```swift
// Encore/Stores/NotificationScheduler.swift
import Foundation
import UserNotifications

struct NotificationScheduler {

    private static let prefix = "set-reminder-"

    // MARK: - Schedule one set

    static func schedule(for set: FestivalSet, offset: Int) {
        let triggerDate = set.startTime.addingTimeInterval(-Double(offset) * 60)
        guard triggerDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = set.artist.name
        content.body  = "\(set.stageName) · \(timeString(set.startTime))"
        content.sound = .default

        let comps   = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(
            identifier: prefix + set.id.uuidString,
            content:    content,
            trigger:    trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Cancel one set

    static func cancel(for set: FestivalSet) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [prefix + set.id.uuidString])
    }

    // MARK: - Cancel all set reminders

    static func cancelAll() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { pending in
            let ids = pending.map { $0.identifier }.filter { $0.hasPrefix(prefix) }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    // MARK: - Reschedule all set reminders

    static func rescheduleAll(_ sets: [FestivalSet], offset: Int) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { pending in
            let ids = pending.map { $0.identifier }.filter { $0.hasPrefix(prefix) }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
            for set in sets {
                schedule(for: set, offset: offset)
            }
        }
    }

    // MARK: - Helpers

    private static func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }
}
```

- [ ] **Step 2: Run xcodegen generate**

```bash
cd /Users/ethantillmon/Desktop/Encore
xcodegen generate
```

Expected: prints `Generating project…` and succeeds with no errors.

- [ ] **Step 3: Build**

Open `Encore.xcodeproj` in Xcode and press Cmd+B.
Expected: build succeeds with no errors.

- [ ] **Step 4: Commit**

```bash
git add Encore/Stores/NotificationScheduler.swift Encore.xcodeproj/project.pbxproj
git commit -m "feat: add NotificationScheduler for local set reminders"
```

---

## Task 2: Wire ScheduleStore

**Files:**
- Modify: `Encore/Stores/ScheduleStore.swift`

- [ ] **Step 1: Update `add(_:)`**

Find the current `add` method:

```swift
func add(_ set: FestivalSet) {
    guard !isScheduled(set) else { return }
    scheduledSets.append(set)
}
```

Replace it with:

```swift
func add(_ set: FestivalSet) {
    guard !isScheduled(set) else { return }
    scheduledSets.append(set)
    let on     = UserDefaults.standard.bool(forKey: StorageKey.notifSetReminder)
    let offset = UserDefaults.standard.integer(forKey: StorageKey.notifReminderOffset)
    if on { NotificationScheduler.schedule(for: set, offset: offset == 0 ? 30 : offset) }
}
```

- [ ] **Step 2: Update `remove(_:)`**

Find the current `remove` method:

```swift
func remove(_ set: FestivalSet) {
    scheduledSets.removeAll { $0.id == set.id }
}
```

Replace it with:

```swift
func remove(_ set: FestivalSet) {
    NotificationScheduler.cancel(for: set)
    scheduledSets.removeAll { $0.id == set.id }
}
```

- [ ] **Step 3: Build**

Cmd+B. Expected: build succeeds with no errors or warnings in `ScheduleStore.swift`.

- [ ] **Step 4: Commit**

```bash
git add Encore/Stores/ScheduleStore.swift
git commit -m "feat: schedule/cancel notifications when sets are added or removed"
```

---

## Task 3: Wire NotificationsView

**Files:**
- Modify: `Encore/Views/Profile/NotificationsView.swift`

- [ ] **Step 1: Add ScheduleStore environment object**

At the top of `NotificationsView`, find the existing `@Environment` and `@AppStorage` declarations:

```swift
@Environment(\.dismiss) private var dismiss

@AppStorage(StorageKey.notifSetReminder)     private var setReminderOn   = false
```

Add the `@EnvironmentObject` line immediately before `@Environment`:

```swift
@EnvironmentObject var scheduleStore: ScheduleStore

@Environment(\.dismiss) private var dismiss

@AppStorage(StorageKey.notifSetReminder)     private var setReminderOn   = false
```

- [ ] **Step 2: Replace the `setReminderOn` onChange handler**

Find the existing toggle's `onChange`:

```swift
Toggle("Remind me before sets", isOn: $setReminderOn)
    .tint(.appCTA)
    .foregroundColor(.appTextPrimary)
    .onChange(of: setReminderOn) { on in
        if on { requestPermission() }
    }
```

Replace it with:

```swift
Toggle("Remind me before sets", isOn: $setReminderOn)
    .tint(.appCTA)
    .foregroundColor(.appTextPrimary)
    .onChange(of: setReminderOn) { on in
        if on {
            requestPermission()
            let offset = UserDefaults.standard.integer(forKey: StorageKey.notifReminderOffset)
            NotificationScheduler.rescheduleAll(
                scheduleStore.scheduledSets,
                offset: offset == 0 ? 30 : offset
            )
        } else {
            NotificationScheduler.cancelAll()
        }
    }
```

- [ ] **Step 3: Add reminderOffset onChange**

Find the `Picker` for the reminder offset:

```swift
if setReminderOn {
    Picker("How early", selection: $reminderOffset) {
        ForEach(offsetOptions, id: \.self) { mins in
            Text("\(mins) min before").tag(mins)
        }
    }
    .foregroundColor(.appTextPrimary)
}
```

Replace it with:

```swift
if setReminderOn {
    Picker("How early", selection: $reminderOffset) {
        ForEach(offsetOptions, id: \.self) { mins in
            Text("\(mins) min before").tag(mins)
        }
    }
    .foregroundColor(.appTextPrimary)
    .onChange(of: reminderOffset) { offset in
        NotificationScheduler.rescheduleAll(scheduleStore.scheduledSets, offset: offset)
    }
}
```

- [ ] **Step 4: Update the #Preview to inject ScheduleStore**

Find the `#Preview`:

```swift
#Preview {
    NotificationsView()
        .preferredColorScheme(.dark)
}
```

Replace it with:

```swift
#Preview {
    NotificationsView()
        .environmentObject(ScheduleStore())
        .preferredColorScheme(.dark)
}
```

- [ ] **Step 5: Build**

Cmd+B. Expected: build succeeds with no errors.

- [ ] **Step 6: Verify in simulator**

Run the app on the iOS Simulator (Cmd+R). Grant notification permission when prompted.

1. Go to the **Lineup** tab, open any set, tap **Add to Schedule**
2. Go to **Profile → Notifications**, enable "Remind me before sets"
3. In Terminal, run: `xcrun simctl push booted com.yourteam.Encore notification.json` — or simply trust the `UNUserNotificationCenter.add` call succeeded by confirming no runtime errors in the Xcode console
4. Confirm: toggling off clears all set reminders — check Xcode console for no new requests

- [ ] **Step 7: Commit**

```bash
git add Encore/Views/Profile/NotificationsView.swift
git commit -m "feat: wire NotificationsView toggle and offset to NotificationScheduler"
```
