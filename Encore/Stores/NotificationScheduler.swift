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
