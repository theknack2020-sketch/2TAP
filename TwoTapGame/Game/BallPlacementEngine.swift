import Foundation
import CoreGraphics

/// Generates non-overlapping ball positions within a playable area.
/// Ensures minimum finger-tap gap between balls and screen edges.
struct BallPlacementEngine {

    /// Minimum gap between ball edges (Apple's minimum touch target)
    static let minimumGap: CGFloat = 44.0

    /// Margin from screen edges / safe area
    static let edgeMargin: CGFloat = 20.0

    /// Generates random non-overlapping positions for the given ball count.
    ///
    /// Uses rejection sampling with a grid-based fallback if random placement
    /// can't find valid positions within the retry limit.
    ///
    /// - Parameters:
    ///   - count: Number of balls to place (5-12+)
    ///   - ballRadius: Radius of each ball in points
    ///   - screenSize: Full screen size in points
    ///   - topInset: Top area reserved for HUD (timer bar, etc.)
    ///   - bottomInset: Bottom area reserved (safe area, etc.)
    /// - Returns: Array of center positions, or nil if placement is impossible
    static func generatePositions(
        count: Int,
        ballRadius: CGFloat,
        screenSize: CGSize,
        topInset: CGFloat = 80,
        bottomInset: CGFloat = 40
    ) -> [CGPoint]? {
        let playableRect = CGRect(
            x: edgeMargin + ballRadius,
            y: bottomInset + edgeMargin + ballRadius,
            width: screenSize.width - 2 * (edgeMargin + ballRadius),
            height: screenSize.height - topInset - bottomInset - 2 * (edgeMargin + ballRadius)
        )

        guard playableRect.width > 0, playableRect.height > 0 else {
            return nil
        }

        let minimumCenterDistance = 2 * ballRadius + minimumGap

        // Try rejection sampling first (more natural random distribution)
        if let positions = rejectionSampling(
            count: count,
            playableRect: playableRect,
            minimumCenterDistance: minimumCenterDistance,
            maxAttempts: count * 200
        ) {
            return positions
        }

        // Fallback: grid-based placement with jitter
        return gridPlacement(
            count: count,
            playableRect: playableRect,
            minimumCenterDistance: minimumCenterDistance
        )
    }

    /// Calculates the recommended ball radius for the given screen size and ball count.
    ///
    /// Ensures balls fit comfortably with gaps. Returns a radius that works
    /// for the worst case (maximum balls on smallest screen dimension).
    static func recommendedBallRadius(
        for screenSize: CGSize,
        ballCount: Int,
        topInset: CGFloat = 80,
        bottomInset: CGFloat = 40
    ) -> CGFloat {
        let availableWidth = screenSize.width - 2 * edgeMargin
        let availableHeight = screenSize.height - topInset - bottomInset - 2 * edgeMargin

        // Estimate how many balls fit per row/column
        let cols = ceil(sqrt(Double(ballCount) * Double(availableWidth) / Double(availableHeight)))
        let rows = ceil(Double(ballCount) / cols)

        let maxRadiusFromWidth = (availableWidth - minimumGap * (CGFloat(cols) - 1)) / (2 * CGFloat(cols))
        let maxRadiusFromHeight = (availableHeight - minimumGap * (CGFloat(rows) - 1)) / (2 * CGFloat(rows))

        let maxRadius = min(maxRadiusFromWidth, maxRadiusFromHeight)

        // Clamp between reasonable sizes (min 20pt for visibility, max 38pt for aesthetics)
        return min(max(maxRadius, 20), 38)
    }

