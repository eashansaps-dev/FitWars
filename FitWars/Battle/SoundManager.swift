import SpriteKit

/// Centralized audio system with named hooks for all combat events.
/// Uses SKAction.playSoundFileNamed for SFX and SKAudioNode for background music.
class SoundManager {
    static let shared = SoundManager()

    /// Maps event names to audio filenames (e.g. "attack_hit" → "hit_01.wav")
    private var soundMap: [String: String] = [:]

    /// Tracks how many SFX are currently playing to enforce the cap.
    private var activeSFXCount: Int = 0

    /// Maximum simultaneous sound effects allowed.
    private let maxConcurrent = 4

    /// Weak reference to the current scene for running sound actions.
    weak var scene: SKScene?

    /// Currently playing background music node.
    private var bgMusicNode: SKAudioNode?

    private init() {}

    // MARK: - Configuration

    /// Configure the event-to-filename mapping.
    /// - Parameter mapping: Dictionary of event name keys to audio filename values.
    ///   e.g. `["attack_hit": "hit_01.wav", "knockdown": "ko_boom.wav"]`
    func configure(mapping: [String: String]) {
        self.soundMap = mapping
    }

    // MARK: - SFX Playback

    /// Play a sound effect for the given event.
    /// Looks up the filename from the configured soundMap, checks the file exists in the bundle,
    /// and plays it via SKAction on the current scene. Respects the maxConcurrent SFX limit.
    /// - Parameters:
    ///   - event: The event key (e.g. "attack_hit").
    ///   - context: Optional context dictionary (e.g. damage amount, combo count).
    func play(_ event: String, context: [String: Any] = [:]) {
        guard let filename = soundMap[event] else {
            print("[SoundManager] ⚠️ No mapping found for event: \(event)")
            return
        }

        // Graceful missing-file handling: check bundle before playing
        guard audioFileExists(filename) else {
            print("[SoundManager] ⚠️ Audio file not found in bundle: \(filename) (event: \(event)) — skipping playback")
            return
        }

        guard let scene = scene else {
            print("[SoundManager] ⚠️ No scene set — cannot play sound for event: \(event)")
            return
        }

        guard activeSFXCount < maxConcurrent else {
            return
        }

        activeSFXCount += 1

        let playAction = SKAction.playSoundFileNamed(filename, waitForCompletion: true)
        let decrementAction = SKAction.run { [weak self] in
            self?.activeSFXCount = max((self?.activeSFXCount ?? 1) - 1, 0)
        }

        scene.run(SKAction.sequence([playAction, decrementAction]))
    }

    // MARK: - Background Music

    /// Start looping background music in the given scene.
    /// Stops any currently playing music first.
    /// - Parameters:
    ///   - filename: The audio file name (e.g. "battle_bgm_01.m4a").
    ///   - scene: The SKScene to attach the audio node to.
    func playMusic(_ filename: String, in scene: SKScene) {
        // Check file exists before attempting playback
        guard audioFileExists(filename) else {
            print("[SoundManager] ⚠️ Music file not found in bundle: \(filename) — skipping playback")
            return
        }

        // Stop existing music immediately if any
        if let existing = bgMusicNode {
            existing.removeFromParent()
            bgMusicNode = nil
        }

        let musicNode = SKAudioNode(fileNamed: filename)
        musicNode.autoplayLooped = true
        musicNode.isPositional = false
        scene.addChild(musicNode)
        bgMusicNode = musicNode
    }

    /// Stop the currently playing background music with a fade out.
    /// - Parameter fadeDuration: Duration of the fade out in seconds. Defaults to 0.5.
    func stopMusic(fadeDuration: TimeInterval = 0.5) {
        guard let musicNode = bgMusicNode else { return }

        let fadeOut = SKAction.changeVolume(to: 0, duration: fadeDuration)
        let remove = SKAction.run { [weak self] in
            musicNode.removeFromParent()
            self?.bgMusicNode = nil
        }
        musicNode.run(SKAction.sequence([fadeOut, remove]))
    }

    /// Crossfade from the current background music to a new track.
    /// Fades out the old track while fading in the new one over the given duration.
    /// - Parameters:
    ///   - filename: The new music file name.
    ///   - scene: The SKScene to attach the new audio node to.
    ///   - duration: Crossfade duration in seconds. Defaults to 0.5.
    func crossfadeMusic(to filename: String, in scene: SKScene, duration: TimeInterval = 0.5) {
        // Check new file exists before starting crossfade
        guard audioFileExists(filename) else {
            print("[SoundManager] ⚠️ Music file not found in bundle: \(filename) — skipping crossfade")
            return
        }

        // Fade out old music
        if let oldMusic = bgMusicNode {
            let fadeOut = SKAction.changeVolume(to: 0, duration: duration)
            let remove = SKAction.run {
                oldMusic.removeFromParent()
            }
            oldMusic.run(SKAction.sequence([fadeOut, remove]))
        }

        // Fade in new music
        let newMusic = SKAudioNode(fileNamed: filename)
        newMusic.autoplayLooped = true
        newMusic.isPositional = false
        scene.addChild(newMusic)

        // Start at zero volume and fade in
        let setVolume = SKAction.changeVolume(to: 0, duration: 0)
        let fadeIn = SKAction.changeVolume(to: 1.0, duration: duration)
        newMusic.run(SKAction.sequence([setVolume, fadeIn]))

        bgMusicNode = newMusic
    }

    // MARK: - Named Event Hooks (Requirement 8)

    func attackHit(damage: Int) {
        play("attack_hit", context: ["damage": damage])
    }

    func attackBlocked() {
        play("attack_blocked")
    }

    func attackWhiff() {
        play("attack_whiff")
    }

    func comboHit(count: Int) {
        play("combo_hit", context: ["count": count])
    }

    func specialAttack() {
        play("special_attack")
    }

    func knockdown() {
        play("knockdown")
    }

    func roundStart() {
        play("round_start")
    }

    func roundEnd() {
        play("round_end")
    }

    func timerWarning() {
        play("timer_warning")
    }

    func menuSelect() {
        play("menu_select")
    }

    // MARK: - Bundle File Check

    /// Check whether an audio file exists in the app bundle.
    /// Handles filenames with and without extensions.
    /// - Parameter filename: The audio filename to look for.
    /// - Returns: `true` if the file is found in the bundle.
    private func audioFileExists(_ filename: String) -> Bool {
        let nsFilename = filename as NSString
        let name = nsFilename.deletingPathExtension
        let ext = nsFilename.pathExtension

        if !ext.isEmpty {
            return Bundle.main.url(forResource: name, withExtension: ext) != nil
        } else {
            // No extension provided — try common audio extensions
            let commonExtensions = ["wav", "m4a", "mp3", "caf", "aif", "aiff"]
            return commonExtensions.contains { Bundle.main.url(forResource: name, withExtension: $0) != nil }
        }
    }

    // MARK: - Cleanup

    /// Stop all audio and reset state. Called when the battle scene is dismissed.
    func cleanup() {
        bgMusicNode?.removeFromParent()
        bgMusicNode = nil
        activeSFXCount = 0
        scene = nil
    }
}
