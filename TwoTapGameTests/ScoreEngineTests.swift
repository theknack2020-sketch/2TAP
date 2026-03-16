import XCTest
@testable import TwoTapGame

final class ScoreEngineTests: XCTestCase {

    func testBasePoints() {
        let points = ScoreEngine.pointsForRound(combo: 1)
        XCTAssertEqual(points, 100)
    }

    func testComboMultiplier() {
        XCTAssertEqual(ScoreEngine.pointsForRound(combo: 1), 100)
        XCTAssertEqual(ScoreEngine.pointsForRound(combo: 2), 200)
        XCTAssertEqual(ScoreEngine.pointsForRound(combo: 5), 500)
        XCTAssertEqual(ScoreEngine.pointsForRound(combo: 10), 1000)
    }

    func testComboMaxCap() {
        XCTAssertEqual(ScoreEngine.pointsForRound(combo: 15), 1000) // capped at x10
    }

    // MARK: - Edge Cases

    func testComboZeroReturnsZeroPoints() {
        XCTAssertEqual(ScoreEngine.pointsForRound(combo: 0), 0)
    }

    func testComboNegativeReturnsNegativePoints() {
        // Negative combo shouldn't happen in practice, but verify behavior
        let points = ScoreEngine.pointsForRound(combo: -1)
        XCTAssertEqual(points, -100) // 100 × -1
    }

    func testComboExactly10IsNotCapped() {
        XCTAssertEqual(ScoreEngine.pointsForRound(combo: 10), 1000)
    }

    func testCombo11IsCapped() {
        XCTAssertEqual(ScoreEngine.pointsForRound(combo: 11), 1000)
    }

    func testBonusLifeEvery10() {
        XCTAssertFalse(ScoreEngine.shouldAwardBonusLife(consecutivePerfect: 0))
        XCTAssertFalse(ScoreEngine.shouldAwardBonusLife(consecutivePerfect: 5))
        XCTAssertFalse(ScoreEngine.shouldAwardBonusLife(consecutivePerfect: 9))
        XCTAssertTrue(ScoreEngine.shouldAwardBonusLife(consecutivePerfect: 10))
        XCTAssertFalse(ScoreEngine.shouldAwardBonusLife(consecutivePerfect: 15))
        XCTAssertTrue(ScoreEngine.shouldAwardBonusLife(consecutivePerfect: 20))
    }
}

final class DifficultyEngineTests: XCTestCase {

    func testStartsAt6Balls() {
        XCTAssertEqual(DifficultyEngine.ballCount(forScore: 0), 6)
    }

    func testIncreasesWithScore() {
        XCTAssertEqual(DifficultyEngine.ballCount(forScore: 500), 7)
        XCTAssertEqual(DifficultyEngine.ballCount(forScore: 1200), 8)
        XCTAssertEqual(DifficultyEngine.ballCount(forScore: 4000), 9)
    }

    func testRespectsMaxBalls() {
        XCTAssertEqual(DifficultyEngine.ballCount(forScore: 99999, maxBalls: 8), 8)
    }

    // MARK: - Edge Cases

    func testAllThresholds() {
        XCTAssertEqual(DifficultyEngine.ballCount(forScore: 0), 6)
        XCTAssertEqual(DifficultyEngine.ballCount(forScore: 499), 6)
        XCTAssertEqual(DifficultyEngine.ballCount(forScore: 500), 7)
        XCTAssertEqual(DifficultyEngine.ballCount(forScore: 1199), 7)
        XCTAssertEqual(DifficultyEngine.ballCount(forScore: 1200), 8)
        XCTAssertEqual(DifficultyEngine.ballCount(forScore: 2500), 8) // still 8 at 2500
        XCTAssertEqual(DifficultyEngine.ballCount(forScore: 4000), 9)
        XCTAssertEqual(DifficultyEngine.ballCount(forScore: 6000), 10)
        XCTAssertEqual(DifficultyEngine.ballCount(forScore: 9000), 11)
        XCTAssertEqual(DifficultyEngine.ballCount(forScore: 13000), 12)
    }

    func testNegativeScoreReturnsSixBalls() {
        XCTAssertEqual(DifficultyEngine.ballCount(forScore: -100), 6)
    }

    func testMaxBallsZeroReturnsZero() {
        // Edge: maxBalls=0 should clamp to 0
        XCTAssertEqual(DifficultyEngine.ballCount(forScore: 0, maxBalls: 0), 0)
    }

    func testLevelNames() {
        XCTAssertEqual(DifficultyEngine.levelName(forScore: 0), "Easy")
        XCTAssertEqual(DifficultyEngine.levelName(forScore: 600), "Normal")
        XCTAssertEqual(DifficultyEngine.levelName(forScore: 3000), "Expert")
        XCTAssertEqual(DifficultyEngine.levelName(forScore: 15000), "Insane")
    }
}
