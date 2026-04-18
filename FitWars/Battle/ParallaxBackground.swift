import SpriteKit

/// Multi-layer scrolling stage backdrop that creates depth via parallax.
/// Satisfies Requirement 2 (Stage and Parallax Background).
class ParallaxBackground: SKNode {

    // MARK: - Types

    struct Layer {
        let node: SKSpriteNode
        let speedFactor: CGFloat   // 0.2 (far) … 1.0 (near)
        let duplicate: SKSpriteNode // second copy for seamless wrapping
    }

    // MARK: - Properties

    private var layers: [Layer] = []
    private let sceneSize: CGSize

    // MARK: - Init (Task 10.1)

    /// Loads three texture layers for the given stage and sets up seamless
    /// horizontal wrapping. Falls back to a gradient when textures are missing.
    ///
    /// Texture naming convention:
    ///   `{stageID}_bg_far`, `{stageID}_bg_mid`, `{stageID}_bg_near`
    ///
    /// - Parameters:
    ///   - stageID: Identifier used to look up stage textures in the asset catalog.
    ///   - sceneSize: The scene's point size (used for positioning and fallback).
    init(stageID: String, sceneSize: CGSize) {
        self.sceneSize = sceneSize
        super.init()

        let layerDefs: [(suffix: String, speed: CGFloat, zPos: CGFloat)] = [
            ("far",  0.2, -30),
            ("mid",  0.5, -20),
            ("near", 1.0, -10)
        ]

        var loadedAny = false

        for def in layerDefs {
            let textureName = "\(stageID)_bg_\(def.suffix)"

            if textureExists(named: textureName) {
                let texture = SKTexture(imageNamed: textureName)
                addLayer(texture: texture, speedFactor: def.speed, zPosition: def.zPos)
                loadedAny = true
            }
        }

        // Task 10.3: If no stage textures were found, use the fallback gradient.
        if !loadedAny {
            print("⚠️ ParallaxBackground: stage textures for '\(stageID)' not found – using fallback gradient")
            let fallback = ParallaxBackground.fallbackGradient(sceneSize: sceneSize)
            fallback.zPosition = -30
            addChild(fallback)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    // MARK: - Per-Frame Update (Task 10.1)

    /// Scrolls every layer based on the current camera X position.
    /// Each layer moves at `cameraX * speedFactor`. The duplicate copy is
    /// repositioned to keep the seam invisible.
    func update(cameraX: CGFloat) {
        for layer in layers {
            let offset = cameraX * layer.speedFactor
            let width = layer.node.size.width

            // Primary node position
            layer.node.position.x = -offset.truncatingRemainder(dividingBy: width)
            // Duplicate sits directly to the right
            layer.duplicate.position.x = layer.node.position.x + width

            // If the primary scrolled too far left, swap positions so
            // there's always a copy covering the visible area.
            if layer.node.position.x < -width {
                layer.node.position.x += width * 2
            }
            if layer.duplicate.position.x < -width {
                layer.duplicate.position.x += width * 2
            }
        }
    }

    // MARK: - Fallback Gradient (Task 10.2)

    /// Creates a vertical gradient node (dark blue → dark purple) suitable as
    /// a stage background when real textures are unavailable.
    static func fallbackGradient(sceneSize: CGSize) -> SKNode {
        let container = SKNode()

        // Build the gradient with horizontal strips.
        let stripCount = 32
        let stripHeight = sceneSize.height / CGFloat(stripCount)

        // Top color: dark blue
        let topR: CGFloat = 0.05
        let topG: CGFloat = 0.05
        let topB: CGFloat = 0.25

        // Bottom color: dark purple
        let botR: CGFloat = 0.15
        let botG: CGFloat = 0.02
        let botB: CGFloat = 0.20

        for i in 0..<stripCount {
            let t = CGFloat(i) / CGFloat(stripCount - 1) // 0 = top, 1 = bottom

            let r = topR + (botR - topR) * t
            let g = topG + (botG - topG) * t
            let b = topB + (botB - topB) * t

            let strip = SKSpriteNode(color: SKColor(red: r, green: g, blue: b, alpha: 1.0),
                                     size: CGSize(width: sceneSize.width, height: stripHeight + 1)) // +1 avoids sub-pixel gaps
            strip.anchorPoint = CGPoint(x: 0.5, y: 0)
            strip.position = CGPoint(x: sceneSize.width / 2,
                                     y: sceneSize.height - CGFloat(i + 1) * stripHeight)
            container.addChild(strip)
        }

        return container
    }

    // MARK: - Private Helpers

    /// Adds a parallax layer (and its duplicate) for seamless horizontal wrapping.
    private func addLayer(texture: SKTexture, speedFactor: CGFloat, zPosition: CGFloat) {
        let primary = SKSpriteNode(texture: texture)
        primary.anchorPoint = CGPoint(x: 0, y: 0)
        primary.size = CGSize(width: max(texture.size().width, sceneSize.width),
                              height: sceneSize.height)
        primary.position = .zero
        primary.zPosition = zPosition
        addChild(primary)

        let duplicate = SKSpriteNode(texture: texture)
        duplicate.anchorPoint = CGPoint(x: 0, y: 0)
        duplicate.size = primary.size
        duplicate.position = CGPoint(x: primary.size.width, y: 0)
        duplicate.zPosition = zPosition
        addChild(duplicate)

        layers.append(Layer(node: primary, speedFactor: speedFactor, duplicate: duplicate))
    }

    /// Returns `true` when the named image actually exists in the asset catalog
    /// (as opposed to SpriteKit silently returning a placeholder).
    private func textureExists(named name: String) -> Bool {
        // UIImage(named:) returns nil when the asset doesn't exist,
        // whereas SKTexture(imageNamed:) never returns nil.
        return UIImage(named: name) != nil
    }
}
