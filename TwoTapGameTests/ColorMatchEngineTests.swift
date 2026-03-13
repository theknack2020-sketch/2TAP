import XCTest
@testable import TwoTapGame

final class ColorMatchEngineTests: XCTestCase {

    // MARK: - Basic Round Generation

    func testGeneratesCorrectBallCount() {
        for count in [5, 6, 7, 8, 10, 12] {
            let round = ColorMatchEngine.generateRound(ballCount: count)
            XCTAssertEqual(
                round.assignments.count, count,
                "Expected \(count) balls, got \(round.assignments.count)"
            )
        }
    }

    func testExactlyOneColorRepeats() {
        for _ in 0..<50 {
            let round = ColorMatchEngine.generateRound(ballCount: 7)

            // Count occurrences of each color
            var colorCounts: [UIColor: Int] = [:]
            for color in round.assignments {
                colorCounts[color, default: 0] += 1
            }

            // Exactly one color should have count > 1
            let repeatedColors = colorCounts.filter { $0.value > 1 }
            XCTAssertEqual(
                repeatedColors.count, 1,
                "Expected exactly 1 repeated color, got \(repeatedColors.count)"
            )
        }
    }

    func testMatchCountIsAlways3() {
        for _ in 0..<100 {
            let round = ColorMatchEngine.generateRound(ballCount: 7)
            XCTAssertEqual(
                round.matchCount, 3,
                "Match count must always be 3, got \(round.matchCount)"
            )
        }
    }

    // MARK: - Matching Indices

    func testMatchingIndicesCorrect() {
        for _ in 0..<50 {
            let round = ColorMatchEngine.generateRound(ballCount: 7)

            let indices = round.matchingIndices
            XCTAssertEqual(indices.count, round.matchCount)

            for index in indices {
                XCTAssertEqual(
                    round.assignments[index], round.matchingColor,
                    "Ball at index \(index) should have matching color"
                )
            }
        }
    }

    // MARK: - Color Uniqueness

    func testNonMatchingColorsAreUnique() {
        for _ in 0..<50 {
            let round = ColorMatchEngine.generateRound(ballCount: 7)
            let matchingIndices = round.matchingIndices

            var seenColors: Set<UIColor> = []
            for (index, color) in round.assignments.enumerated() {
                if !matchingIndices.contains(index) {
                    XCTAssertFalse(
                        seenColors.contains(color),
                        "Non-matching color at index \(index) is duplicated"
                    )
                    seenColors.insert(color)
                }
            }
        }
    }

    // MARK: - Color Distance

    func testColorDistanceSameColor() {
        let color = UIColor.red
        let distance = ColorMatchEngine.colorDistance(color, color)
        XCTAssertEqual(distance, 0.0, accuracy: 0.001)
    }

    func testColorDistanceOppositeColors() {
        let red = UIColor.red
        let cyan = UIColor.cyan
        let distance = ColorMatchEngine.colorDistance(red, cyan)
        XCTAssertGreaterThan(distance, 0.3, "Red and cyan should be far apart")
    }

    func testColorsInRoundAreDistinct() {
        for _ in 0..<30 {
            let round = ColorMatchEngine.generateRound(ballCount: 7)

            // Get unique colors used
            var uniqueColors: [UIColor] = []
            for color in round.assignments {
                if !uniqueColors.contains(color) {
                    uniqueColors.append(color)
                }
            }

            // Check pairwise distance
            for i in 0..<uniqueColors.count {
                for j in (i + 1)..<uniqueColors.count {
                    let dist = ColorMatchEngine.colorDistance(uniqueColors[i], uniqueColors[j])
                    // Should meet default minimum distance or be close
                    // (fallback path may not enforce distance)
                    XCTAssertGreaterThan(
                        dist, 0.05,
                        "Colors \(i) and \(j) are too similar: distance \(dist)"
                    )
                }
            }
        }
    }

    // MARK: - Palette Support

    func testWorksWithNeonPalette() {
        let round = ColorMatchEngine.generateRound(ballCount: 7, palette: .neon)
        XCTAssertEqual(round.assignments.count, 7)
    }

    func testWorksWithPastelPalette() {
        let round = ColorMatchEngine.generateRound(ballCount: 7, palette: .pastel)
        XCTAssertEqual(round.assignments.count, 7)
    }

    // MARK: - Edge Cases

    func testMinimumBallCount() {
        let round = ColorMatchEngine.generateRound(ballCount: 5)
        XCTAssertEqual(round.assignments.count, 5)
        XCTAssertEqual(round.matchCount, 3)
    }

    func testLargeBallCount() {
        let round = ColorMatchEngine.generateRound(ballCount: 12)
        XCTAssertEqual(round.assignments.count, 12)
    }
}
