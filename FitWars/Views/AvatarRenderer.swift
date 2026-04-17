import SwiftUI

struct AvatarRenderer: View {
    let config: AvatarConfig
    var size: CGFloat = 200

    private var s: CGFloat { size / 200 }

    var body: some View {
        ZStack {
            outfitShape
            armsShape
            headShape
            hairShape
            eyesShape
            noseShape
            mouthShape
        }
        .frame(width: size, height: size * 1.6)
    }

    // MARK: - Head

    private var headShape: some View {
        let shape: some Shape = switch config.faceShape {
        case .oval: AnyShape(Ellipse())
        case .square: AnyShape(RoundedRectangle(cornerRadius: 8 * s))
        case .round: AnyShape(Circle())
        case .angular: AnyShape(RoundedRectangle(cornerRadius: 4 * s))
        }
        return shape
            .fill(config.skinTone.color)
            .frame(width: 70 * s, height: 80 * s)
            .overlay(shape.stroke(.black.opacity(0.1), lineWidth: 1 * s))
            .offset(y: -90 * s)
    }

    // MARK: - Eyes

    private var eyesShape: some View {
        HStack(spacing: 14 * s) { singleEye; singleEye }
            .offset(y: -96 * s)
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
            .frame(width: w * s, height: h * s)
            .overlay(Circle().fill(.black).frame(width: 5 * s, height: 5 * s))
    }

    // MARK: - Nose

    private var noseShape: some View {
        Ellipse()
            .fill(config.skinTone.color.opacity(0.7))
            .frame(width: 8 * s, height: 6 * s)
            .overlay(Ellipse().stroke(.black.opacity(0.15), lineWidth: 0.5 * s))
            .offset(y: -85 * s)
    }

    // MARK: - Mouth

    private var mouthShape: some View {
        // Smile arc
        Capsule()
            .fill(Color(red: 0.8, green: 0.3, blue: 0.3))
            .frame(width: 18 * s, height: 6 * s)
            .overlay(
                // Upper lip curve to make it look like a smile
                Capsule()
                    .fill(Color(red: 0.9, green: 0.4, blue: 0.4))
                    .frame(width: 14 * s, height: 3 * s)
                    .offset(y: -1 * s)
            )
            .offset(y: -76 * s)
    }

    // MARK: - Arms

    private var armsShape: some View {
        let outfitColor: Color = switch config.outfit {
        case .gi: .white
        case .tankTop: .gray
        case .hoodie: .indigo
        case .armor: .orange
        }
        return HStack(spacing: 74 * s) {
            // Left arm
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 4 * s)
                    .fill(outfitColor.opacity(0.9))
                    .frame(width: 20 * s, height: 50 * s)
                // Hand
                Circle()
                    .fill(config.skinTone.color)
                    .frame(width: 16 * s)
            }
            // Right arm
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 4 * s)
                    .fill(outfitColor.opacity(0.9))
                    .frame(width: 20 * s, height: 50 * s)
                Circle()
                    .fill(config.skinTone.color)
                    .frame(width: 16 * s)
            }
        }
        .offset(y: 10 * s)
    }

    // MARK: - Hair

    private var hairShape: some View {
        Group {
            switch config.hairStyle {
            case .bald:
                EmptyView()
            case .short:
                RoundedRectangle(cornerRadius: 10 * s)
                    .fill(config.hairColor.color)
                    .frame(width: 74 * s, height: 30 * s)
                    .offset(y: -128 * s)
            case .long:
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 10 * s)
                        .fill(config.hairColor.color)
                        .frame(width: 78 * s, height: 30 * s)
                    RoundedRectangle(cornerRadius: 4 * s)
                        .fill(config.hairColor.color)
                        .frame(width: 84 * s, height: 50 * s)
                }
                .offset(y: -118 * s)
            case .mohawk:
                RoundedRectangle(cornerRadius: 4 * s)
                    .fill(config.hairColor.color)
                    .frame(width: 20 * s, height: 50 * s)
                    .offset(y: -140 * s)
            case .braids:
                HStack(spacing: 4 * s) {
                    ForEach(0..<5, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2 * s)
                            .fill(config.hairColor.color)
                            .frame(width: 8 * s, height: 45 * s)
                    }
                }
                .offset(y: -120 * s)
            case .ponytail:
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 10 * s)
                        .fill(config.hairColor.color)
                        .frame(width: 74 * s, height: 25 * s)
                    Circle()
                        .fill(config.hairColor.color)
                        .frame(width: 20 * s)
                        .offset(x: 40 * s, y: -5 * s)
                }
                .offset(y: -128 * s)
            }
        }
    }

    // MARK: - Outfit / Body

    private var outfitShape: some View {
        let c: Color = switch config.outfit {
        case .gi: .white
        case .tankTop: .gray
        case .hoodie: .indigo
        case .armor: .orange
        }
        return VStack(spacing: 0) {
            // Torso
            RoundedRectangle(cornerRadius: 8 * s)
                .fill(c)
                .frame(width: 90 * s, height: 80 * s)
                .overlay(RoundedRectangle(cornerRadius: 8 * s).stroke(.black.opacity(0.1), lineWidth: 1 * s))
            // Legs
            HStack(spacing: 6 * s) {
                RoundedRectangle(cornerRadius: 4 * s).fill(c.opacity(0.85))
                    .frame(width: 36 * s, height: 70 * s)
                RoundedRectangle(cornerRadius: 4 * s).fill(c.opacity(0.85))
                    .frame(width: 36 * s, height: 70 * s)
            }
            // Feet
            HStack(spacing: 10 * s) {
                RoundedRectangle(cornerRadius: 4 * s).fill(.black)
                    .frame(width: 34 * s, height: 14 * s)
                RoundedRectangle(cornerRadius: 4 * s).fill(.black)
                    .frame(width: 34 * s, height: 14 * s)
            }
        }
        .offset(y: 30 * s)
    }
}

#Preview {
    HStack(spacing: 30) {
        AvatarRenderer(config: AvatarConfig(
            name: "Blaze", skinTone: AvatarConfig.skinTones[1],
            faceShape: .square, eyeStyle: .fierce, hairStyle: .mohawk,
            hairColor: AvatarConfig.hairColors[6], outfit: .armor
        ), size: 140)

        AvatarRenderer(config: AvatarConfig(
            name: "Shadow", skinTone: AvatarConfig.skinTones[4],
            faceShape: .oval, eyeStyle: .normal, hairStyle: .braids,
            hairColor: AvatarConfig.hairColors[0], outfit: .gi
        ), size: 140)

        AvatarRenderer(config: AvatarConfig(
            name: "Viper", skinTone: AvatarConfig.skinTones[2],
            faceShape: .round, eyeStyle: .wide, hairStyle: .long,
            hairColor: AvatarConfig.hairColors[7], outfit: .hoodie
        ), size: 140)
    }
    .padding()
}
