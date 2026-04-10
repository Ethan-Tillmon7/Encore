// Encore/Views/Onboarding/OnboardingView.swift
import SwiftUI

struct OnboardingView: View {

    @AppStorage(StorageKey.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @AppStorage(StorageKey.displayName)            private var displayName: String = ""
    @AppStorage(StorageKey.avatarColorHex)         private var avatarColorHex: String = "A8BFB2"

    @EnvironmentObject var crewStore: CrewStore

    @State private var page = 0
    @State private var draftName: String = ""
    @State private var draftColorHex: String = "A8BFB2"

    private let totalPages = 5

    private let colorOptions: [String] = [
        "A8BFB2", "D4ECEC", "E8F7D0",
        "F0A840", "E05555", "8BA3F5",
        "C9A0DC", "F5CBA7", "7DCEA0",
        "5DADE2", "F1948A", "B2BABB"
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $page) {
                welcomeStep.tag(0)
                spotifyStep.tag(1)
                profileStep.tag(2)
                crewStep.tag(3)
                doneStep.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: page)

            pageIndicator
                .padding(.bottom, 20)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .onAppear { draftName = displayName; draftColorHex = avatarColorHex }
    }

    // MARK: - Page indicator

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalPages, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Color.appCTA : Color.appAccent.opacity(0.3))
                    .frame(width: i == page ? 20 : 6, height: 6)
                    .animation(.spring(), value: page)
            }
        }
    }

    // MARK: - Step 1: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: DS.Spacing.sectionGap) {
                Text("encore")
                    .font(DS.Font.display)
                    .foregroundColor(.appCTA)
                    .tracking(2)
                Text("Your festival, your way.")
                    .font(DS.Font.hero)
                    .foregroundColor(.appTextPrimary)
                    .multilineTextAlignment(.center)
                Text("Discover artists, build your schedule, and explore with your crew.")
                    .font(DS.Font.listItem)
                    .foregroundColor(.appTextMuted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .padding(.horizontal, DS.Spacing.pageMargin * 2)

            Spacer()

            ctaButton(label: "Get Started") { advance() }
                .padding(.horizontal, DS.Spacing.pageMargin)
                .padding(.bottom, 60)
        }
    }

    // MARK: - Step 2: Spotify

    private var spotifyStep: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: DS.Spacing.sectionGap) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 52, weight: .light))
                    .foregroundColor(.appCTA)
                    .padding(.bottom, 8)
                Text("Connect Spotify")
                    .font(DS.Font.hero)
                    .foregroundColor(.appTextPrimary)
                Text("Encore uses your listening history to rank artists and surface your best matches in the lineup.")
                    .font(DS.Font.listItem)
                    .foregroundColor(.appTextMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, DS.Spacing.pageMargin * 2)

            Spacer()

            VStack(spacing: 10) {
                ctaButton(label: "Connect Spotify") {
                    // TODO: wire Spotify OAuth
                    advance()
                }
                skipButton { advance() }
            }
            .padding(.horizontal, DS.Spacing.pageMargin)
            .padding(.bottom, 60)
        }
    }

    // MARK: - Step 3: Profile

    private var profileStep: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color(appHex: draftColorHex))
                        .frame(width: 72, height: 72)
                    Text(initials(from: draftName))
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(Color.appBackground)
                }

                VStack(alignment: .leading, spacing: DS.Spacing.sectionGap) {
                    sectionLabel("Your name")
                    TextField("Display name", text: $draftName)
                        .font(DS.Font.listItem)
                        .foregroundColor(.appTextPrimary)
                        .padding(12)
                        .background(Color.appSurface)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
                }
                .padding(.horizontal, DS.Spacing.pageMargin * 2)

                VStack(alignment: .leading, spacing: DS.Spacing.sectionGap) {
                    sectionLabel("Avatar color")
                        .padding(.horizontal, DS.Spacing.pageMargin * 2)
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 6), spacing: 10) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Circle()
                                .fill(Color(appHex: hex))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle().stroke(Color.appCTA, lineWidth: draftColorHex == hex ? 2.5 : 0)
                                )
                                .onTapGesture { draftColorHex = hex }
                        }
                    }
                    .padding(.horizontal, DS.Spacing.pageMargin * 2)
                }
            }

            Spacer()

            ctaButton(label: "Continue") {
                if !draftName.isEmpty {
                    displayName = draftName
                    avatarColorHex = draftColorHex
                }
                advance()
            }
            .padding(.horizontal, DS.Spacing.pageMargin)
            .padding(.bottom, 60)
        }
    }

    // MARK: - Step 4: Crew

    private var crewStep: some View {
        OnboardingCrewStep(onFinish: advance)
    }

    // MARK: - Step 5: Done

    private var doneStep: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: DS.Spacing.sectionGap) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56, weight: .light))
                    .foregroundColor(.appCTA)
                    .padding(.bottom, 8)
                Text("You're all set!")
                    .font(DS.Font.hero)
                    .foregroundColor(.appTextPrimary)
                Text("Head to the Lineup to explore artists, or jump into Discover to find your next festival.")
                    .font(DS.Font.listItem)
                    .foregroundColor(.appTextMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, DS.Spacing.pageMargin * 2)

            Spacer()

            ctaButton(label: "Let's Go") {
                hasCompletedOnboarding = true
            }
            .padding(.horizontal, DS.Spacing.pageMargin)
            .padding(.bottom, 60)
        }
    }

    // MARK: - Helpers

    private func advance() {
        withAnimation { page = min(page + 1, totalPages - 1) }
    }

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ").prefix(2)
        if parts.isEmpty { return "?" }
        return parts.map { String($0.prefix(1)).uppercased() }.joined()
    }

    private func ctaButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.appCTA)
                .foregroundColor(Color.appBackground)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        }
    }

    private func skipButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("Skip for now")
                .font(DS.Font.listItem)
                .foregroundColor(.appTextMuted)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(DS.Font.label)
            .foregroundColor(.appTextMuted)
            .textCase(.uppercase)
            .tracking(0.8)
    }
}

