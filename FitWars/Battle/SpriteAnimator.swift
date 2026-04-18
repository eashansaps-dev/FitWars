import SpriteKit

/// Handles loading texture atlases and playing frame-sequence animations on an `SKSpriteNode`.
///
/// Frame naming convention in atlas: `idle_01`, `idle_02`, `walk_forward_01`, `light_attack_01`, etc.
/// Frames are grouped by prefix — everything before the last `_XX` numeric suffix.
///
/// If the requested atlas is missing from the bundle, a single 128×128 colored-rectangle
/// fallback texture is generated so the sprite always has something to render.
class SpriteAnimator {

    // MARK: - Properties

    private var atlasCache: [String: SKTextureAtlas] = [:]
    private var animations: [String: [SKTexture]] = [:]
    private weak var sprite: SKSpriteNode?
    private(set) var currentAnimation: String = ""
    private var animationActionKey = "spriteAnimation"

    /// Whether an animation is currently running on the sprite.
    var isPlaying: Bool {
        sprite?.action(forKey: animationActionKey) != nil
    }

    /// The name of the current animation (e.g. `"idle"`, `"walk_forward"`).
    var currentFrame: String {
        currentAnimation
    }

    // MARK: - Init

    /// Creates a new animator attached to the given sprite node.
    ///
    /// - Parameters:
    ///   - sprite: The `SKSpriteNode` whose texture will be driven by this animator.
    ///   - atlasName: The name of the texture atlas to load (e.g. `"fighter_default"`).
    init(sprite: SKSpriteNode, atlasName: String) {
        self.sprite = sprite
        loadAnimations(atlasName: atlasName)
    }

    // MARK: - Atlas Loading

    /// Loads a texture atlas by name, groups its frames by animation prefix,
    /// and caches the results. Falls back to loading individual images by name,
    /// then to a colored rectangle if nothing works.
    ///
    /// - Parameter atlasName: Bundle name of the `.atlas` / `.spriteatlas` asset.
    func loadAnimations(atlasName: String) {
        let atlas: SKTextureAtlas

        if let cached = atlasCache[atlasName] {
            atlas = cached
        } else {
            let candidate = SKTextureAtlas(named: atlasName)
            let names = candidate.textureNames
            print("[SpriteAnimator] Atlas '\(atlasName)' has \(names.count) textures: \(names.sorted())")
            
            if names.isEmpty {
                // Atlas not found via SKTextureAtlas — try loading images directly
                print("[SpriteAnimator] ⚠️ Atlas '\(atlasName)' empty — trying direct image loading...")
                if loadImagesDirectly(atlasName: atlasName) {
                    return
                }
                print("[SpriteAnimator] ⚠️ Direct loading also failed — using fallback texture.")
                applyFallbackTexture()
                return
            }
            atlas = candidate
            atlasCache[atlasName] = atlas
        }

        groupFrames(from: atlas)
        print("[SpriteAnimator] Loaded \(animations.count) animations: \(animations.keys.sorted())")
    }
    
    /// Tries to load sprite frames directly as UIImage/SKTexture by name,
    /// bypassing the atlas system. This works when images are in the asset catalog
    /// but the atlas isn't being recognized.
    private func loadImagesDirectly(atlasName: String) -> Bool {
        let frameNames = [
            "idle": ["idle_01", "idle_02", "idle_03", "idle_04"],
            "walk_forward": ["walk_forward_01", "walk_forward_02", "walk_forward_03", "walk_forward_04"],
            "walk_backward": ["walk_backward_01", "walk_backward_02", "walk_backward_03", "walk_backward_04"],
            "light_attack": ["light_attack_01", "light_attack_02", "light_attack_03", "light_attack_04"],
            "heavy_attack": ["heavy_attack_01", "heavy_attack_02"],
            "blocking": ["blocking_01", "blocking_02"],
            "hit_stun": ["hit_stun_01", "hit_stun_02"],
            "dodging": ["dodging_01", "dodging_02"],
            "knockdown": ["knockdown_01"],
            "special_attack": ["special_attack_01", "special_attack_02"],
            "victory": ["victory_01"],
        ]
        
        var loadedAny = false
        
        for (animName, names) in frameNames {
            var textures: [SKTexture] = []
            for name in names {
                // Try loading as UIImage first (works for asset catalog images)
                if let uiImage = UIImage(named: name) {
                    textures.append(SKTexture(image: uiImage))
                } else {
                    // Try with atlas prefix
                    let prefixed = "\(atlasName)/\(name)"
                    let tex = SKTexture(imageNamed: prefixed)
                    // SKTexture(imageNamed:) never returns nil but may return a placeholder
                    // Check if it has a reasonable size
                    if tex.size().width > 1 && tex.size().height > 1 {
                        textures.append(tex)
                    }
                }
            }
            if !textures.isEmpty {
                animations[animName] = textures
                loadedAny = true
            }
        }
        
        if loadedAny {
            print("[SpriteAnimator] Direct loading found \(animations.count) animations: \(animations.keys.sorted())")
            // Set the first idle frame as the sprite's texture
            if let idleFrames = animations["idle"], let first = idleFrames.first {
                sprite?.texture = first
            }
        }
        
        return loadedAny
    }

    // MARK: - Frame Grouping

