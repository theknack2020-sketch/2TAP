import UIKit

/// Centralized haptic feedback for game events.
///
/// Haptic generators are prepared before each use for instant response.
/// All methods fire synchronously on whatever thread they're called from.
final class HapticManager {
    static let shared = HapticManager()

    private init() {}

    /// Ball tap — light, crisp
    func tap() {
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.prepare()
        gen.impactOccurred(intensity: 0.6)
    }

    /// Correct match tap — satisfying medium thud
    func correctTap() {
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.prepare()
        gen.impactOccurred(intensity: 0.8)
    }

    /// Wrong tap — sharp error buzz
    func wrongTap() {
        let gen = UINotificationFeedbackGenerator()
        gen.prepare()
        gen.notificationOccurred(.error)
    }

    /// Round success — double tap celebration
    func success() {
        let gen = UIImpactFeedbackGenerator(style: .rigid)
        gen.prepare()
        gen.impactOccurred(intensity: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            gen.impactOccurred(intensity: 0.6)
        }
    }

    /// Life lost — heavy thud
    func lifeLost() {
        let gen = UIImpactFeedbackGenerator(style: .heavy)
        gen.prepare()
        gen.impactOccurred(intensity: 1.0)
    }

    /// Game over — triple descending buzz
    func gameOver() {
        let gen = UIImpactFeedbackGenerator(style: .heavy)
        gen.prepare()
        gen.impactOccurred(intensity: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            gen.impactOccurred(intensity: 0.7)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            gen.impactOccurred(intensity: 0.4)
        }
    }

    /// Combo streak — quick selection tick
    func combo() {
        let gen = UISelectionFeedbackGenerator()
        gen.prepare()
        gen.selectionChanged()
    }

    /// Countdown tick
    func countdownTick() {
        let gen = UIImpactFeedbackGenerator(style: .rigid)
        gen.prepare()
        gen.impactOccurred(intensity: 0.5)
    }
}
