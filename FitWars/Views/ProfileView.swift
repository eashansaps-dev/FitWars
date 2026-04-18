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
                            AvatarRenderer(config: avatar, size: 100)
                            if !avatar.name.isEmpty {
                                Text(avatar.name)
                                    .font(.headline)
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section("Stats") {
                    statRow("Strength", value: stats.strength, icon: "flame.fill", color: .red)
                    statRow("Stamina", value: stats.stamina, icon: "heart.fill", color: .green)
                    statRow("Speed", value: stats.speed, icon: "bolt.fill", color: .blue)
                }

                Section("Progress") {
                    HStack { Text("Level"); Spacer(); Text("\(stats.level)").bold() }
                    HStack { Text("Total XP"); Spacer(); Text("\(stats.totalXP)").bold() }
                    HStack { Text("XP to next level"); Spacer(); Text("\(stats.xpToNextLevel)").bold() }
                }

                // Task 7.1: Account section
                accountSection

                Section("About") {
                    HStack { Text("App"); Spacer(); Text(AppConfig.appName).foregroundStyle(.secondary) }
                    HStack { Text("Version"); Spacer(); Text("1.0.0").foregroundStyle(.secondary) }
                }
            }
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
                // Task 7.2: Upgrade prompt for anonymous users
                Button {
                    Task { await upgradeToApple() }
                } label: {
                    HStack {
                        Image(systemName: "apple.logo")
                        Text("Upgrade to Apple ID")
                    }
                }

            case .authenticated(_, let email):
                // Task 7.3: Show email + sign out
                if let email {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(email)
                            .foregroundStyle(.secondary)
                    }
                }
                // Task 7.4: Sign out button
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
            Text(label)
            Spacer()
            Text("\(value)").bold()
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
