// Encore/Views/Profile/CrewManageView.swift
import SwiftUI

struct CrewManageView: View {

    @EnvironmentObject var crewStore: CrewStore
    @Environment(\.dismiss) private var dismiss

    @State private var showInvite = false
    @State private var showLeaveConfirm = false

    var body: some View {
        NavigationView {
            List {
                if let crew = crewStore.crew {
                    // Crew header
                    Section {
                        VStack(alignment: .leading, spacing: DS.Spacing.sectionGap) {
                            Text(crew.name)
                                .font(DS.Font.cardTitle)
                                .foregroundColor(.appTextPrimary)
                            HStack(spacing: 8) {
                                Text("Invite Code")
                                    .font(DS.Font.label)
                                    .foregroundColor(.appTextMuted)
                                Text(crew.inviteCode)
                                    .font(.system(size: 20, weight: .black, design: .monospaced))
                                    .foregroundColor(.appCTA)
                                    .tracking(4)
                                Button(action: {
                                    UIPasteboard.general.string = crew.inviteCode
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 14))
                                        .foregroundColor(.appAccent)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.appSurface)

                    // Members
                    Section("Members") {
                        ForEach(crew.members) { member in
                            HStack(spacing: 12) {
                                CrewAvatarBubble(member: member, size: 36)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(member.name)
                                        .font(DS.Font.listItem)
                                        .foregroundColor(.appTextPrimary)
                                    if let stage = member.lastSeenStage {
                                        Text(stage)
                                            .font(DS.Font.metadata)
                                            .foregroundColor(.appTextMuted)
                                    }
                                }
                                Spacer()
                                Circle()
                                    .fill(member.isOnline ? Color.appCTA : Color.appTextMuted.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                    .listRowBackground(Color.appSurface)

                    // Leave
                    Section {
                        Button(role: .destructive, action: { showLeaveConfirm = true }) {
                            Label("Leave Crew", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                    .listRowBackground(Color.appSurface)
                } else {
                    Section {
                        Text("You're not in a crew yet.")
                            .font(DS.Font.listItem)
                            .foregroundColor(.appTextMuted)
                        Button("Create or Join a Crew") { showInvite = true }
                            .font(DS.Font.listItem)
                            .foregroundColor(.appCTA)
                    }
                    .listRowBackground(Color.appSurface)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("My Crew")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.appCTA)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showInvite = true }) {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(.appCTA)
                    }
                }
            }
            .sheet(isPresented: $showInvite) {
                CrewInviteView()
                    .environmentObject(crewStore)
            }
            .confirmationDialog("Leave \(crewStore.crew?.name ?? "crew")?", isPresented: $showLeaveConfirm, titleVisibility: .visible) {
                Button("Leave Crew", role: .destructive) { crewStore.leaveCrew(); dismiss() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

#Preview {
    CrewManageView()
        .environmentObject(CrewStore())
        .preferredColorScheme(.dark)
}
