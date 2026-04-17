import SwiftUI

struct AvatarRenderer: View {
    let config: AvatarConfig
    var size: CGFloat = 200

    private var scale: CGFloat { size / 200 }

    var body: some View {
        ZStack {
            // Body / Outfit
            outfitShape
            // Head
            headShape
            // Hair
            hairShape
            // Eyes
            eyesShape
        }
        .frame(width: size, height: size * 1.6)
    }

    // MARK: - Head

    private var headShape: some View {
        let shape: some Shape = switch config.faceShape {
        case .oval: AnyShape(Ellipse())
        case .square: AnyShape(RoundedRectangle(cornerRadius: 8 * scale))
        case .round: AnyShape(Circle())
        case .angular: AnyShape(RoundedRectangle(cornerRadius: 4 * scale))
        }

        return shape
            .fill(config.skinTone.color)
            .frame(width: 70 * scale, height: 80 * scale)
            .overlay(
                shape.stroke(config.skinTone.color.opacity(0.6), lineWidth: 2 * scale)
            )
            .offset(y: -90 * scale)
    }

    // MARK: - Eyes

    private var eyesShape: some View {
        HStack(spacing: 14 * scale) {
            singleEye
            singleEye
        }
        .offset(y: -92 * scale)
    }

    private var singleEye: some View {
        let h: CGFloat = switch config.eyeStyle {
        case .normal: 8
        case .narrow: 5
        case .wide: 11
        case .fierce: 7
        }
        let w: CGFloat = config.eyeStyle == .fierce ? 14 : 10

        return Ellipse()
            .fill(.white)
            .frame(width: w * scale, height: h * scale)
            .overlay(
                Circle()
                    .fill(.black)
                    .frame(width: 5 * scale, height: 5 * scale)
            )
    }

    // MARK: - Hair

    private var hairShape: some View {
        Group {
            switch config.hairStyle {
            case .bald:
                EmptyView()
            case .short:
                RoundedRectangle(cornerRadius: 10 * scale)
                    .fill(config.hairColor.color)
                    .frame(width: 74 * scale, height: 30 * scale)
                    .offset(y: -128 * scale)
            case .long:
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 10 * scale)
                        .fill(config.hairColor.color)
                        .frame(width: 78 * scale, height: 30 * scale)
                    RoundedRectangle(cornerRadius: 4 * scale)
                        .fill(config.hairColor.color)
                        .frame(width: 84 * scale, height: 50 * scale)
                }
                .offset(y: -118 * scale)
            case .mohawk:
                RoundedRectangle(cornerRadius: 4 * scale)
                    .fill(config.hairColor.color)
                    .frame(width: 20 * scale, height: 50 * scale)
                    .offset(y: -140 * scale)
            case .braids:
                HStack(spacing: 4 * scale) {
                    ForEach(0..<5, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2 * scale)
                            .fill(config.hairColor.color)
                            .frame(width: 8 * scale, height: 45 * scale)
                    }
                }
                .offset(y: -120 * scale)
            case .ponytail:
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 10 * scale)
                        .fill(config.hairColor.color)
                        .frame(width: 74 * scale, height: 25 * scale)
                    Circle()
                        .fill(config.hairColor.color)
                        .frame(width: 20 * scale)
                        .offset(x: 40 * scale, y: -5 * scale)
                }
                .offset(y: -128 * scale)
            }
        }
    }

    // MARK: - Outfit / Body

    private var outfitShape: some View {
        let outfitColor: Color = switch config.outfit {
        case .gi: .white
        case .tankTop: .gray
        case .hoodie: .indigo
        case .armor: .orange
        }

        return VStack(spacing: 0) {
            // Torso
            RoundedRectangle(cornerRadius: 8 * scale)
                .fill(outfitColor)
                .frame(width: 90 * scale, height: 80 * scale)
                .overlay(
                    RoundedRectangle(cornerRadius: 8 * scale)
                        .stroke(outfitColor.opacity(0.5), lineWidth: 2 * scale)
                )
            // Legs
            HStack(spacing: 6 * scale) {
                RoundedRectangle(cornerRadius: 4 * scale)
                    .fill(outfitColor.opacity(0.85))
                    .frame(width: 36 * scale, height: 70 * scale)
                RoundedRectangle(cornerRadius: 4 * scale)
                    .fill(outfitColor.opacity(0.85))
                    .frame(width: 36 * scale, height: 70 * scale)
            }
            // Feet
            HStack(spacing: 10 * scale) {
                RoundedRectangle(cornerRadius: 4 * scale)
                    .fill(.black)
                    .frame(width: 34 * scale, height: 14 * scale)
                RoundedRectangle(cornerRadius: 4 * scale)
                    .fill(.black)
                    .frame(width: 34 * scale, height: 14 * scale)
            }
        }
        .offset(y: 30 * scale)
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 30) {
            AvatarRenderer(config: AvatarConfig(
                name: "Blaze",
                skinTone: AvatarConfig.skinTones[1],
                faceShape: .square,
                eyeStyle: .fierce,
                hairStyle: .mohawk,
                hairColor: AvatarConfig.hairColors[6],
                outfit: .armor
            ), size: 120)

            AvatarRenderer(config: AvatarConfig(
                name: "Shadow",
                skinTone: AvatarConfig.skinTones[4],
                faceShape: .oval,
                eyeStyle: .normal,
                hairStyle: .braids,
                hairColor: AvatarConfig.hairColors[0],
                outfit: .gi
            ), size: 120)

            AvatarRenderer(config: AvatarConfig(
                name: "Viper",
                skinTone: AvatarConfig.skinTones[2],
                faceShape: .round,
                eyeStyle: .wide,
                hairStyle: .long,
                hairColor: AvatarConfig.hairColors[7],
                outfit: .hoodie
            ), size: 120)
        }
    }
    .padding()
}