    /// Parses every texture name in the atlas and groups them by animation prefix.
    ///
    /// Naming convention: `{action}_{frameNumber}` where `action` can itself contain
    /// underscores (e.g. `walk_forward_01`). The prefix is everything before the last
    /// `_` followed by one or more digits.
    private func groupFrames(from atlas: SKTextureAtlas) {
        // Build a dictionary of prefix → sorted texture names
        var groups: [String: [(index: Int, name: String)]] = [:]

        for name in atlas.textureNames {
            let (prefix, index) = parseFrameName(name)
            groups[prefix, default: []].append((index, name))
        }

        // Sort each group by frame index and convert to textures
        for (prefix, frames) in groups {
            let sorted = frames.sorted { $0.index < $1.index }
            animations[prefix] = sorted.map { atlas.textureNamed($0.name) }
        }
    }

    /// Splits a frame name like `"walk_forward_02"` into `("walk_forward", 2)`.
    ///
    /// If the name doesn't match the expected pattern, the entire name is used as
    /// the prefix with index 0.
    private func parseFrameName(_ name: String) -> (prefix: String, index: Int) {
        // Strip file extension if present (e.g. ".png")
        let baseName: String
        if let dotIndex = name.lastIndex(of: ".") {
            baseName = String(name[name.startIndex..<dotIndex])
        } else {
            baseName = name
        }

        // Find the last underscore — everything after it should be digits
        guard let lastUnderscore = baseName.lastIndex(of: "_") else {
            return (baseName, 0)
        }

        let suffix = String(baseName[baseName.index(after: lastUnderscore)...])
        guard let index = Int(suffix) else {
            // The part after the last underscore isn't a number,
            // so treat the whole name as the prefix.
            return (baseName, 0)
        }

        let prefix = String(baseName[baseName.startIndex..<lastUnderscore])
        return (prefix, index)
    }

    // MARK: - Playback

    /// Plays the named animation on the attached sprite.
    ///
    /// - Parameters:
    ///   - animationName: The animation prefix (e.g. `"idle"`, `"walk_forward"`, `"light_attack"`).
    ///   - loop: Whether the animation should repeat forever.
    ///   - blendDuration: Cross-fade time between the current texture and the first frame
    ///     of the new animation. Defaults to 0.05 s.
    func play(_ animationName: String, loop: Bool, blendDuration: TimeInterval = 0.05) {
        guard let sprite else { return }

        // Resolve the animation name — try direct match first, then snake_case conversion
        let resolvedName = resolveAnimationName(animationName)

        guard let frames = animations[resolvedName], !frames.isEmpty else {
            // No frames for this animation — try falling back to idle
            if resolvedName != "idle", let idleFrames = animations["idle"], !idleFrames.isEmpty {
                play("idle", loop: true, blendDuration: blendDuration)
            }
            return
        }

        // Don't restart the same looping animation
        if currentAnimation == resolvedName && loop && isPlaying {
            return
        }

        stop()
        currentAnimation = resolvedName

        // Cross-fade to the first frame of the new animation
        let firstFrame = frames[0]
        let blendAction = SKAction.setTexture(firstFrame, resize: false)

        // Build the frame-sequence action
        let timePerFrame: TimeInterval = 1.0 / 12.0  // 12 FPS sprite animation
        let animateAction = SKAction.animate(with: frames, timePerFrame: timePerFrame)

        let sequence: SKAction
        if loop {
            sequence = SKAction.sequence([
                blendAction,
                SKAction.wait(forDuration: blendDuration),
                SKAction.repeatForever(animateAction)
            ])
        } else {
            sequence = SKAction.sequence([
                blendAction,
                SKAction.wait(forDuration: blendDuration),
                animateAction
            ])
        }

        sprite.run(sequence, withKey: animationActionKey)
    }

    /// Stops the current animation and clears the action.
    func stop() {
        sprite?.removeAction(forKey: animationActionKey)
    }

    // MARK: - Name Resolution

    /// Maps camelCase `FighterState` raw values to the snake_case atlas prefix convention.
    ///
    /// For example `"walkForward"` → `"walk_forward"`, `"lightAttack"` → `"light_attack"`.
    /// If the name already exists as-is in the animations dictionary, it's returned unchanged.
    private func resolveAnimationName(_ name: String) -> String {
        // Direct match — no conversion needed
        if animations[name] != nil {
            return name
        }

        // Convert camelCase to snake_case
        let snakeCased = camelToSnake(name)
        if animations[snakeCased] != nil {
            return snakeCased
        }

        // Return the snake_case version regardless — the caller handles missing keys
        return snakeCased
    }

    /// Converts a camelCase string to snake_case.
    ///
    /// `"walkForward"` → `"walk_forward"`, `"lightAttack"` → `"light_attack"`.
    private func camelToSnake(_ input: String) -> String {
        var result = ""
        for (i, char) in input.enumerated() {
            if char.isUppercase {
                if i > 0 {
                    result += "_"
                }
                result += char.lowercased()
            } else {
                result += String(char)
            }
        }
        return result
    }

    // MARK: - Fallback

    /// Creates a 128×128 colored-rectangle texture and assigns it to the sprite
    /// so there's always something visible even without real art assets.
    private func applyFallbackTexture() {
        let size = CGSize(width: 128, height: 128)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.systemPurple.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        let texture = SKTexture(image: image)
        sprite?.texture = texture
        sprite?.size = size

        // Store as a single-frame "idle" so play("idle") doesn't break
        animations["idle"] = [texture]
    }

    // MARK: - Query

    /// Returns the list of loaded animation names (e.g. `["idle", "walk_forward", "light_attack"]`).
    var availableAnimations: [String] {
        Array(animations.keys).sorted()
    }

    /// Returns the frame count for a given animation, or 0 if not loaded.
    func frameCount(for animationName: String) -> Int {
        let resolved = resolveAnimationName(animationName)
        return animations[resolved]?.count ?? 0
    }
}
