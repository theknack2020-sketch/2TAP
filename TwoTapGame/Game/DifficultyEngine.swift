import Foundation

/// Controls difficulty progression based on score.
///
/// Ball count increases at score thresholds.
/// Starts at 6, increases gradually up to 12 (screen maximum).
struct DifficultyEngine {

    /// Score thresholds and their corresponding ball counts.
    /// Each entry: (minimumScore, ballCount)
    private static let thresholds: [(score: Int, balls: Int)] = [
        (0,     6),
        (500,   7),
        (1200,  8),
        (2500,  8),
        (4000,  9),
        (6000,  10),
        (9000,  11),
        (13000, 12),
    ]

    /// Returns the ball count for the given score.
    /// - Parameters:
    ///   - score: current player score
    ///   - maxBalls: maximum balls that fit on screen
    /// - Returns: number of balls for the next round
    static func ballCount(forScore score: Int, maxBalls: Int = 12) -> Int {
        var result = 6
        for threshold in thresholds {
            if score >= threshold.score {
                result = threshold.balls
            } else {
                break
            }
        }
        return min(result, maxBalls)
    }

    /// Returns a descriptive difficulty level name.
    static func levelName(forScore score: Int) -> String {
        switch score {
        case 0..<500: return "Easy"
        case 500..<1200: return "Normal"
        case 1200..<2500: return "Hard"
        case 2500..<4000: return "Expert"
        case 4000..<6000: return "Master"
        case 6000..<9000: return "Legend"
        default: return "Insane"
        }
    }
}