    /// Maximum number of balls that can fit on the given screen size.
    static func maxBallCount(
        for screenSize: CGSize,
        topInset: CGFloat = 80,
        bottomInset: CGFloat = 40
    ) -> Int {
        // Binary search for max count where placement succeeds
        var low = 5
        var high = 20
        var result = 5

        while low <= high {
            let mid = (low + high) / 2
            let radius = recommendedBallRadius(
                for: screenSize,
                ballCount: mid,
                topInset: topInset,
                bottomInset: bottomInset
            )
            if radius >= 20 { // Minimum usable ball size
                result = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }

        return result
    }

    // MARK: - Private

    /// Rejection sampling: pick random positions, reject if they overlap.
    private static func rejectionSampling(
        count: Int,
        playableRect: CGRect,
        minimumCenterDistance: CGFloat,
        maxAttempts: Int
    ) -> [CGPoint]? {
        var positions: [CGPoint] = []
        var attempts = 0

        while positions.count < count && attempts < maxAttempts {
            let candidate = CGPoint(
                x: playableRect.minX + CGFloat.random(in: 0...playableRect.width),
                y: playableRect.minY + CGFloat.random(in: 0...playableRect.height)
            )

            let isValid = positions.allSatisfy { existing in
                distance(candidate, existing) >= minimumCenterDistance
            }

            if isValid {
                positions.append(candidate)
            }

            attempts += 1
        }

        return positions.count == count ? positions : nil
    }

    /// Grid-based fallback: place balls on a grid with random jitter.
    private static func gridPlacement(
        count: Int,
        playableRect: CGRect,
        minimumCenterDistance: CGFloat
    ) -> [CGPoint]? {
        // Calculate max cols/rows that fit with minimum distance
        let maxCols = max(1, Int(playableRect.width / minimumCenterDistance) + 1)
        let maxRows = max(1, Int(playableRect.height / minimumCenterDistance) + 1)

        guard maxCols * maxRows >= count else { return nil }

        // Find the smallest grid that fits all balls
        var cols = min(maxCols, Int(ceil(sqrt(Double(count) * Double(playableRect.width) / Double(playableRect.height)))))
        var rows = Int(ceil(Double(count) / Double(cols)))

        // Adjust if rows exceed max
        if rows > maxRows {
            rows = maxRows
            cols = Int(ceil(Double(count) / Double(rows)))
        }

        guard cols > 0, rows > 0, cols <= maxCols, rows <= maxRows else { return nil }

        let cellWidth = playableRect.width / CGFloat(cols)
        let cellHeight = playableRect.height / CGFloat(rows)

        let maxJitter = min(cellWidth, cellHeight) * 0.2

        var positions: [CGPoint] = []

        // Generate all grid positions, then shuffle and take `count`
        var gridPositions: [(Int, Int)] = []
        for row in 0..<rows {
            for col in 0..<cols {
                gridPositions.append((row, col))
            }
        }
        gridPositions.shuffle()

        for i in 0..<min(count, gridPositions.count) {
            let (row, col) = gridPositions[i]
            let baseX = playableRect.minX + CGFloat(col) * cellWidth + cellWidth / 2
            let baseY = playableRect.minY + CGFloat(row) * cellHeight + cellHeight / 2

            let jitterX = CGFloat.random(in: -maxJitter...maxJitter)
            let jitterY = CGFloat.random(in: -maxJitter...maxJitter)

            let point = CGPoint(
                x: min(max(baseX + jitterX, playableRect.minX), playableRect.maxX),
                y: min(max(baseY + jitterY, playableRect.minY), playableRect.maxY)
            )
            positions.append(point)
        }

        guard positions.count == count else { return nil }

        // Verify no overlaps after jitter
        for i in 0..<positions.count {
            for j in (i + 1)..<positions.count {
                if distance(positions[i], positions[j]) < minimumCenterDistance {
                    // Remove jitter — use exact grid positions
                    return gridPlacementExact(count: count, playableRect: playableRect, cols: cols, rows: rows)
                }
            }
        }

        return positions
    }

    /// Exact grid placement without jitter (last resort).
    private static func gridPlacementExact(
        count: Int,
        playableRect: CGRect,
        cols: Int,
        rows: Int
    ) -> [CGPoint]? {
        let cellWidth = playableRect.width / CGFloat(cols)
        let cellHeight = playableRect.height / CGFloat(rows)

        var positions: [CGPoint] = []
        var gridPositions: [(Int, Int)] = []

        for row in 0..<rows {
            for col in 0..<cols {
                gridPositions.append((row, col))
            }
        }
        gridPositions.shuffle()

        for i in 0..<min(count, gridPositions.count) {
            let (row, col) = gridPositions[i]
            let x = playableRect.minX + CGFloat(col) * cellWidth + cellWidth / 2
            let y = playableRect.minY + CGFloat(row) * cellHeight + cellHeight / 2
            positions.append(CGPoint(x: x, y: y))
        }

        return positions.count == count ? positions : nil
    }

    /// Euclidean distance between two points.
    private static func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return sqrt(dx * dx + dy * dy)
    }
}
