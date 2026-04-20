import SwiftUI

/// Displays a fighter's idle sprite image for use in SwiftUI screens
/// (Dashboard, Profile, Battle preview). Replaces the old shape-based AvatarRenderer.
struct FighterSpriteView: View {
    var variant: FighterVariant = .defaultMale
    var size: CGFloat = 200

    var body: some View {
        Group {
            if let path = Bundle.main.path(forResource: variant.idleImageName, ofType: "png"),
               let uiImage = UIImage(contentsOfFile: path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            } else {
                // Fallback — system icon
                Image(systemName: "figure.martial.arts")
                    .font(.system(size: size * 0.5))
                    .foregroundStyle(AeroColors.primaryAccent)
                    .frame(width: size, height: size)
            }
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        ForEach(FighterVariant.allCases) { variant in
            VStack {
                FighterSpriteView(variant: variant, size: 100)
                Text(variant.displayName)
                    .font(.caption)
            }
        }
    }
}
