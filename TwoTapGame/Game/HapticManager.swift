import UIKit

/// Centralized haptic feedback for game events.
///
/// Generators are created once and reused (Apple recommendation).
/// Reads haptics setting from UserDefaults (thread-safe).
final class HapticManager {
    static let shared = HapticManager()

    // Reusable generators — Apple recommends creating once and reusing
    private let lightGen = UIImpactFeedbackGenerator(style: .light)
    private let mediumGen = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGen = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidGen = UIImpactFeedbackGenerator(style: .rigid)
    private let notificationGen = UINotificationFeedbackGenerator()
    private let selectionGen = UISelectionFeedbackGenerator()

    private var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: "hapticsEnabled")
    }

    private init() {}

    /// Ball tap — light, crisp
    func tap() {
        guard isEnabled else { return }
        lightGen.prepare()
        lightGen.impactOccurred(intensity: 0.6)
    }

    /// Correct match tap — satisfying medium thud
    func correctTap() {
        guard isEnabled else { return }
        mediumGen.prepare()
        mediumGen.impactOccurred(intensity: 0.8)
    }

    /// Wrong tap — sharp error buzz
    func wrongTap() {
        guard isEnabled else { return }
        notificationGen.prepare()
        notificationGen.notificationOccurred(.error)
    }

    /// Round success — double tap celebration
    func success() {
        guard isEnabled else { return }
        rigidGen.prepare()
        rigidGen.impactOccurred(intensity: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [self] in
            rigidGen.impactOccurred(intensity: 0.6)
        }
    }

    /// Life lost — heavy thud
    func lifeLost() {
        guard isEnabled else { return }
        heavyGen.prepare()
        heavyGen.impactOccurred(intensity: 1.0)
    }

    /// Game over — triple descending buzz
    func gameOver() {
        guard isEnabled else { return }
        heavyGen.prepare()
        heavyGen.impactOccurred(intensity: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [self] in
            heavyGen.impactOccurred(intensity: 0.7)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) { [self] in
            heavyGen.impactOccurred(intensity: 0.4)
        }
    }

    /// Combo streak — quick selection tick
    func combo() {
        guard isEnabled else { return }
        selectionGen.prepare()
        selectionGen.selectionChanged()
    }

    /// Countdown tick
    func countdownTick() {
        guard isEnabled else { return }
        rigidGen.prepare()
        rigidGen.impactOccurred(intensity: 0.5)
    }
}
