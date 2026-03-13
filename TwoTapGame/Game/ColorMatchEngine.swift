import UIKit

/// Represents the color assignment for a single round.
struct RoundColors {
    /// The colors assigned to each ball, in order.
    let assignments: [UIColor]

    /// The color that is repeated (the one the player must find).
    let matchingColor: UIColor

    /// How many times the matching color appears (2 or 3).
    let matchCount: Int

    /// Indices of balls that have the matching color.
    var matchingIndices: Set<Int> {
        Set(assignments.enumerated().compactMap { index, color in
            color == matchingColor ? index : nil
        })
    }
}

/// Generates color assignments for each round.
///
/// Rules:
/// - Exactly one color repeats (2 or 3 times, per D005: max 3)
/// - All other colors are unique
/// - Colors within a round maintain minimum visual distance
struct ColorMatchEngine {

    /// Minimum distance between any two colors in the same round (HSB space).
    /// Higher = easier to distinguish. Range: 0.0-1.0
    static let defaultMinColorDistance: CGFloat = 0.15

    /// Generates a round's color assignment.
    ///
    /// - Parameters:
    ///   - ballCount: Number of balls (5-12+)
    ///   - palette: Color palette to draw from
    ///   - minColorDistance: Minimum HSB distance between colors in the round (lower = harder)
    /// - Returns: RoundColors with assignments and match info
    static func generateRound(
        ballCount: Int,
        palette: ColorPalette = .default,
        minColorDistance: CGFloat = defaultMinColorDistance
    ) -> RoundColors {
        precondition(ballCount >= 3, "Need at least 3 balls for a meaningful round")
        precondition(palette.colors.count >= ballCount, "Palette needs at least \(ballCount) colors")

        // Decide match count: 2 or 3 (weighted toward 2 for balance)
        let matchCount = Int.random(in: 1...10) <= 7 ? 2 : 3

        // If ball count is too small for 3 matches, force 2
        let effectiveMatchCount = ballCount <= 4 ? 2 : matchCount

        // Number of unique colors needed (one for the match + rest unique)
        let uniqueColorsNeeded = ballCount - effectiveMatchCount + 1

        // Pick colors with minimum distance enforcement
        let selectedColors = selectDistinctColors(
            count: uniqueColorsNeeded,
            from: palette.colors,
            minDistance: minColorDistance
        )

        guard selectedColors.count == uniqueColorsNeeded else {
            // Fallback: just use random colors if distance filtering is too strict
            return generateRoundFallback(
                ballCount: ballCount,
                palette: palette,
                matchCount: effectiveMatchCount
            )
        }

        // First color is the matching one
        let matchingColor = selectedColors[0]
        let uniqueColors = Array(selectedColors.dropFirst())

        // Build assignments: matchCount copies of matching + one each of unique
        var assignments: [UIColor] = Array(repeating: matchingColor, count: effectiveMatchCount)
        assignments.append(contentsOf: uniqueColors)

        // Shuffle so matching balls aren't always first
        assignments.shuffle()

        return RoundColors(
            assignments: assignments,
            matchingColor: matchingColor,
            matchCount: effectiveMatchCount
        )
    }

    // MARK: - Private

    /// Select `count` colors from the palette that are at least `minDistance` apart in HSB space.
    private static func selectDistinctColors(
        count: Int,
        from palette: [UIColor],
        minDistance: CGFloat
    ) -> [UIColor] {
        var shuffled = palette.shuffled()
        var selected: [UIColor] = []

        while selected.count < count && !shuffled.isEmpty {
            let candidate = shuffled.removeFirst()

            let isFarEnough = selected.allSatisfy { existing in
                colorDistance(candidate, existing) >= minDistance
            }

            if isFarEnough {
                selected.append(candidate)
            }
        }

        return selected
    }

    /// Fallback round generation without color distance enforcement.
    private static func generateRoundFallback(
        ballCount: Int,
        palette: ColorPalette,
        matchCount: Int
    ) -> RoundColors {
        let shuffled = palette.colors.shuffled()
        let uniqueNeeded = ballCount - matchCount + 1
        let selectedColors = Array(shuffled.prefix(uniqueNeeded))

        let matchingColor = selectedColors[0]
        var assignments = Array(repeating: matchingColor, count: matchCount)
        assignments.append(contentsOf: selectedColors.dropFirst())
        assignments.shuffle()

        return RoundColors(
            assignments: assignments,
            matchingColor: matchingColor,
            matchCount: matchCount
        )
    }

    /// HSB-space distance between two colors (0.0 to ~1.73).
    /// Normalized to 0.0-1.0 range.
    static func colorDistance(_ a: UIColor, _ b: UIColor) -> CGFloat {
        var h1: CGFloat = 0, s1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var h2: CGFloat = 0, s2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        a.getHue(&h1, saturation: &s1, brightness: &b1, alpha: &a1)
        b.getHue(&h2, saturation: &s2, brightness: &b2, alpha: &a2)

        // Hue is circular (0.0 = 1.0), so use shortest arc
        let hueDiff = min(abs(h1 - h2), 1.0 - abs(h1 - h2))
        let satDiff = abs(s1 - s2)
        let briDiff = abs(b1 - b2)

        // Weighted: hue matters most, then saturation, then brightness
        let distance = sqrt(
            hueDiff * hueDiff * 2.0 +
            satDiff * satDiff * 1.0 +
            briDiff * briDiff * 0.5
        )

        // Normalize to 0.0-1.0 range (max theoretical ~1.87)
        return min(distance / 1.87, 1.0)
    }
}