// MARK: - Crew step

private struct OnboardingCrewStep: View {

    var onFinish: () -> Void

    @EnvironmentObject var crewStore: CrewStore
    @State private var mode: Mode = .choose
    @State private var crewName: String = ""
    @State private var joinCode: String = ""
    @State private var errorMessage: String?
    @State private var didCreate = false

    private enum Mode { case choose, create, join }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Group {
                switch mode {
                case .choose: chooseView
                case .create: createView
                case .join:   joinView
                }
            }
            Spacer()
            Button(action: onFinish) {
                Text("Skip for now")
                    .font(DS.Font.listItem)
                    .foregroundColor(.appTextMuted)
            }
            .padding(.bottom, 60)
        }
        .padding(.horizontal, DS.Spacing.pageMargin * 2)
    }

    private var chooseView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.appAccent)
            Text("Bring your crew")
                .font(DS.Font.hero)
                .foregroundColor(.appTextPrimary)
            Text("Coordinate schedules and see who's going to the same sets.")
                .font(DS.Font.listItem)
                .foregroundColor(.appTextMuted)
                .multilineTextAlignment(.center)
            VStack(spacing: 10) {
                rowButton(label: "Create a Crew") { mode = .create }
                rowButton(label: "Join a Crew")   { mode = .join }
            }
        }
    }

    private var createView: some View {
        VStack(alignment: .leading, spacing: 16) {
            backButton
            Text("Name your crew")
                .font(DS.Font.hero)
                .foregroundColor(.appTextPrimary)
            TextField("Crew name", text: $crewName)
                .font(DS.Font.listItem)
                .padding(12)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))

            if didCreate, let crew = crewStore.crew {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Share this code with your crew:")
                        .font(DS.Font.metadata)
                        .foregroundColor(.appTextMuted)
                    Text(crew.inviteCode)
                        .font(.system(size: 28, weight: .black, design: .monospaced))
                        .foregroundColor(.appCTA)
                        .tracking(4)
                        .onTapGesture { UIPasteboard.general.string = crew.inviteCode }
                }
                .padding(12)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))

                rowButton(label: "Continue") { onFinish() }
            } else {
                rowButton(label: "Create Crew") {
                    guard !crewName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    crewStore.createCrew(name: crewName)
                    didCreate = true
                }
            }
        }
    }

    private var joinView: some View {
        VStack(alignment: .leading, spacing: 16) {
            backButton
            Text("Enter invite code")
                .font(DS.Font.hero)
                .foregroundColor(.appTextPrimary)
            TextField("6-character code", text: $joinCode)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .tracking(4)
                .autocorrectionDisabled()
                .padding(12)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
                .onChange(of: joinCode) { newValue in
                    joinCode = String(newValue.uppercased().prefix(6))
                }
            if let err = errorMessage {
                Text(err)
                    .font(DS.Font.metadata)
                    .foregroundColor(.appDanger)
            }
            rowButton(label: "Join Crew") {
                crewStore.joinCrew(code: joinCode) { success in
                    if success { onFinish() } else { errorMessage = "Invalid or expired code." }
                }
            }
            .disabled(joinCode.count != 6)
        }
    }

    private var backButton: some View {
        Button(action: { mode = .choose; errorMessage = nil }) {
            Label("Back", systemImage: "chevron.left")
                .font(DS.Font.listItem)
                .foregroundColor(.appTextMuted)
        }
    }

    private func rowButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.appCTA)
                .foregroundColor(Color.appBackground)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        }
    }
}

// MARK: - Color(appHex:) convenience

private extension Color {
    init(appHex hex: String) {
        self.init(uiColor: UIColor(appHex: hex))
    }
}

#Preview {
    OnboardingView()
        .environmentObject(CrewStore())
        .preferredColorScheme(.dark)
}
