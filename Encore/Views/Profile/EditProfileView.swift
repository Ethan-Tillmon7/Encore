// Encore/Views/Profile/EditProfileView.swift
import SwiftUI

struct EditProfileView: View {

    @EnvironmentObject var crewStore:   CrewStore
    @EnvironmentObject var lineupStore: LineupStore
    @Environment(\.dismiss) private var dismiss

    @AppStorage(StorageKey.displayName)    private var displayName    = "Your Name"
    @AppStorage(StorageKey.avatarColorHex) private var avatarColorHex = "8B5CF6"

    @State private var draftName  = ""
    @State private var draftColor = "8B5CF6"

    private let presetColors: [String] = [
        "8B5CF6", "10B981", "F59E0B", "EF4444",
        "3B82F6", "EC4899", "14B8A6", "F97316",
        "6366F1", "84CC16", "A855F7", "06B6D4"
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Live avatar preview
                    avatarPreview

                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Display Name")
                            .font(DS.Font.label)
                            .foregroundColor(.appTextMuted)
                            .textCase(.uppercase)
                            .tracking(0.8)
                        TextField("Your name", text: $draftName)
                            .font(DS.Font.cardTitle)
                            .foregroundColor(.appTextPrimary)
                            .padding(DS.Spacing.cardPadding)
                            .background(Color.appSurface)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
                    }

                    // Color picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Avatar Color")
                            .font(DS.Font.label)
                            .foregroundColor(.appTextMuted)
                            .textCase(.uppercase)
                            .tracking(0.8)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                            ForEach(presetColors, id: \.self) { hex in
                                Button(action: { draftColor = hex }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: hex) ?? .appCTA)
                                            .frame(width: 44, height: 44)
                                        if draftColor == hex {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Spotify card
                    spotifyCard

                    Spacer(minLength: 20)
                }
                .padding(DS.Spacing.pageMargin)
            }
            .background(Color.appBackground)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.appTextMuted)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveProfile() }
                        .font(DS.Font.listItem)
                        .foregroundColor(.appCTA)
                }
            }
            .onAppear {
                draftName  = displayName
                draftColor = avatarColorHex
            }
        }
    }

    private var avatarPreview: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color(hex: draftColor) ?? .appCTA)
                    .frame(width: 80, height: 80)
                Text(initials(from: draftName))
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.white)
            }
            Text(draftName.isEmpty ? "Your Name" : draftName)
                .font(DS.Font.cardTitle)
                .foregroundColor(.appTextPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var spotifyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Spotify")
                .font(DS.Font.label)
                .foregroundColor(.appTextMuted)
                .textCase(.uppercase)
                .tracking(0.8)
            HStack {
                Image(systemName: "music.note.list")
                    .foregroundColor(.appAccent)
                if lineupStore.isSpotifyConnected {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Connected")
                            .font(DS.Font.listItem)
                            .foregroundColor(.appTextPrimary)
                        Text("Lineup match scores are active")
                            .font(DS.Font.metadata)
                            .foregroundColor(.appTextMuted)
                    }
                    Spacer()
                    Button("Disconnect") { lineupStore.disconnectSpotify() }
                        .font(DS.Font.label)
                        .foregroundColor(.appDanger)
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Not connected")
                            .font(DS.Font.listItem)
                            .foregroundColor(.appTextPrimary)
                        Text("Connect to see match scores")
                            .font(DS.Font.metadata)
                            .foregroundColor(.appTextMuted)
                    }
                    Spacer()
                    Button("Connect Spotify") {
                        lineupStore.connectSpotify()  // TODO: Phase 1 — OAuth
                    }
                    .font(DS.Font.label)
                    .foregroundColor(.appCTA)
                }
            }
            .padding(DS.Spacing.cardPadding)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
        }
    }

    private func saveProfile() {
        displayName    = draftName.trimmingCharacters(in: .whitespaces).isEmpty ? "Encore User" : draftName
        avatarColorHex = draftColor
        dismiss()
    }

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }
}

#Preview {
    EditProfileView()
        .environmentObject(CrewStore())
        .environmentObject(LineupStore())
        .preferredColorScheme(.dark)
}
