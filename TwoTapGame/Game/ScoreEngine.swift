import Foundation

/// Handles score calculation with combo multiplier.
///
/// Rules:
/// - Base points per correct round: 100
/// - Combo multiplier: x1 → x2 → x3 → x4... (caps at x10)
/// - One mistake resets combo to x1
/// - Bonus life every 10 consecutive perfect rounds
struct ScoreEngine {

    /// Base points awarded per correct match.
    static let basePoints = 100

    /// Maximum combo multiplier.
    static let maxCombo = 10

    /// Consecutive perfect rounds needed for a bonus life.
    static let perfectStreakForBonus = 10

    /// Calculate score for a correct round.
    /// - Parameter combo: current combo count (1-based, incremented before calling)
    /// - Returns: points earned this round
    static func pointsForRound(combo: Int) -> Int {
        let multiplier = min(combo, maxCombo)
        return basePoints * multiplier
    }

    /// Check if a bonus life should be awarded.
    /// - Parameter consecutivePerfect: total consecutive perfect rounds
    /// - Returns: true if this round earns a bonus life
    static func shouldAwardBonusLife(consecutivePerfect: Int) -> Bool {
        consecutivePerfect > 0 && consecutivePerfect % perfectStreakForBonus == 0
    }
}
