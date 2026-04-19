import SpriteKit

/// Dynamic camera system that frames both fighters, zooms on key moments,
/// and applies screen shake. Satisfies Requirement 7 (Dynamic Camera System).
class CameraController {

    // MARK: - Properties

    private let camera: SKCameraNode
    private weak var scene: SKScene?
    
    /// Public access to the camera node for attaching HUD elements.
    var cameraNode: SKCameraNode { camera }

    private var targetScale: CGFloat = 1.0
    private var targetPosition: CGPoint = .zero

    private let minScale: CGFloat = 0.75
    private let maxScale: CGFloat = 1.15

    /// Per-frame shake offset, applied on top of the computed camera position.
    private var shakeOffset: CGPoint = .zero

    /// Remaining shake duration (counts down each frame).
    private var shakeDuration: TimeInterval = 0
    /// Original shake intensity; offset decays linearly from this value.
    private var shakeIntensity: CGFloat = 0

    /// Interpolation factor per frame for ease-in-out smoothing (0-1).
    /// Higher = snappier. 0.12 gives a smooth cinematic feel at 60 FPS.
    private let smoothing: CGFloat = 0.12

    /// Whether a special-zoom sequence is currently playing.
    private var isSpecialZoomActive = false
    
    /// When true, camera stays fixed at center — no dynamic framing.
    private var isFixed = false
    
    /// Sets whether the camera should stay fixed (no dynamic zoom/pan).
    func setFixed(_ fixed: Bool) {
        isFixed = fixed
    }

    // MARK: - Init

    init(scene: SKScene) {
        self.scene = scene
        self.camera = SKCameraNode()
        camera.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        scene.addChild(camera)
        scene.camera = camera
    }

    // MARK: - Per-Frame Update (Task 9.1)

    /// Call every frame to reposition and rescale the camera.
    /// - Parameters:
    ///   - playerPos: Current position of the player fighter.
    ///   - opponentPos: Current position of the opponent fighter.
    ///   - sceneSize: The scene's size (used for distance ratios and clamping).
    func update(playerPos: CGPoint, opponentPos: CGPoint, sceneSize: CGSize) {
        // Fixed mode — camera stays centered, no zoom
        if isFixed {
            camera.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
            camera.setScale(1.0)
            return
        }
        
        // During a special zoom the camera is driven by the SKAction sequence.
        guard !isSpecialZoomActive else {
            updateShake()
            return
        }

        // 1. Target position = midpoint between fighters (horizontal),
        //    keep vertical centered on the scene.
        let midX = (playerPos.x + opponentPos.x) / 2
        let midY = sceneSize.height / 2
        targetPosition = CGPoint(x: midX, y: midY)

        // 2. Zoom scale based on horizontal distance between fighters.
        let distance = abs(playerPos.x - opponentPos.x)
        let distanceRatio = distance / sceneSize.width

        if distanceRatio < 0.3 {
            targetScale = 0.85
        } else if distanceRatio > 0.7 {
            targetScale = 1.15
        } else {
            // Linearly interpolate between 0.85 and 1.15 across the 0.3–0.7 range.
            let t = (distanceRatio - 0.3) / 0.4
            targetScale = 0.85 + t * (1.15 - 0.85)
        }

        // Clamp scale to allowed range.
        targetScale = max(minScale, min(maxScale, targetScale))

        // 3. Ease-in-out interpolation toward targets.
        let currentPos = camera.position
        let easedX = currentPos.x + (targetPosition.x - currentPos.x) * smoothing
        let easedY = currentPos.y + (targetPosition.y - currentPos.y) * smoothing
        let easedScale = camera.xScale + (targetScale - camera.xScale) * smoothing

        // 4. Clamp to stage bounds so no empty space is visible.
        let clampedPos = clampToStageBounds(
            CGPoint(x: easedX, y: easedY),
            scale: easedScale,
            stageWidth: sceneSize.width,
            sceneSize: sceneSize
        )

        // 5. Apply shake offset on top of the clamped position.
        updateShake()

        camera.position = CGPoint(
            x: clampedPos.x + shakeOffset.x,
            y: clampedPos.y + shakeOffset.y
        )
        camera.setScale(easedScale)
    }

    // MARK: - Special Zoom (Task 9.2)

    /// Zooms to 0.75x centered on the attacker over 0.4 s, then eases back
    /// to normal framing over 0.3 s.
    func zoomForSpecial(attacker: CGPoint, completion: @escaping () -> Void) {
        guard let scene else { completion(); return }

        isSpecialZoomActive = true

        let zoomIn = SKAction.group([
            SKAction.scale(to: minScale, duration: 0.4),
            SKAction.move(to: CGPoint(x: attacker.x, y: scene.size.height / 2), duration: 0.4)
        ])
        zoomIn.timingMode = .easeInEaseOut

        let zoomOut = SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.3),
            SKAction.move(to: CGPoint(x: scene.size.width / 2, y: scene.size.height / 2), duration: 0.3)
        ])
        zoomOut.timingMode = .easeInEaseOut

        camera.run(SKAction.sequence([zoomIn, zoomOut])) { [weak self] in
            self?.isSpecialZoomActive = false
            completion()
        }
    }

    // MARK: - Screen Shake (Task 9.3)

    /// Starts a camera shake that decays linearly over `duration`.
    /// - Parameters:
    ///   - intensity: Maximum pixel offset per axis.
    ///   - duration: How long the shake lasts (seconds).
    func applyShake(intensity: CGFloat, duration: TimeInterval) {
        shakeIntensity = intensity
        shakeDuration = duration
    }

    // MARK: - Helpers

    /// Advances the shake timer and computes the current frame's offset.
    private func updateShake() {
        guard shakeDuration > 0 else {
            shakeOffset = .zero
            return
        }

        let dt: TimeInterval = 1.0 / 60.0
        shakeDuration -= dt

        if shakeDuration <= 0 {
            shakeDuration = 0
            shakeOffset = .zero
            return
        }

        // Linear decay: full intensity at start, zero at end.
        let progress = CGFloat(shakeDuration) / CGFloat(shakeDuration + dt)
        let currentIntensity = shakeIntensity * progress

        shakeOffset = CGPoint(
            x: CGFloat.random(in: -currentIntensity...currentIntensity),
            y: CGFloat.random(in: -currentIntensity...currentIntensity)
        )
    }

    /// Clamps the camera position so the visible rect stays within the stage.
    private func clampToStageBounds(
        _ pos: CGPoint,
        scale: CGFloat,
        stageWidth: CGFloat,
        sceneSize: CGSize
    ) -> CGPoint {
        let visibleWidth = sceneSize.width * scale
        let visibleHeight = sceneSize.height * scale

        let minX = visibleWidth / 2
        let maxX = stageWidth - visibleWidth / 2
        let minY = visibleHeight / 2
        let maxY = sceneSize.height - visibleHeight / 2

        return CGPoint(
            x: max(minX, min(maxX, pos.x)),
            y: max(minY, min(maxY, pos.y))
        )
    }
}
