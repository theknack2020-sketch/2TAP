import UIKit

/// Represents the color assignment for a single round.
struct RoundColors {
    /// The colors assigned to each ball, in order.
    let assignments: [UIColor]

    /// The color that is repeated (the one the player must find).
    let matchingColor: UIColor

    /// How many times the matching color appears (always 3).
    let matchCount: Int

    /// Indices of balls that have the matching color.
    let matchingIndices: Set<Int>
}

/// Generates color assignments for each round.
///
/// Rules:
/// - Exactly 3 balls share the matching color
/// - All other balls have unique, visually distinct colors
/// - No two non-matching colors look similar to the matching color
struct ColorMatchEngine {

    /// Minimum HSB distance between any two colors in the same round.
    /// 0.20 is quite strict — ensures clear visual separation.
    static let defaultMinColorDistance: CGFloat = 0.20

    /// Generates a round's color assignment.
    static func generateRound(
        ballCount: Int,
        palette: ColorPalette = .default,
        minColorDistance: CGFloat = defaultMinColorDistance
    ) -> RoundColors {
        precondition(ballCount >= 4, "Need at least 4 balls")

        let matchCount = 3
        let uniqueColorsNeeded = ballCount - matchCount + 1 // +1 for matching color itself

        // Try with distance enforcement
        let selected = selectDistinctColors(
            count: uniqueColorsNeeded,
            from: palette.colors,
            minDistance: minColorDistance
        )

        // If we got enough, use them
        if selected.count == uniqueColorsNeeded {
            return buildRound(
                matchingColor: selected[0],
                uniqueColors: Array(selected.dropFirst()),
                matchCount: matchCount
            )
        }

        // Retry with relaxed distance
        let relaxed = selectDistinctColors(
            count: uniqueColorsNeeded,
            from: palette.colors,
            minDistance: minColorDistance * 0.6
        )

        if relaxed.count == uniqueColorsNeeded {
            return buildRound(
                matchingColor: relaxed[0],
                uniqueColors: Array(relaxed.dropFirst()),
                matchCount: matchCount
            )
        }

        // Last resort: pick any distinct colors (no distance check, but no duplicates)
        let shuffled = palette.colors.shuffled()
        let picked = Array(shuffled.prefix(uniqueColorsNeeded))
        return buildRound(
            matchingColor: picked[0],
            uniqueColors: Array(picked.dropFirst()),
            matchCount: matchCount
        )
    }

    /// Build the RoundColors from selected colors.
    private static func buildRound(
        matchingColor: UIColor,
        uniqueColors: [UIColor],
        matchCount: Int
    ) -> RoundColors {
        var assignments: [UIColor] = Array(repeating: matchingColor, count: matchCount)
        assignments.append(contentsOf: uniqueColors)
        assignments.shuffle()

        // Compute matching indices explicitly (don't rely on color equality)
        var matchIndices = Set<Int>()
        var matchesFound = 0
        for (i, color) in assignments.enumerated() {
            // Use identity check — matching balls are the same instance
            if color === matchingColor && matchesFound < matchCount {
                matchIndices.insert(i)
                matchesFound += 1
            }
        }

        // Fallback: if identity check fails (shouldn't), use equality
        if matchIndices.count != matchCount {
            matchIndices.removeAll()
            for (i, color) in assignments.enumerated() {
                if color == matchingColor {
                    matchIndices.insert(i)
                }
            }
        }

        return RoundColors(
            assignments: assignments,
            matchingColor: matchingColor,
            matchCount: matchCount,
            matchingIndices: matchIndices
        )
    }

    // MARK: - Color Selection

    /// Select `count` colors that are at least `minDistance` apart.
    /// Uses greedy selection from shuffled palette.
    private static func selectDistinctColors(
        count: Int,
        from palette: [UIColor],
        minDistance: CGFloat
    ) -> [UIColor] {
        // Try multiple shuffles for better coverage
        for _ in 0..<5 {
            var candidates = palette.shuffled()
            var selected: [UIColor] = []

            while selected.count < count && !candidates.isEmpty {
                let candidate = candidates.removeFirst()

                let isFarEnough = selected.allSatisfy { existing in
                    colorDistance(candidate, existing) >= minDistance
                }

                if isFarEnough {
                    selected.append(candidate)
                }
            }

            if selected.count == count {
                return selected
            }
        }

        return [] // couldn't find enough distinct colors
    }

    /// HSB-space perceptual distance between two colors (0.0 to 1.0).
    static func colorDistance(_ a: UIColor, _ b: UIColor) -> CGFloat {
        var h1: CGFloat = 0, s1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var h2: CGFloat = 0, s2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        a.getHue(&h1, saturation: &s1, brightness: &b1, alpha: &a1)
        b.getHue(&h2, saturation: &s2, brightness: &b2, alpha: &a2)

        // Hue is circular — use shortest arc
        let hueDiff = min(abs(h1 - h2), 1.0 - abs(h1 - h2))
        let satDiff = abs(s1 - s2)
        let briDiff = abs(b1 - b2)

        // Weighted euclidean: hue most important, then saturation, then brightness
        let distance = sqrt(
            hueDiff * hueDiff * 2.0 +
            satDiff * satDiff * 1.0 +
            briDiff * briDiff * 0.5
        )

        return min(distance / 1.87, 1.0)
    }
}
