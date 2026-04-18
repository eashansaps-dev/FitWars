import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App branding
            Image(systemName: "figure.martial.arts")
                .font(.system(size: 64))
                .foregroundStyle(AeroColors.primaryAccent)

            Text(AppConfig.appName)
                .font(.largeTitle.bold())
                .foregroundStyle(AeroColors.primaryText)

            Text("Track your fitness.\nFight your way to the top.")
                .font(.subheadline)
                .foregroundStyle(AeroColors.secondaryText)
                .multilineTextAlignment(.center)

            Spacer()

            if isLoading {
                ProgressView()
            } else {
                // Sign in with Apple
                Button {
                    Task { await signInWithApple() }
                } label: {
                    HStack {
                        Image(systemName: "apple.logo")
                        Text("Sign in with Apple")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.white)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(AeroColors.glassBorder, lineWidth: 1)
                    )
                    .shadow(color: AeroColors.skyBlue.opacity(0.12), radius: 8, y: 4)
                }
                .padding(.horizontal, 32)

                // Continue as Guest
                Button {
                    Task { await signInAnonymously() }
                } label: {
                    Text("Continue as Guest")
                        .foregroundStyle(AeroColors.secondaryText)
                }
            }

            Spacer()
                .frame(height: 32)
        }
        .aeroBackground()
        .alert("Sign In Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
    }

    private func signInWithApple() async {
        isLoading = true
        defer { isLoading = false }
        do {
            if case .anonymous = authManager.authState {
                try await authManager.linkAppleCredential()
            } else {
                try await authManager.signInWithApple()
            }
        } catch let error as AuthManagerError where error == .credentialAlreadyInUse {
            errorMessage = "This Apple ID is already linked to another account. Please sign in with that account instead."
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func signInAnonymously() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await authManager.signInAnonymously()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
