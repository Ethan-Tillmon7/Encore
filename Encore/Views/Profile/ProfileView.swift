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
