import SwiftUI

struct AvatarConfig: Codable, Equatable {
    var name: String = ""
    var skinTone: CodableColor = CodableColor(.brown)
    var faceShape: FaceShape = .oval
    var eyeStyle: EyeStyle = .normal
    var hairStyle: HairStyle = .short
    var hairColor: CodableColor = CodableColor(.black)
    var outfit: Outfit = .gi

    enum FaceShape: String, Codable, CaseIterable {
        case oval, square, round, angular
        var icon: String {
            switch self {
            case .oval: "oval.portrait"
            case .square: "square"
            case .round: "circle"
            case .angular: "diamond"
            }
        }
    }

    enum EyeStyle: String, Codable, CaseIterable {
        case normal, narrow, wide, fierce
        var label: String { rawValue.capitalized }
    }

    enum HairStyle: String, Codable, CaseIterable {
        case bald, short, long, mohawk, braids, ponytail
        var label: String { rawValue.capitalized }
    }

    enum Outfit: String, Codable, CaseIterable {
        case gi, tankTop, hoodie, armor
        var label: String {
            switch self {
            case .gi: "Gi"
            case .tankTop: "Tank Top"
            case .hoodie: "Hoodie"
            case .armor: "Armor"
            }
        }
    }
}

// MARK: - Color Codable wrapper

struct CodableColor: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double

    init(_ color: Color) {
        let resolved = UIColor(color)
        var r: CGFloat = 0; var g: CGFloat = 0; var b: CGFloat = 0
        resolved.getRed(&r, green: &g, blue: &b, alpha: nil)
        self.red = Double(r); self.green = Double(g); self.blue = Double(b)
    }

    init(r: Double, g: Double, b: Double) {
        self.red = r; self.green = g; self.blue = b
    }

    var color: Color { Color(red: red, green: green, blue: blue) }
}

// MARK: - Preset skin tones

extension AvatarConfig {
    static let skinTones: [CodableColor] = [
        CodableColor(r: 1.0, g: 0.87, b: 0.75),   // light
        CodableColor(r: 0.96, g: 0.76, b: 0.57),   // fair
        CodableColor(r: 0.84, g: 0.63, b: 0.42),   // medium
        CodableColor(r: 0.70, g: 0.49, b: 0.32),   // tan
        CodableColor(r: 0.55, g: 0.36, b: 0.24),   // brown
        CodableColor(r: 0.36, g: 0.22, b: 0.14),   // dark
    ]

    static let hairColors: [CodableColor] = [
        CodableColor(r: 0.1, g: 0.1, b: 0.1),      // black
        CodableColor(r: 0.35, g: 0.2, b: 0.1),      // dark brown
        CodableColor(r: 0.6, g: 0.35, b: 0.15),     // brown
        CodableColor(r: 0.9, g: 0.75, b: 0.3),      // blonde
        CodableColor(r: 0.7, g: 0.2, b: 0.1),       // red
        CodableColor(r: 0.7, g: 0.7, b: 0.7),       // gray
        CodableColor(r: 0.2, g: 0.4, b: 0.9),       // blue
        CodableColor(r: 0.8, g: 0.2, b: 0.5),       // pink
    ]
}

// MARK: - Persistence

extension AvatarConfig {
    static let storageKey = "avatarConfig"

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    static func load() -> AvatarConfig {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let config = try? JSONDecoder().decode(AvatarConfig.self, from: data)
        else { return AvatarConfig() }
        return config
    }
}
