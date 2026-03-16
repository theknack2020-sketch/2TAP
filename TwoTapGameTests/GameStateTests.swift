import XCTest
@testable import TwoTapGame

@MainActor
final class GameStateTests: XCTestCase {

    private var state: GameState!

    override func setUp() {
        super.setUp()
        state = GameState()
    }

    // MARK: - reset()

    func testResetSetsDefaults() {
        state.score = 999
        state.lives = 0
        state.combo = 5
        state.roundNumber = 10
        state.phase = .gameOver
        state.isPaused = true
        state.pausesRemaining = 0
        state.ballCount = 12
        state.consecutivePerfect = 8
        state.bestCombo = 7
        state.roundsSurvived = 15

        state.reset()

        XCTAssertEqual(state.score, 0)
        XCTAssertEqual(state.lives, 3)
        XCTAssertEqual(state.combo, 0)
        XCTAssertEqual(state.roundNumber, 0)
        XCTAssertEqual(state.phase, .idle)
        XCTAssertFalse(state.isPaused)
        XCTAssertEqual(state.pausesRemaining, 3)
        XCTAssertEqual(state.ballCount, 6)
        XCTAssertEqual(state.consecutivePerfect, 0)
        XCTAssertEqual(state.bestCombo, 0)
        XCTAssertEqual(state.roundsSurvived, 0)
        XCTAssertEqual(state.timerProgress, 1.0)
        XCTAssertEqual(state.flashColor, .none)
        XCTAssertTrue(state.balls.isEmpty)
    }

    func testResetPreservesDifficultyMode() {
        state.difficultyMode = .insane
        state.reset()
        // difficultyMode should NOT be reset — it's a user selection
        XCTAssertEqual(state.difficultyMode, .insane)
    }

    func testResetPreservesPalette() {
        let customPalette = ColorPalette.allPalettes.last!
        state.palette = customPalette
        state.reset()
        // palette should NOT be reset — it's a user selection
        XCTAssertEqual(state.palette.id, customPalette.id)
    }

    // MARK: - markBallTapped()

    func testMarkBallTapped() {
        state.balls = [
            BallState(id: 0, color: .red, position: .zero, isMatch: true),
            BallState(id: 1, color: .blue, position: .zero, isMatch: false),
            BallState(id: 2, color: .red, position: .zero, isMatch: true),
        ]

        state.markBallTapped(id: 0)

        XCTAssertTrue(state.balls[0].isTapped)
        XCTAssertFalse(state.balls[1].isTapped)
        XCTAssertFalse(state.balls[2].isTapped)
    }

    func testMarkBallTappedInvalidId() {
        state.balls = [
            BallState(id: 0, color: .red, position: .zero, isMatch: true),
        ]

        // Should not crash — just no-op
        state.markBallTapped(id: 999)
        XCTAssertFalse(state.balls[0].isTapped)
    }

    func testMarkBallTappedIdempotent() {
        state.balls = [
            BallState(id: 0, color: .red, position: .zero, isMatch: true),
        ]

        state.markBallTapped(id: 0)
        state.markBallTapped(id: 0) // second call

        XCTAssertTrue(state.balls[0].isTapped)
    }

    // MARK: - allMatchesTapped

    func testAllMatchesTappedFalseWhenNoneAreTapped() {
        state.balls = [
            BallState(id: 0, color: .red, position: .zero, isMatch: true),
            BallState(id: 1, color: .blue, position: .zero, isMatch: false),
            BallState(id: 2, color: .red, position: .zero, isMatch: true),
            BallState(id: 3, color: .red, position: .zero, isMatch: true),
        ]

        XCTAssertFalse(state.allMatchesTapped)
    }

    func testAllMatchesTappedFalseWhenPartiallyTapped() {
        state.balls = [
            BallState(id: 0, color: .red, position: .zero, isMatch: true),
            BallState(id: 1, color: .blue, position: .zero, isMatch: false),
            BallState(id: 2, color: .red, position: .zero, isMatch: true),
            BallState(id: 3, color: .red, position: .zero, isMatch: true),
        ]

        state.markBallTapped(id: 0)
        state.markBallTapped(id: 2)

        XCTAssertFalse(state.allMatchesTapped)
    }

    func testAllMatchesTappedTrueWhenAllMatchesAreTapped() {
        state.balls = [
            BallState(id: 0, color: .red, position: .zero, isMatch: true),
            BallState(id: 1, color: .blue, position: .zero, isMatch: false),
            BallState(id: 2, color: .red, position: .zero, isMatch: true),
            BallState(id: 3, color: .red, position: .zero, isMatch: true),
        ]

        state.markBallTapped(id: 0)
        state.markBallTapped(id: 2)
        state.markBallTapped(id: 3)

        XCTAssertTrue(state.allMatchesTapped)
    }

    func testAllMatchesTappedTrueWithNoBalls() {
        state.balls = []
        // vacuous truth — no matches means "all" are tapped
        XCTAssertTrue(state.allMatchesTapped)
    }

    func testAllMatchesTappedIgnoresNonMatchBalls() {
        state.balls = [
            BallState(id: 0, color: .red, position: .zero, isMatch: true),
            BallState(id: 1, color: .blue, position: .zero, isMatch: false),
            BallState(id: 2, color: .red, position: .zero, isMatch: true),
            BallState(id: 3, color: .red, position: .zero, isMatch: true),
        ]

        // Tap all matches but not non-match
        state.markBallTapped(id: 0)
        state.markBallTapped(id: 2)
        state.markBallTapped(id: 3)

        XCTAssertTrue(state.allMatchesTapped)
        XCTAssertFalse(state.balls[1].isTapped) // non-match untouched
    }

