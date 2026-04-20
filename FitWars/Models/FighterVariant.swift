import SwiftUI

/// Available pre-rendered fighter character variants.
/// Each maps to a sprite atlas and an idle image for UI display.
enum FighterVariant: String, Codable, CaseIterable, Identifiable {
    case defaultMale = "fighter_default"
    case female = "fighter_female"
    case darkSkin = "fighter_dark"
    case blonde = "fighter_blonde"
    case redHair = "fighter_redhair"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .defaultMale: "Fighter"
        case .female: "Kunoichi"
        case .darkSkin: "Striker"
        case .blonde: "Blaze"
        case .redHair: "Inferno"
        }
    }

    /// The sprite atlas name used in SpriteKit battles.
    var atlasName: String { rawValue }

    /// The idle sprite image name in the Sprites bundle folder.
    var idleImageName: String { "idle_01" }
}
