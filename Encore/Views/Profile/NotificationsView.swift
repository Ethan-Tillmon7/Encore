// Encore/Views/Profile/NotificationsView.swift
import SwiftUI
import UserNotifications

struct NotificationsView: View {

    @Environment(\.dismiss) private var dismiss

    @AppStorage(StorageKey.notifSetReminder)     private var setReminderOn   = false
    @AppStorage(StorageKey.notifReminderOffset)  private var reminderOffset  = 30
    @AppStorage(StorageKey.notifConflicts)       private var conflictsOn     = true
    @AppStorage(StorageKey.notifCrewChanges)     private var crewChangesOn   = true
    @AppStorage(StorageKey.notifWalkTime)        private var walkTimeOn      = true

    private let offsetOptions = [15, 30, 60]

    var body: some View {
        NavigationView {
            List {
                Section("Set Reminders") {
                    Toggle("Remind me before sets", isOn: $setReminderOn)
                        .tint(.appCTA)
                        .foregroundColor(.appTextPrimary)
                        .onChange(of: setReminderOn) { on in
                            if on { requestPermission() }
                        }
                    if setReminderOn {
                        Picker("How early", selection: $reminderOffset) {
                            ForEach(offsetOptions, id: \.self) { mins in
                                Text("\(mins) min before").tag(mins)
                            }
                        }
                        .foregroundColor(.appTextPrimary)
                    }
                }
                .listRowBackground(Color.appSurface)

                Section("Alerts") {
                    Toggle("Conflict alerts", isOn: $conflictsOn)
                        .tint(.appCTA)
                        .foregroundColor(.appTextPrimary)
                        .onChange(of: conflictsOn) { on in if on { requestPermission() } }
                    Toggle("Crew schedule changes", isOn: $crewChangesOn)
                        .tint(.appCTA)
                        .foregroundColor(.appTextPrimary)
                        .onChange(of: crewChangesOn) { on in if on { requestPermission() } }
                    Toggle("Walk time warnings", isOn: $walkTimeOn)
                        .tint(.appCTA)
                        .foregroundColor(.appTextPrimary)
                        .onChange(of: walkTimeOn) { on in if on { requestPermission() } }
                }
                .listRowBackground(Color.appSurface)

                Section {
                    Text("Notification delivery depends on your system settings. Enable notifications in iOS Settings if prompts don't appear.")
                        .font(DS.Font.metadata)
                        .foregroundColor(.appTextMuted)
                }
                .listRowBackground(Color.appBackground)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.appCTA)
                }
            }
        }
    }

    private func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
}

#Preview {
    NotificationsView()
        .preferredColorScheme(.dark)
}
