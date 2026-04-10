// Encore/Views/Profile/ProfileView.swift
import SwiftUI

struct ProfileView: View {

    @AppStorage("appTheme") private var appTheme: String = "system"
    @EnvironmentObject var festivalStore: FestivalStore

    @State private var showEditProfile:    Bool = false
    @State private var showNotifications:  Bool = false
    @State private var showSignOutConfirm: Bool = false
    @State private var showCrewManage:     Bool = false
    @State private var showTravelDetails:  Bool = false
    @State private var showCrewInvite:     Bool = false

    var body: some View {
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
                    Text("Your Name")
                        .font(DS.Font.cardTitle)
                        .foregroundColor(.appTextPrimary)
                }
                .padding(.vertical, 6)
            }
            .listRowBackground(Color.appSurface)

            Section("Account") {
                Button("Edit Profile") { showEditProfile = true }
                    .font(DS.Font.listItem)
                    .foregroundColor(.appAccent)
                Button(action: { showNotifications = true }) {
                    Label("Notifications", systemImage: "bell")
                        .foregroundColor(.appTextPrimary)
                }
            }
            .listRowBackground(Color.appSurface)

            Section("Crew & Festival") {
                Button(action: { showCrewManage = true }) {
                    Label("My Crew", systemImage: "person.2")
                        .foregroundColor(.appTextPrimary)
                }
                Button(action: { showTravelDetails = true }) {
                    Label("Travel Details", systemImage: "suitcase")
                        .foregroundColor(.appTextPrimary)
                }
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
                Button(role: .destructive, action: { showSignOutConfirm = true }) {
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
            .confirmationDialog("Sign out of Encore?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) {
                    // Clear AppStorage keys
                    UserDefaults.standard.removeObject(forKey: StorageKey.displayName)
                    UserDefaults.standard.removeObject(forKey: StorageKey.avatarColorHex)
                    UserDefaults.standard.removeObject(forKey: StorageKey.selectedFestivalID)
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showEditProfile) { EditProfileView() }
            .sheet(isPresented: $showNotifications) { NotificationsView() }
            .sheet(isPresented: $showCrewManage) { CrewManageView() }
            .sheet(isPresented: $showCrewInvite) { CrewInviteView() }
            .sheet(isPresented: $showTravelDetails) {
                if let festivalID = festivalStore.selectedFestival?.id {
                    TravelDetailsView(festivalID: festivalID)
                } else {
                    TravelDetailsView(festivalID: UUID())
                }
            }
    }
}

#Preview {
    ProfileView()
        .environmentObject(FestivalStore())
        .preferredColorScheme(.dark)
}
