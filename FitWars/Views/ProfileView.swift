import SwiftUI

struct ProfileView: View {
    let stats: PlayerStats
    @Environment(AuthManager.self) private var authManager
    @State private var avatar = AvatarConfig.load()
    @State private var showSignOutConfirmation = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            FighterSpriteView(variant: avatar.selectedVariant, size: 120)
                            if !avatar.name.isEmpty {
                                Text(avatar.name)
                                    .font(.headline)
                                    .foregroundStyle(AeroColors.primaryText)
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section("Stats") {
                    statRow("Strength", value: stats.strength, icon: "flame.fill", color: AeroColors.strengthRed)
                    statRow("Stamina", value: stats.stamina, icon: "heart.fill", color: AeroColors.staminaGreen)
                    statRow("Speed", value: stats.speed, icon: "bolt.fill", color: AeroColors.speedBlue)
                }

                Section("Progress") {
                    HStack {
                        Text("Level").foregroundStyle(AeroColors.primaryText)
                        Spacer()
                        Text("\(stats.level)").bold().foregroundStyle(AeroColors.primaryText)
                    }
                    HStack {
                        Text("Total XP").foregroundStyle(AeroColors.primaryText)
                        Spacer()
                        Text("\(stats.totalXP)").bold().foregroundStyle(AeroColors.primaryText)
                    }
                    HStack {
                        Text("XP to next level").foregroundStyle(AeroColors.primaryText)
                        Spacer()
                        Text("\(stats.xpToNextLevel)").bold().foregroundStyle(AeroColors.primaryText)
                    }
                }

                accountSection

                Section("About") {
                    HStack {
                        Text("App").foregroundStyle(AeroColors.primaryText)
                        Spacer()
                        Text(AppConfig.appName).foregroundStyle(AeroColors.secondaryText)
                    }
                    HStack {
                        Text("Version").foregroundStyle(AeroColors.primaryText)
                        Spacer()
                        Text("1.0.0").foregroundStyle(AeroColors.secondaryText)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .aeroBackground()
            .navigationTitle("Profile")
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An unknown error occurred.")
            }
            .confirmationDialog("Sign Out", isPresented: $showSignOutConfirmation) {
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }

    // MARK: - Account Section

    @ViewBuilder
    private var accountSection: some View {
        Section("Account") {
            switch authManager.authState {
            case .anonymous:
                Button {
                    Task { await upgradeToApple() }
                } label: {
                    HStack {
                        Image(systemName: "apple.logo")
                        Text("Upgrade to Apple ID")
                    }
                    .foregroundStyle(AeroColors.primaryAccent)
                }

            case .authenticated(_, let email):
                if let email {
                    HStack {
                        Text("Email").foregroundStyle(AeroColors.primaryText)
                        Spacer()
                        Text(email).foregroundStyle(AeroColors.secondaryText)
                    }
                }
                Button(role: .destructive) {
                    showSignOutConfirmation = true
                } label: {
                    Text("Sign Out")
                }

            default:
                EmptyView()
            }
        }
    }

    private func statRow(_ label: String, value: Int, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(color)
            Text(label).foregroundStyle(AeroColors.primaryText)
            Spacer()
            Text("\(value)").bold().foregroundStyle(AeroColors.primaryText)
        }
    }

    private func upgradeToApple() async {
        do {
            try await authManager.linkAppleCredential()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func signOut() {
        do {
            try authManager.signOut()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
