import Foundation

/// Tracks consecutive hits within a timing window and calculates combo damage scaling.
///
/// **Validates: Requirements 6.1, 6.2, 6.7**
class ComboSystem {

    // MARK: - Public State

    /// Number of consecutive hits in the current combo.
    private(set) var currentComboCount: Int = 0

    /// Accumulated total damage dealt during the current combo.
    private(set) var currentComboDamage: Int = 0

    // MARK: - Callbacks

    /// Fired after each hit that extends the combo. Parameters: (hitCount, totalDamage).
    var onComboUpdated: ((Int, Int) -> Void)?

    /// Fired when the combo window expires without a new hit. Parameters: (finalCount, finalDamage).
    var onComboEnded: ((Int, Int) -> Void)?

    // MARK: - Private

    /// Timestamp of the most recent registered hit.
    private var lastHitTime: TimeInterval = 0

    /// Maximum allowed gap between consecutive hits to keep the combo alive.
    private let comboWindow: TimeInterval = 0.4

    /// Whether a combo is currently active (at least one hit registered and window hasn't expired).
    private var comboActive: Bool = false

    // MARK: - Damage Multiplier

    /// Scaling factor for the current combo hit.
    /// Hit 1 = 1.0×, hit 2 = 1.1×, hit 3 = 1.2×, etc.
    var damageMultiplier: Double {
        1.0 + 0.1 * Double(max(currentComboCount - 1, 0))
    }

    // MARK: - Public API

    /// Registers a new hit and returns the scaled damage value.
    ///
    /// If the hit arrives within `comboWindow` of the previous hit the combo continues;
    /// otherwise the previous combo is ended first and a fresh combo begins.
    ///
    /// - Parameters:
    ///   - baseDamage: Raw damage before combo scaling.
    ///   - timestamp: The current game time (seconds).
    /// - Returns: The damage after applying the combo multiplier.
    func registerHit(baseDamage: Int, timestamp: TimeInterval) -> Int {
        // If the window has expired since the last hit, end the old combo first.
        if comboActive && (timestamp - lastHitTime) > comboWindow {
            endCombo()
        }

        // Advance the combo.
        currentComboCount += 1
        lastHitTime = timestamp
        comboActive = true

        let scaledDamage = Int(Double(baseDamage) * damageMultiplier)
        currentComboDamage += scaledDamage

        onComboUpdated?(currentComboCount, currentComboDamage)

        return scaledDamage
    }

    /// Called every frame to check whether the combo window has expired.
    ///
    /// - Parameter currentTime: The current game time (seconds).
    func update(currentTime: TimeInterval) {
        guard comboActive else { return }

        if (currentTime - lastHitTime) > comboWindow {
            endCombo()
        }
    }

    /// Immediately resets the combo state without firing callbacks.
    func reset() {
        currentComboCount = 0
        currentComboDamage = 0
        lastHitTime = 0
        comboActive = false
    }

    // MARK: - Special Meter Bonus

    /// Returns `true` when the combo that just ended qualifies for a special meter bonus
    /// (5 or more hits). The caller is responsible for applying the 10% meter fill.
    var qualifiesForSpecialBonus: Bool {
        currentComboCount >= 5
    }

    // MARK: - Private Helpers

    private func endCombo() {
        guard comboActive, currentComboCount > 0 else { return }

        onComboEnded?(currentComboCount, currentComboDamage)

        // Reset for the next combo.
        currentComboCount = 0
        currentComboDamage = 0
        comboActive = false
    }
}