    // MARK: - matchCount / tappedMatchCount

    func testMatchCount() {
        state.balls = [
            BallState(id: 0, color: .red, position: .zero, isMatch: true),
            BallState(id: 1, color: .blue, position: .zero, isMatch: false),
            BallState(id: 2, color: .red, position: .zero, isMatch: true),
            BallState(id: 3, color: .green, position: .zero, isMatch: false),
            BallState(id: 4, color: .red, position: .zero, isMatch: true),
        ]

        XCTAssertEqual(state.matchCount, 3)
    }

    func testMatchCountZero() {
        state.balls = [
            BallState(id: 0, color: .blue, position: .zero, isMatch: false),
        ]

        XCTAssertEqual(state.matchCount, 0)
    }

    func testTappedMatchCount() {
        state.balls = [
            BallState(id: 0, color: .red, position: .zero, isMatch: true),
            BallState(id: 1, color: .blue, position: .zero, isMatch: false),
            BallState(id: 2, color: .red, position: .zero, isMatch: true),
            BallState(id: 3, color: .red, position: .zero, isMatch: true),
        ]

        XCTAssertEqual(state.tappedMatchCount, 0)

        state.markBallTapped(id: 0)
        XCTAssertEqual(state.tappedMatchCount, 1)

        state.markBallTapped(id: 2)
        XCTAssertEqual(state.tappedMatchCount, 2)

        // Tap non-match — doesn't affect tappedMatchCount
        state.markBallTapped(id: 1)
        XCTAssertEqual(state.tappedMatchCount, 2)
    }

    // MARK: - matchingColor

    func testMatchingColorReturnsFirstMatchColor() {
        let red = UIColor.red
        state.balls = [
            BallState(id: 0, color: .blue, position: .zero, isMatch: false),
            BallState(id: 1, color: red, position: .zero, isMatch: true),
            BallState(id: 2, color: red, position: .zero, isMatch: true),
        ]

        XCTAssertEqual(state.matchingColor, red)
    }

    func testMatchingColorNilWhenNoBalls() {
        state.balls = []
        XCTAssertNil(state.matchingColor)
    }

    func testMatchingColorNilWhenNoMatches() {
        state.balls = [
            BallState(id: 0, color: .blue, position: .zero, isMatch: false),
        ]
        XCTAssertNil(state.matchingColor)
    }

    // MARK: - DifficultyMode

    func testDifficultyModeTimerDuration() {
        XCTAssertEqual(DifficultyMode.easy.timerDuration, 3.0)
        XCTAssertEqual(DifficultyMode.normal.timerDuration, 2.0)
        XCTAssertEqual(DifficultyMode.insane.timerDuration, 1.5)
    }

    func testTimerDurationMatchesDifficultyMode() {
        state.difficultyMode = .easy
        XCTAssertEqual(state.timerDuration, 3.0)

        state.difficultyMode = .insane
        XCTAssertEqual(state.timerDuration, 1.5)
    }

    // MARK: - RoundPhase equality

    func testRoundPhaseEquality() {
        XCTAssertEqual(RoundPhase.idle, RoundPhase.idle)
        XCTAssertEqual(RoundPhase.playing, RoundPhase.playing)
        XCTAssertEqual(RoundPhase.countdown(number: 2), RoundPhase.countdown(number: 2))
        XCTAssertNotEqual(RoundPhase.countdown(number: 2), RoundPhase.countdown(number: 1))
        XCTAssertNotEqual(RoundPhase.playing, RoundPhase.success)
    }

    // MARK: - Progressive Timer

    func testTimerDurationAtZeroScore() {
        state.difficultyMode = .normal
        state.score = 0
        XCTAssertEqual(state.timerDuration, 2.0, accuracy: 0.001)
    }

    func testTimerDurationTightensWithScore() {
        state.difficultyMode = .normal
        state.score = 5000
        // 2.0 - 5000/25000 = 2.0 - 0.2 = 1.8
        XCTAssertEqual(state.timerDuration, 1.8, accuracy: 0.001)
    }

    func testTimerDurationHasMinimumFloor() {
        state.difficultyMode = .normal
        state.score = 100000 // extreme score
        // min = 2.0 * 0.60 = 1.2
        XCTAssertEqual(state.timerDuration, 1.2, accuracy: 0.001)
    }

    func testTimerDurationEasyMode() {
        state.difficultyMode = .easy
        state.score = 0
        XCTAssertEqual(state.timerDuration, 3.0, accuracy: 0.001)

        state.score = 10000
        // 3.0 - 10000/25000 = 3.0 - 0.4 = 2.6
        XCTAssertEqual(state.timerDuration, 2.6, accuracy: 0.001)
    }

    func testTimerDurationInsaneMode() {
        state.difficultyMode = .insane
        state.score = 0
        XCTAssertEqual(state.timerDuration, 1.5, accuracy: 0.001)

        state.score = 5000
        // 1.5 - 5000/25000 = 1.5 - 0.2 = 1.3
        XCTAssertEqual(state.timerDuration, 1.3, accuracy: 0.001)

        // Floor: 1.5 * 0.60 = 0.9
        state.score = 50000
        XCTAssertEqual(state.timerDuration, 0.9, accuracy: 0.001)
    }
}
