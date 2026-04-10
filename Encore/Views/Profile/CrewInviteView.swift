// Encore/Views/Profile/CrewInviteView.swift
import SwiftUI

struct CrewInviteView: View {

    @EnvironmentObject var crewStore: CrewStore
    @Environment(\.dismiss) private var dismiss

    @State private var mode: Mode = .create
    @State private var crewName = ""
    @State private var joinCode = ""
    @State private var joinError: String? = nil
    @State private var didCreate = false

    enum Mode { case create, join }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Mode picker
                Picker("Mode", selection: $mode) {
                    Text("Create").tag(Mode.create)
                    Text("Join").tag(Mode.join)
                }
                .pickerStyle(.segmented)
                .padding(DS.Spacing.pageMargin)
                .background(Color.appBackground)

                Divider()

                ScrollView {
                    VStack(spacing: 20) {
                        if mode == .create {
                            createSection
                        } else {
                            joinSection
                        }
                    }
                    .padding(DS.Spacing.pageMargin)
                }
            }
            .background(Color.appBackground)
            .navigationTitle(mode == .create ? "Create a Crew" : "Join a Crew")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.appTextMuted)
                }
            }
        }
    }

    private var createSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if didCreate, let crew = crewStore.crew {
                // Success state — show invite code
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.appCTA)
                    Text("Crew created!")
                        .font(DS.Font.cardTitle)
                        .foregroundColor(.appTextPrimary)
                    Text(crew.name)
                        .font(DS.Font.listItem)
                        .foregroundColor(.appTextMuted)
                    Text(crew.inviteCode)
                        .font(.system(size: 32, weight: .black, design: .monospaced))
                        .foregroundColor(.appCTA)
                        .tracking(6)
                        .padding(.vertical, 8)
                    Text("Share this code with your friends")
                        .font(DS.Font.metadata)
                        .foregroundColor(.appTextMuted)
                    ShareLink(item: "Join my crew on Encore! Code: \(crew.inviteCode)") {
                        Label("Share invite code", systemImage: "square.and.arrow.up")
                            .font(DS.Font.listItem)
                            .foregroundColor(Color.appBackground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.appCTA)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
                    }
                    .buttonStyle(.plain)
                    Button("Done") { dismiss() }
                        .font(DS.Font.listItem)
                        .foregroundColor(.appTextMuted)
                }
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Crew Name")
                        .font(DS.Font.label)
                        .foregroundColor(.appTextMuted)
                    TextField("e.g. Bonnaroo Squad", text: $crewName)
                        .font(DS.Font.listItem)
                        .foregroundColor(.appTextPrimary)
                        .padding(12)
                        .background(Color.appSurface)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
                }
                Button(action: {
                    let name = crewName.trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty {
                        crewStore.createCrew(name: name)
                        didCreate = true
                    }
                }) {
                    Text("Create Crew")
                        .fontWeight(.semibold)
                        .foregroundColor(Color.appBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(crewName.trimmingCharacters(in: .whitespaces).isEmpty ? Color.appTextMuted.opacity(0.3) : Color.appCTA)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
                }
                .buttonStyle(.plain)
                .disabled(crewName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private var joinSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Enter Invite Code")
                    .font(DS.Font.label)
                    .foregroundColor(.appTextMuted)
                TextField("6-character code", text: $joinCode)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .textCase(.uppercase)
                    .tracking(4)
                    .foregroundColor(.appCTA)
                    .multilineTextAlignment(.center)
                    .padding(16)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
                    .onChange(of: joinCode) { newVal in
                        joinCode = String(newVal.uppercased().prefix(6))
                        joinError = nil
                    }
                if let error = joinError {
                    Text(error)
                        .font(DS.Font.metadata)
                        .foregroundColor(.appDanger)
                }
            }

            Button(action: {
                let code = joinCode.trimmingCharacters(in: .whitespaces)
                if code.count == 6 {
                    crewStore.joinCrew(code: code)
                    if crewStore.crew != nil {
                        dismiss()
                    } else {
                        joinError = "No crew found with that code."
                    }
                } else {
                    joinError = "Enter the full 6-character code."
                }
            }) {
                Text("Join Crew")
                    .fontWeight(.semibold)
                    .foregroundColor(Color.appBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(joinCode.count == 6 ? Color.appCTA : Color.appTextMuted.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
            }
            .buttonStyle(.plain)
            .disabled(joinCode.count < 6)
        }
    }
}

#Preview {
    CrewInviteView()
        .environmentObject(CrewStore())
        .preferredColorScheme(.dark)
}
