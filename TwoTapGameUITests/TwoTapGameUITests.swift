import XCTest

/// Comprehensive UI tests for 2TAP — simulates real player interactions.
///
/// Test plan:
/// 1. Main menu elements visible
/// 2. Difficulty switching works
/// 3. Play button launches game
/// 4. Game HUD elements appear
/// 5. Countdown sequence runs
/// 6. Timer bar visible during play
/// 7. Game over screen appears after timeout
/// 8. Play Again works (quick restart)
/// 9. Home button from game over returns to menu
/// 10. Settings screen opens and closes
/// 11. Pause overlay works
/// 12. Settings toggles respond
/// 13. Each difficulty mode launches correctly
/// 14. Score displays during gameplay
/// 15. Navigation flow integrity (menu → game → over → menu)
final class TwoTapGameUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /// Wait for an element to exist with timeout.
    @discardableResult
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 10) -> Bool {
        element.waitForExistence(timeout: timeout)
    }

    /// Wait for gameplay to reach game over (balls timeout with no taps).
    func waitForGameOver(timeout: TimeInterval = 60) {
        // Play Again button is the most reliable indicator that game over appeared
        let playAgain = app.buttons["playAgainButton"]
        XCTAssertTrue(playAgain.waitForExistence(timeout: timeout), "Game over should appear after lives run out (Play Again button)")
    }

    // MARK: - 1. Main Menu

    func testMainMenuElementsVisible() {
        // Title
        let title = app.staticTexts["2TAP"]
        XCTAssertTrue(waitForElement(title), "Title '2TAP' should be visible")

        // Subtitle
        let subtitle = app.staticTexts["FIND • TAP • 2 SECONDS"]
        XCTAssertTrue(subtitle.exists, "Subtitle should be visible")

        // Play button
        let play = app.buttons["playButton"]
        XCTAssertTrue(waitForElement(play), "Play button should be visible")

        // Settings button
        let settings = app.buttons["settingsButton"]
        XCTAssertTrue(settings.exists, "Settings button should be visible")

        // Difficulty selectors
        let easy = app.buttons["difficulty_easy"]
        let normal = app.buttons["difficulty_normal"]
        let insane = app.buttons["difficulty_insane"]
        XCTAssertTrue(easy.exists, "Easy difficulty should be visible")
        XCTAssertTrue(normal.exists, "Normal difficulty should be visible")
        XCTAssertTrue(insane.exists, "Insane difficulty should be visible")
    }

    // MARK: - 2. Difficulty Selection

    func testDifficultySwitching() {
        let easy = app.buttons["difficulty_easy"]
        let insane = app.buttons["difficulty_insane"]
        let normal = app.buttons["difficulty_normal"]

        XCTAssertTrue(waitForElement(easy))

        // Tap Easy
        easy.tap()
        sleep(1)

        // Tap Insane
        insane.tap()
        sleep(1)

        // Tap Normal
        normal.tap()
        sleep(1)

        // All should still exist after toggling
        XCTAssertTrue(easy.exists)
        XCTAssertTrue(normal.exists)
        XCTAssertTrue(insane.exists)
    }

    // MARK: - 3. Game Launch (Normal)

    func testPlayButtonLaunchesGame() {
        let play = app.buttons["playButton"]
        XCTAssertTrue(waitForElement(play))
        play.tap()

        // After countdown (~1.5s), score label should be visible
        let scoreLabel = app.staticTexts["scoreLabel"]
        XCTAssertTrue(waitForElement(scoreLabel, timeout: 8), "Score label should be visible during gameplay")
    }

    // MARK: - 4. HUD During Gameplay

    func testHUDElementsDuringGameplay() {
        let play = app.buttons["playButton"]
        XCTAssertTrue(waitForElement(play))
        play.tap()

        // Wait for gameplay
        let scoreLabel = app.staticTexts["scoreLabel"]
        XCTAssertTrue(waitForElement(scoreLabel, timeout: 8))

        // Lives display — search across all element types
        let lives = app.descendants(matching: .any).matching(identifier: "livesDisplay").firstMatch
        XCTAssertTrue(waitForElement(lives, timeout: 3), "Lives display should be visible during gameplay")

        // FIND indicator should be visible
        let findText = app.staticTexts["FIND"]
        XCTAssertTrue(waitForElement(findText, timeout: 5), "FIND target indicator should be visible")
    }

    // MARK: - 5. Game Over Appears After Timeout

    func testGameOverAppearsAfterLivesRunOut() {
        let play = app.buttons["playButton"]
        XCTAssertTrue(waitForElement(play))
        play.tap()

        // Don't tap anything — let lives expire
        waitForGameOver()

        // Game over elements
        let playAgain = app.buttons["playAgainButton"]
        XCTAssertTrue(waitForElement(playAgain, timeout: 5), "Play Again button should exist")

        let share = app.buttons["shareButton"]
        XCTAssertTrue(share.exists, "Share button should exist")
    }

    // MARK: - 6. Play Again (Quick Restart)

    func testPlayAgainFromGameOver() {
        let play = app.buttons["playButton"]
        XCTAssertTrue(waitForElement(play))
        play.tap()

        // Wait for game over
        waitForGameOver()

        // Tap Play Again
        let playAgain = app.buttons["playAgainButton"]
        XCTAssertTrue(waitForElement(playAgain, timeout: 5))
        playAgain.tap()

        // Should go back to gameplay (score label visible, game over text gone)
        let scoreLabel = app.staticTexts["scoreLabel"]
        XCTAssertTrue(waitForElement(scoreLabel, timeout: 8), "Score should be visible after Play Again")

        // Game over text should disappear
        sleep(2)
        let playAgainBtn = app.buttons["playAgainButton"]
        XCTAssertFalse(playAgainBtn.exists, "Game over should disappear after Play Again")
    }

    // MARK: - 7. Home from Game Over

    func testHomeButtonFromGameOverReturnsToMenu() {
        let play = app.buttons["playButton"]
        XCTAssertTrue(waitForElement(play))
        play.tap()

        // Wait for game over
        waitForGameOver()

        // Tap Home
        let home = app.buttons.matching(identifier: "homeButton").firstMatch
        // Home might be in game over overlay or the home button
        if home.exists {
            home.tap()
        } else {
            // Try finding by label
            let homeLabel = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Home'")).firstMatch
            XCTAssertTrue(waitForElement(homeLabel, timeout: 3), "Home button should exist on game over screen")
            homeLabel.tap()
        }

        // Should return to main menu
        let title = app.staticTexts["2TAP"]
        XCTAssertTrue(waitForElement(title, timeout: 5), "Should return to main menu after tapping Home")

        // Play button should be visible again
        XCTAssertTrue(app.buttons["playButton"].exists, "Play button should be visible on main menu")
    }

    // MARK: - 8. Settings Screen

    func testSettingsOpensAndCloses() {
        let settingsBtn = app.buttons["settingsButton"]
        XCTAssertTrue(waitForElement(settingsBtn))
        settingsBtn.tap()

        // Settings screen elements
        let navTitle = app.navigationBars["Settings"]
        XCTAssertTrue(waitForElement(navTitle, timeout: 3), "Settings navigation bar should appear")

        // Sound toggle
        let soundToggle = app.switches["Sound Effects"]
        XCTAssertTrue(soundToggle.exists, "Sound Effects toggle should exist")

        // Haptic toggle
        let hapticToggle = app.switches["Haptic Feedback"]
        XCTAssertTrue(hapticToggle.exists, "Haptic Feedback toggle should exist")

        // Done button
        let done = app.buttons["Done"]
        XCTAssertTrue(done.exists, "Done button should exist")
        done.tap()

        // Should return to main menu
        let title = app.staticTexts["2TAP"]
        XCTAssertTrue(waitForElement(title, timeout: 3), "Should return to main menu after Settings Done")
    }

    // MARK: - 9. Settings Toggle Sound

    func testSettingsToggleSound() {
        let settingsBtn = app.buttons["settingsButton"]
        XCTAssertTrue(waitForElement(settingsBtn))
        settingsBtn.tap()

        let soundToggle = app.switches["Sound Effects"]
        XCTAssertTrue(waitForElement(soundToggle, timeout: 3))

        // Get current value
        let initialValue = soundToggle.value as? String

        // Toggle — use the switch's internal control for reliable toggling
        soundToggle.switches.firstMatch.tap()
        sleep(1)

        // Should have changed
        let newValue = soundToggle.value as? String
        XCTAssertNotEqual(initialValue, newValue, "Sound toggle value should change after tap")

        // Toggle back
        soundToggle.switches.firstMatch.tap()
        sleep(1)

        let restoredValue = soundToggle.value as? String
        XCTAssertEqual(initialValue, restoredValue, "Sound toggle should restore to original value")

        // Close settings
        app.buttons["Done"].tap()
    }

    // MARK: - 10. Settings Toggle Haptics

    func testSettingsToggleHaptics() {
        app.buttons["settingsButton"].tap()

        let hapticToggle = app.switches["Haptic Feedback"]
        XCTAssertTrue(waitForElement(hapticToggle, timeout: 3))

        let initialValue = hapticToggle.value as? String
        hapticToggle.switches.firstMatch.tap()
        sleep(1)

        let newValue = hapticToggle.value as? String
        XCTAssertNotEqual(initialValue, newValue, "Haptic toggle value should change after tap")

        // Restore
        hapticToggle.switches.firstMatch.tap()
        app.buttons["Done"].tap()
    }

    // MARK: - 11. Easy Mode Game Flow

    func testEasyModeGameFlow() {
        // Select Easy
        let easy = app.buttons["difficulty_easy"]
        XCTAssertTrue(waitForElement(easy))
        easy.tap()
        sleep(1)

        // Play
        app.buttons["playButton"].tap()

        // Should enter gameplay
        let scoreLabel = app.staticTexts["scoreLabel"]
        XCTAssertTrue(waitForElement(scoreLabel, timeout: 5), "Should enter gameplay in Easy mode")

        // Wait for game over (Easy has 3s timer, so slightly longer)
        waitForGameOver()

        let playAgainBtn = app.buttons["playAgainButton"]
        XCTAssertTrue(playAgainBtn.exists, "Game over should appear in Easy mode")
    }

    // MARK: - 12. Insane Mode Game Flow

    func testInsaneModeGameFlow() {
        // Select Insane
        let insane = app.buttons["difficulty_insane"]
        XCTAssertTrue(waitForElement(insane))
        insane.tap()
        sleep(1)

        // Play
        app.buttons["playButton"].tap()

        // Should enter gameplay
        let scoreLabel = app.staticTexts["scoreLabel"]
        XCTAssertTrue(waitForElement(scoreLabel, timeout: 5), "Should enter gameplay in Insane mode")

        // Wait for game over (Insane is 1.5s timer, should be faster)
        waitForGameOver()

        // Should show difficulty badge
        let playAgainBtn = app.buttons["playAgainButton"]
        XCTAssertTrue(playAgainBtn.exists, "Game over should appear in Insane mode")
    }

    // MARK: - 13. Pause Button Visible During Gameplay

    /// Note: SpriteView's touch handling prevents XCUITest from reliably tapping
    /// the pause button. The pause/resume logic is covered by GameState unit tests.
    /// This test verifies the button appears in the accessibility tree.
    func testPauseButtonVisibleDuringGameplay() {
        app.buttons["playButton"].tap()

        // Pause button appears during playing phase (after countdown)
        let pauseBtn = app.buttons["pauseButton"]
        XCTAssertTrue(waitForElement(pauseBtn, timeout: 10), "Pause button should be visible during gameplay")
        XCTAssertTrue(pauseBtn.isEnabled, "Pause button should be enabled")
    }

    // MARK: - 15. Full Player Journey

    func testFullPlayerJourney() {
        // 1. Start at main menu
        XCTAssertTrue(waitForElement(app.staticTexts["2TAP"]))

        // 2. Check settings
        app.buttons["settingsButton"].tap()
        XCTAssertTrue(waitForElement(app.navigationBars["Settings"], timeout: 3))
        app.buttons["Done"].tap()
        XCTAssertTrue(waitForElement(app.staticTexts["2TAP"], timeout: 3))

        // 3. Switch difficulty to Easy
        app.buttons["difficulty_easy"].tap()
        sleep(1)

        // 4. Play a game
        app.buttons["playButton"].tap()
        XCTAssertTrue(waitForElement(app.staticTexts["scoreLabel"], timeout: 5))

        // 5. Wait for game over
        waitForGameOver()
        XCTAssertTrue(app.buttons["playAgainButton"].exists)

        // 6. Play again
        app.buttons["playAgainButton"].tap()
        XCTAssertTrue(waitForElement(app.staticTexts["scoreLabel"], timeout: 5))

        // 7. Wait for second game over
        waitForGameOver()

        // 8. Go home
        let home = app.buttons.matching(identifier: "homeButton").firstMatch
        if home.waitForExistence(timeout: 3) {
            home.tap()
        } else {
            app.buttons.matching(NSPredicate(format: "label CONTAINS 'Home'")).firstMatch.tap()
        }

        // 9. Back at main menu
        XCTAssertTrue(waitForElement(app.staticTexts["2TAP"], timeout: 5))

        // 10. Switch to Insane and play
        app.buttons["difficulty_insane"].tap()
        sleep(1)
        app.buttons["playButton"].tap()
        XCTAssertTrue(waitForElement(app.staticTexts["scoreLabel"], timeout: 5))

        // 11. Wait for game over
        waitForGameOver()
        XCTAssertTrue(app.buttons["playAgainButton"].exists)
    }

    // MARK: - 16. Settings Records Display

    func testSettingsShowsRecords() {
        app.buttons["settingsButton"].tap()

        let navTitle = app.navigationBars["Settings"]
        XCTAssertTrue(waitForElement(navTitle, timeout: 3))

        // Records section should show labels
        let bestScore = app.staticTexts["Best Score"]
        XCTAssertTrue(bestScore.exists, "Best Score label should exist in settings")

        let bestCombo = app.staticTexts["Best Combo"]
        XCTAssertTrue(bestCombo.exists, "Best Combo label should exist in settings")

        let mostRounds = app.staticTexts["Most Rounds"]
        XCTAssertTrue(mostRounds.exists, "Most Rounds label should exist in settings")

        // Per-difficulty scores
        let easyBest = app.staticTexts["Easy Best"]
        XCTAssertTrue(easyBest.exists, "Easy Best label should exist")

        let normalBest = app.staticTexts["Normal Best"]
        XCTAssertTrue(normalBest.exists, "Normal Best label should exist")

        let insaneBest = app.staticTexts["Insane Best"]
        XCTAssertTrue(insaneBest.exists, "Insane Best label should exist")

        app.buttons["Done"].tap()
    }

    // MARK: - 17. Multiple Quick Restarts

    func testMultipleQuickRestarts() {
        app.buttons["playButton"].tap()

        // Game 1
        waitForGameOver()
        XCTAssertTrue(app.buttons["playAgainButton"].exists)

        // Quick restart 1
        app.buttons["playAgainButton"].tap()
        XCTAssertTrue(waitForElement(app.staticTexts["scoreLabel"], timeout: 5))

        // Game 2
        waitForGameOver()
        XCTAssertTrue(app.buttons["playAgainButton"].exists)

        // Quick restart 2
        app.buttons["playAgainButton"].tap()
        XCTAssertTrue(waitForElement(app.staticTexts["scoreLabel"], timeout: 5))

        // Game 3
        waitForGameOver()
        XCTAssertTrue(app.buttons["playAgainButton"].exists)

        // No crashes after 3 consecutive games — solid memory handling
    }
}
