import XCTest

final class ScreenshotTest: XCTestCase {
    
    func testGameplayScreenshot() throws {
        let app = XCUIApplication()
        app.launch()
        
        sleep(2)
        
        // Take menu screenshot
        saveScreenshot(app: app, name: "01_MainMenu")
        
        // Tap PLAY button
        let playButton = app.buttons["playButton"]
        if playButton.waitForExistence(timeout: 5) {
            playButton.tap()
        }
        
        // Wait for countdown (3..2..1) + balls to appear
        sleep(5)
        saveScreenshot(app: app, name: "02_Gameplay")
        
        // Wait for timer to expire -> game over
        sleep(4)
        saveScreenshot(app: app, name: "03_GameOver")
    }
    
    private func saveScreenshot(app: XCUIApplication, name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        
        let data = screenshot.pngRepresentation
        let path = "/tmp/2tap_screenshot_\(name).png"
        try? data.write(to: URL(fileURLWithPath: path))
    }
}
