import SwiftUI

struct AvatarCustomizerView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(AuthManager.self) private var authManager
    @Environment(FirestoreService.self) private var firestoreService
    @State private var config = AvatarConfig()
    @State private var step = 0

    private let steps = ["Name", "Skin", "Face", "Eyes", "Hair", "Outfit"]

    var body: some View {
        VStack(spacing: 20) {
            Text(AppConfig.appName)
                .font(.title2.bold())
                .foregroundStyle(AeroColors.primaryText)

            // Live preview
            AvatarRenderer(config: config, size: 150)
                .animation(.easeInOut(duration: 0.2), value: config)

            if !config.name.isEmpty {
                Text(config.name)
                    .font(.headline)
                    .foregroundStyle(AeroColors.primaryText)
            }

            // Step indicator
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { i in
                    Circle()
                        .fill(i == step ? AeroColors.primaryAccent : AeroColors.skyBlue.opacity(0.2))
                        .frame(width: 8, height: 8)
                }
            }

            Text(steps[step])
                .font(.headline)
                .foregroundStyle(AeroColors.secondaryText)

            // Step content
            Group {
                switch step {
                case 0: nameStep
                case 1: skinStep
                case 2: faceStep
                case 3: eyeStep
                case 4: hairStep
                case 5: outfitStep
                default: EmptyView()
                }
            }
            .frame(maxHeight: 160)

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
        TextField("Fighter Name", text: $config.name)
            .font(.title3)
            .textFieldStyle(.roundedBorder)
            .padding(.horizontal)
    }

    private var skinStep: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
            ForEach(AvatarConfig.skinTones, id: \.red) { tone in
                Circle()
                    .fill(tone.color)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle().stroke(AeroColors.primaryAccent, lineWidth: config.skinTone == tone ? 3 : 0)
                    )
                    .onTapGesture { config.skinTone = tone }
            }
        }
        .padding(.horizontal)
    }

    private var faceStep: some View {
        HStack(spacing: 16) {
            ForEach(AvatarConfig.FaceShape.allCases, id: \.self) { shape in
                VStack(spacing: 6) {
                    Image(systemName: shape.icon)
                        .font(.title)
                        .frame(width: 50, height: 50)
                        .background(config.faceShape == shape ? AeroColors.skyBlue.opacity(0.15) : .gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Text(shape.rawValue.capitalized)
                        .font(.caption)
                }
                .foregroundStyle(config.faceShape == shape ? AeroColors.primaryAccent : AeroColors.secondaryText)
                .onTapGesture { config.faceShape = shape }
            }
        }
    }

    private var eyeStep: some View {
        HStack(spacing: 16) {
            ForEach(AvatarConfig.EyeStyle.allCases, id: \.self) { style in
                VStack(spacing: 6) {
                    Image(systemName: "eye")
                        .font(.title)
                        .frame(width: 50, height: 50)
                        .background(config.eyeStyle == style ? AeroColors.skyBlue.opacity(0.15) : .gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Text(style.label)
                        .font(.caption)
                }
                .foregroundStyle(config.eyeStyle == style ? AeroColors.primaryAccent : AeroColors.secondaryText)
                .onTapGesture { config.eyeStyle = style }
            }
        }
    }

    private var hairStep: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AvatarConfig.HairStyle.allCases, id: \.self) { style in
                        Text(style.label)
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(config.hairStyle == style ? AeroColors.primaryAccent : .gray.opacity(0.15))
                            .foregroundStyle(config.hairStyle == style ? .white : AeroColors.primaryText)
                            .clipShape(Capsule())
                            .onTapGesture { config.hairStyle = style }
                    }
                }
                .padding(.horizontal)
            }

            if config.hairStyle != .bald {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                    ForEach(AvatarConfig.hairColors, id: \.red) { color in
                        Circle()
                            .fill(color.color)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle().stroke(AeroColors.primaryAccent, lineWidth: config.hairColor == color ? 3 : 0)
                            )
                            .onTapGesture { config.hairColor = color }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var outfitStep: some View {
        HStack(spacing: 16) {
            ForEach(AvatarConfig.Outfit.allCases, id: \.self) { outfit in
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(outfitColor(outfit))
                        .frame(width: 50, height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AeroColors.primaryAccent, lineWidth: config.outfit == outfit ? 3 : 0)
                        )
                    Text(outfit.label)
                        .font(.caption)
                }
                .foregroundStyle(config.outfit == outfit ? AeroColors.primaryAccent : AeroColors.secondaryText)
                .onTapGesture { config.outfit = outfit }
            }
        }
    }

    private func outfitColor(_ outfit: AvatarConfig.Outfit) -> Color {
        switch outfit {
        case .gi: .white
        case .tankTop: .gray
        case .hoodie: .indigo
        case .armor: AeroColors.primaryAccent
        }
    }
}
