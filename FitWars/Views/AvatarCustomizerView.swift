import SwiftUI

struct AvatarCustomizerView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(AuthManager.self) private var authManager
    @Environment(FirestoreService.self) private var firestoreService
    @State private var config = AvatarConfig()
    @State private var step = 0

    private let steps = ["Name", "Fighter"]

    var body: some View {
        VStack(spacing: 24) {
            Text(AppConfig.appName)
                .font(.title2.bold())
                .foregroundStyle(AeroColors.primaryText)

            // Live preview
            FighterSpriteView(variant: config.selectedVariant, size: 160)

            if !config.name.isEmpty {
                Text(config.name)
                    .font(.title3.bold())
                    .foregroundStyle(AeroColors.primaryText)
            }

            Text(config.selectedVariant.displayName)
                .font(.subheadline)
                .foregroundStyle(AeroColors.secondaryText)

            // Step indicator
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { i in
                    Circle()
                        .fill(i == step ? AeroColors.primaryAccent : AeroColors.skyBlue.opacity(0.2))
                        .frame(width: 8, height: 8)
                }
            }

            // Step content
            Group {
                switch step {
                case 0: nameStep
                case 1: fighterPickerStep
                default: EmptyView()
                }
            }

            Spacer()

            // Navigation
            HStack(spacing: 16) {
                if step > 0 {
                    Button("Back") { step -= 1 }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AeroColors.pearl)
                        .foregroundStyle(AeroColors.primaryText)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }

                Button(step == steps.count - 1 ? "Let's Fight" : "Next") {
                    if step == steps.count - 1 {
                        config.save()
                        if let userId = authManager.currentUserId {
                            Task {
                                try? await firestoreService.updateAvatarConfig(
                                    userId: userId,
                                    avatarConfig: config
                                )
                            }
                        }
                        hasCompletedOnboarding = true
                    } else {
                        step += 1
                    }
                }
                .disabled(step == 0 && config.name.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(AeroButtonStyle(
                    gradient: step == 0 && config.name.trimmingCharacters(in: .whitespaces).isEmpty
                        ? LinearGradient(colors: [.gray], startPoint: .top, endPoint: .bottom)
                        : AeroGradients.buttonPrimary
                ))
            }
            .padding(.horizontal)
        }
        .padding()
        .aeroBackground()
        .task {
            if let userId = authManager.currentUserId {
                if let profile = try? await firestoreService.fetchUserProfile(userId: userId) {
                    config = profile.avatarConfig
                }
            }
        }
    }

    // MARK: - Steps

    private var nameStep: some View {
        VStack(spacing: 12) {
            Text("Choose your fighter name")
                .font(.headline)
                .foregroundStyle(AeroColors.secondaryText)
            TextField("Fighter Name", text: $config.name)
                .font(.title3)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 32)
        }
    }

    private var fighterPickerStep: some View {
        VStack(spacing: 12) {
            Text("Choose your fighter")
                .font(.headline)
                .foregroundStyle(AeroColors.secondaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(FighterVariant.allCases) { variant in
                        VStack(spacing: 8) {
                            FighterSpriteView(variant: variant, size: 80)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            config.selectedVariant == variant
                                                ? AeroColors.primaryAccent
                                                : Color.clear,
                                            lineWidth: 3
                                        )
                                )

                            Text(variant.displayName)
                                .font(.caption)
                                .foregroundStyle(
                                    config.selectedVariant == variant
                                        ? AeroColors.primaryAccent
                                        : AeroColors.secondaryText
                                )
                        }
                        .onTapGesture {
                            config.selectedVariant = variant
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
