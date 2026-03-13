import XCTest
@testable import TwoTapGame

final class BallPlacementEngineTests: XCTestCase {

    let iPhoneSESize = CGSize(width: 375, height: 667)
    let iPhone16ProSize = CGSize(width: 393, height: 852)
    let iPhoneProMaxSize = CGSize(width: 430, height: 932)

    // MARK: - Basic Placement

    func testPlaces5Balls() throws {
        let positions = try XCTUnwrap(
            BallPlacementEngine.generatePositions(
                count: 5,
                ballRadius: 30,
                screenSize: iPhone16ProSize
            )
        )
        XCTAssertEqual(positions.count, 5)
    }

    func testPlaces7Balls() throws {
        let positions = try XCTUnwrap(
            BallPlacementEngine.generatePositions(
                count: 7,
                ballRadius: 30,
                screenSize: iPhone16ProSize
            )
        )
        XCTAssertEqual(positions.count, 7)
    }

    func testPlaces12Balls() throws {
        let radius = BallPlacementEngine.recommendedBallRadius(
            for: iPhone16ProSize,
            ballCount: 12
        )
        let positions = try XCTUnwrap(
            BallPlacementEngine.generatePositions(
                count: 12,
                ballRadius: radius,
                screenSize: iPhone16ProSize
            )
        )
        XCTAssertEqual(positions.count, 12)
    }

    // MARK: - Non-Overlapping

    func testBallsDoNotOverlap() throws {
        let ballRadius: CGFloat = 30
        let minimumCenterDistance = 2 * ballRadius + BallPlacementEngine.minimumGap

        // Run multiple times to test randomness
        for _ in 0..<20 {
            let positions = try XCTUnwrap(
                BallPlacementEngine.generatePositions(
                    count: 7,
                    ballRadius: ballRadius,
                    screenSize: iPhone16ProSize
                )
            )

            for i in 0..<positions.count {
                for j in (i + 1)..<positions.count {
                    let dx = positions[i].x - positions[j].x
                    let dy = positions[i].y - positions[j].y
                    let dist = sqrt(dx * dx + dy * dy)

                    XCTAssertGreaterThanOrEqual(
                        dist,
                        minimumCenterDistance - 0.01, // tiny float tolerance
                        "Balls \(i) and \(j) are too close: \(dist) < \(minimumCenterDistance)"
                    )
                }
            }
        }
    }

    // MARK: - Screen Edge Margins

    func testBallsStayWithinBounds() throws {
        let ballRadius: CGFloat = 30
        let margin = BallPlacementEngine.edgeMargin

        for _ in 0..<20 {
            let positions = try XCTUnwrap(
                BallPlacementEngine.generatePositions(
                    count: 7,
                    ballRadius: ballRadius,
                    screenSize: iPhone16ProSize
                )
            )

            for (index, pos) in positions.enumerated() {
                XCTAssertGreaterThanOrEqual(
                    pos.x - ballRadius, margin - 0.01,
                    "Ball \(index) left edge too close: \(pos.x - ballRadius)"
                )
                XCTAssertLessThanOrEqual(
                    pos.x + ballRadius, iPhone16ProSize.width - margin + 0.01,
                    "Ball \(index) right edge too close"
                )
                XCTAssertGreaterThanOrEqual(
                    pos.y - ballRadius, 0,
                    "Ball \(index) bottom edge too close"
                )
                XCTAssertLessThanOrEqual(
                    pos.y + ballRadius, iPhone16ProSize.height + 0.01,
                    "Ball \(index) top edge too close"
                )
            }
        }
    }

    // MARK: - Recommended Radius

    func testRecommendedRadiusIsReasonable() {
        let radius5 = BallPlacementEngine.recommendedBallRadius(
            for: iPhone16ProSize, ballCount: 5
        )
        let radius12 = BallPlacementEngine.recommendedBallRadius(
            for: iPhone16ProSize, ballCount: 12
        )

        XCTAssertGreaterThanOrEqual(radius5, 20, "Radius too small for 5 balls")
        XCTAssertLessThanOrEqual(radius5, 40, "Radius too large")
        XCTAssertGreaterThanOrEqual(radius12, 20, "Radius too small for 12 balls")
        XCTAssertLessThanOrEqual(radius12, radius5, "More balls should mean smaller or equal radius")
    }

    // MARK: - iPhone SE (Smallest Screen)

    func testPlacementWorksOnSmallScreen() throws {
        let radius = BallPlacementEngine.recommendedBallRadius(
            for: iPhoneSESize, ballCount: 7
        )
        let positions = try XCTUnwrap(
            BallPlacementEngine.generatePositions(
                count: 7,
                ballRadius: radius,
                screenSize: iPhoneSESize
            )
        )
        XCTAssertEqual(positions.count, 7)
    }

    // MARK: - Max Ball Count

    func testMaxBallCountIsReasonable() {
        let maxSE = BallPlacementEngine.maxBallCount(for: iPhoneSESize)
        let maxPro = BallPlacementEngine.maxBallCount(for: iPhone16ProSize)
        let maxProMax = BallPlacementEngine.maxBallCount(for: iPhoneProMaxSize)

        XCTAssertGreaterThanOrEqual(maxSE, 7, "SE should support at least 7 balls")
        XCTAssertGreaterThanOrEqual(maxPro, 9, "Pro should support at least 9 balls")
        XCTAssertGreaterThanOrEqual(maxProMax, 10, "Pro Max should support at least 10 balls")
    }

    // MARK: - Performance

    func testPlacementPerformance() {
        let radius = BallPlacementEngine.recommendedBallRadius(
            for: iPhone16ProSize, ballCount: 12
        )
        measure {
            for _ in 0..<100 {
                _ = BallPlacementEngine.generatePositions(
                    count: 12,
                    ballRadius: radius,
                    screenSize: iPhone16ProSize
                )
            }
        }
    }
}
