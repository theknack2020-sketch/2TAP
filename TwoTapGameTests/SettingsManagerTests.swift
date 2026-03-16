import XCTest
@testable import TwoTapGame

@MainActor
final class SettingsManagerTests: XCTestCase {

    private var settings: SettingsManager!

    override func setUp() {
        super.setUp()
        settings = SettingsManager.shared
        // Reset relevant state for each test
        settings.resetHighScore()
        UserDefaults.standard.removeObject(forKey: "lastPlayDate")
        UserDefaults.standard.removeObject(forKey: "currentStreak")
        UserDefaults.standard.removeObject(forKey: "bestStreak")
        UserDefaults.standard.removeObject(forKey: "totalGamesPlayed")
        // Re-read from defaults
        settings.currentStreak = 0
        settings.bestStreak = 0
        settings.totalGamesPlayed = 0
        settings.lastPlayDate = nil
    }

    // MARK: - High Score

    func testUpdateHighScoreNewRecord() {
        settings.highScore = 0
        settings.updateHighScore(score: 500, bestCombo: 3, rounds: 10, difficulty: .normal)

        XCTAssertEqual(settings.highScore, 500)
        XCTAssertEqual(settings.highScoreBestCombo, 3)
        XCTAssertEqual(settings.highScoreRounds, 10)
    }

    func testUpdateHighScoreDoesNotOverwriteLower() {
        settings.updateHighScore(score: 500, bestCombo: 3, rounds: 10, difficulty: .normal)
        settings.updateHighScore(score: 200, bestCombo: 5, rounds: 15, difficulty: .normal)

        XCTAssertEqual(settings.highScore, 500)
        XCTAssertEqual(settings.highScoreBestCombo, 3)
        XCTAssertEqual(settings.highScoreRounds, 10)
    }

    func testUpdateHighScoreOverwritesHigher() {
        settings.updateHighScore(score: 500, bestCombo: 3, rounds: 10, difficulty: .normal)
        settings.updateHighScore(score: 1000, bestCombo: 8, rounds: 20, difficulty: .normal)

        XCTAssertEqual(settings.highScore, 1000)
        XCTAssertEqual(settings.highScoreBestCombo, 8)
        XCTAssertEqual(settings.highScoreRounds, 20)
    }

    func testResetHighScore() {
        settings.updateHighScore(score: 999, bestCombo: 10, rounds: 50, difficulty: .normal)
        settings.resetHighScore()

        XCTAssertEqual(settings.highScore, 0)
        XCTAssertEqual(settings.highScoreBestCombo, 0)
        XCTAssertEqual(settings.highScoreRounds, 0)
    }

    // MARK: - Streak Logic

    func testRecordFirstGameStartsStreak() {
        settings.recordGamePlayed()

        XCTAssertEqual(settings.currentStreak, 1)
        XCTAssertEqual(settings.bestStreak, 1)
        XCTAssertEqual(settings.totalGamesPlayed, 1)
        XCTAssertNotNil(settings.lastPlayDate)
    }

    func testRecordSecondGameSameDayDoesNotIncrementStreak() {
        settings.recordGamePlayed()
        let streakAfterFirst = settings.currentStreak

        settings.recordGamePlayed()

        XCTAssertEqual(settings.currentStreak, streakAfterFirst)
        XCTAssertEqual(settings.totalGamesPlayed, 2)
    }

    func testRecordGameConsecutiveDayIncrementsStreak() {
        // Simulate yesterday
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        settings.lastPlayDate = yesterday
        settings.currentStreak = 1
        settings.bestStreak = 1

        settings.recordGamePlayed()

        XCTAssertEqual(settings.currentStreak, 2)
        XCTAssertEqual(settings.bestStreak, 2)
    }

    func testRecordGameMissedDayResetsStreak() {
        // Simulate two days ago
        let calendar = Calendar.current
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date())!
        settings.lastPlayDate = twoDaysAgo
        settings.currentStreak = 5
        settings.bestStreak = 5

        settings.recordGamePlayed()

        XCTAssertEqual(settings.currentStreak, 1)
        // bestStreak should remain 5
        XCTAssertEqual(settings.bestStreak, 5)
    }

    func testBestStreakPreserved() {
        // Build a streak of 3
        let calendar = Calendar.current
        settings.lastPlayDate = calendar.date(byAdding: .day, value: -1, to: Date())!
        settings.currentStreak = 2
        settings.bestStreak = 2

        settings.recordGamePlayed()
        XCTAssertEqual(settings.currentStreak, 3)
        XCTAssertEqual(settings.bestStreak, 3)
    }

    func testTotalGamesPlayedIncrements() {
        settings.totalGamesPlayed = 0

        settings.recordGamePlayed()
        XCTAssertEqual(settings.totalGamesPlayed, 1)

        settings.recordGamePlayed()
        XCTAssertEqual(settings.totalGamesPlayed, 2)

        settings.recordGamePlayed()
        XCTAssertEqual(settings.totalGamesPlayed, 3)
    }

    // MARK: - Palette

    func testSelectedPaletteDefault() {
        let defaultPalette = ColorPalette.default
        settings.selectedPaletteId = defaultPalette.id

        XCTAssertEqual(settings.selectedPalette.id, defaultPalette.id)
    }

    func testSelectedPaletteFallsBackToDefault() {
        settings.selectedPaletteId = "nonexistent_palette"

        XCTAssertEqual(settings.selectedPalette.id, ColorPalette.default.id)
    }

    // MARK: - Theme

    func testThemeColorScheme() {
        XCTAssertNil(AppTheme.system.colorScheme)
        XCTAssertEqual(AppTheme.light.colorScheme, .light)
        XCTAssertEqual(AppTheme.dark.colorScheme, .dark)
    }
}
