import UIKit

/// Centralized haptic feedback for game events.
///
/// Uses UIKit's haptic generators for precise, low-latency feedback.
/// Generators are pre-warmed for instant response.
@MainActor
final class HapticManager {
    static let shared = HapticManager()

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    private init() {
        // Pre-warm all generators
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        rigid.prepare()
        notification.prepare()
        selection.prepare()
    }

    /// Ball tap — light, crisp
    func tap() {
        lightImpact.impactOccurred(intensity: 0.6)
        lightImpact.prepare()
    }

    /// Correct match tap — satisfying medium thud
    func correctTap() {
        mediumImpact.impactOccurred(intensity: 0.8)
        mediumImpact.prepare()
    }

    /// Wrong tap — sharp error buzz
    func wrongTap() {
        notification.notificationOccurred(.error)
        notification.prepare()
    }

    /// Round success — double tap celebration
    func success() {
        rigid.impactOccurred(intensity: 1.0)
        rigid.prepare()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [self] in
            rigid.impactOccurred(intensity: 0.6)
            rigid.prepare()
        }
    }

    /// Life lost — heavy thud
    func lifeLost() {
        heavyImpact.impactOccurred(intensity: 1.0)
        heavyImpact.prepare()
    }

    /// Game over — triple descending buzz
    func gameOver() {
        heavyImpact.impactOccurred(intensity: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [self] in
            heavyImpact.impactOccurred(intensity: 0.7)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) { [self] in
            heavyImpact.impactOccurred(intensity: 0.4)
            heavyImpact.prepare()
        }
    }

    /// Combo streak — quick selection tick
    func combo() {
        selection.selectionChanged()
        selection.prepare()
    }

    /// Countdown tick
    func countdownTick() {
        rigid.impactOccurred(intensity: 0.4)
        rigid.prepare()
    }
}
