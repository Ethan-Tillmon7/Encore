# Local Set Reminders — Design Spec

**Date:** 2026-04-14
**Scope:** Wire `UNUserNotificationCenter` to `ScheduleStore` so users receive a local push notification N minutes before each scheduled set.

---

## Goal

When "Remind me before sets" is toggled on in `NotificationsView`, the app schedules a local notification for every set in the user's schedule. Notifications fire at `reminderOffset` minutes before each set's `startTime`. Adding or removing a set keeps notifications in sync. The toggle retroactively applies to all currently-scheduled sets.

---

## Architecture

### New file: `Encore/Stores/NotificationScheduler.swift`

A stateless struct with three static methods. Has no stored properties and no `@Published` state — it is a pure side-effect helper.

```swift
NotificationScheduler
  static func schedule(for: FestivalSet, offset: Int)
  static func cancel(for: FestivalSet)
  static func cancelAll()
  static func rescheduleAll(_ sets: [FestivalSet], offset: Int)
```

**Notification ID scheme:** `"set-reminder-\(set.id.uuidString)"` — makes cancel-by-ID reliable without tracking any state.

**`schedule` behavior:**

- Builds a `UNMutableNotificationContent`: title = artist name, body = "\(set.stageName) · \(formatted startTime)"
- Computes trigger date = `set.startTime` minus `offset` minutes
- If trigger date is in the past, skips silently (no-op)
- Adds the request via `UNUserNotificationCenter.current().add(_:)`

**`cancel` behavior:**

- Calls `removePendingNotificationRequests(withIdentifiers:)` with the set's ID
- Safe to call even if no request exists

**`cancelAll` behavior:**

- Calls `getPendingNotificationRequests` (async completion), filters IDs prefixed `"set-reminder-"`, removes them

**`rescheduleAll` behavior:**

- Calls `cancelAll`, then schedules each set in the provided array using `schedule(for:offset:)`

---

### Modified: `Encore/Stores/ScheduleStore.swift`

`add(_:)` — after appending, read reminder settings from `UserDefaults.standard` and call `NotificationScheduler.schedule` if enabled:

```swift
func add(_ set: FestivalSet) {
    guard !isScheduled(set) else { return }
    scheduledSets.append(set)
    let on     = UserDefaults.standard.bool(forKey: StorageKey.notifSetReminder)
    let offset = UserDefaults.standard.integer(forKey: StorageKey.notifReminderOffset)
    if on { NotificationScheduler.schedule(for: set, offset: offset == 0 ? 30 : offset) }
}
```

`remove(_:)` — call `NotificationScheduler.cancel` unconditionally before removing:

```swift
func remove(_ set: FestivalSet) {
    NotificationScheduler.cancel(for: set)
    scheduledSets.removeAll { $0.id == set.id }
}
```

No change to `persistScheduledSets` or the `init` loader.

---

### Modified: `Encore/Views/Profile/NotificationsView.swift`

`NotificationsView` needs a `ScheduleStore` environment object to supply the current set list to `rescheduleAll`. Add:

```swift
@EnvironmentObject var scheduleStore: ScheduleStore
```

Update the `setReminderOn` `onChange`:

```swift
.onChange(of: setReminderOn) { on in
    if on {
        requestPermission()
        let offset = UserDefaults.standard.integer(forKey: StorageKey.notifReminderOffset)
        NotificationScheduler.rescheduleAll(scheduleStore.scheduledSets, offset: offset == 0 ? 30 : offset)
    } else {
        NotificationScheduler.cancelAll()
    }
}
```

Add a `reminderOffset` `onChange`:

```swift
.onChange(of: reminderOffset) { offset in
    guard setReminderOn else { return }
    NotificationScheduler.rescheduleAll(scheduleStore.scheduledSets, offset: offset)
}
```

Add `cancelAll()` to `NotificationScheduler` — removes all pending `"set-reminder-*"` requests (same logic as the first half of `rescheduleAll`, extracted for clarity).

---

## Call sites that inject `NotificationsView`

`NotificationsView` is currently presented as a sheet from `ProfileView`. Confirm `ProfileView` injects `scheduleStore` or passes it through the environment from root. Since `ScheduleStore` is injected at the root in `EncoreApp`, it is available in `@EnvironmentObject` without changes to `ProfileView`.

---

## Edge cases

| Case | Behavior |
|------|----------|
| Trigger date in the past | `schedule` silently no-ops — UNUserNotificationCenter rejects past triggers |
| User hasn't granted permission | Requests are queued; UNUserNotificationCenter delivers them once permission is granted (system behavior) |
| Offset = 0 from UserDefaults default | Default falls back to 30 minutes |
| App reinstalled / fresh launch | `scheduledSets` reloads from `UserDefaults`; no notifications are scheduled until user re-enables the toggle |
| Multiple sets at the same time | Each gets a distinct notification ID, all schedule independently |

---

## Files changed

| Action | File |
|--------|------|
| Create | `Encore/Stores/NotificationScheduler.swift` |
| Modify | `Encore/Stores/ScheduleStore.swift` |
| Modify | `Encore/Views/Profile/NotificationsView.swift` |

No new models, no new stores, no `project.yml` changes needed.
