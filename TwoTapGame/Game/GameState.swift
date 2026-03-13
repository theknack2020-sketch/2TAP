import Foundation
import Observation
import UIKit

/// Phase of a single round.
enum RoundPhase: Equatable {
    case idle
    case countdown(number: Int) // 3, 2, 1
    case playing
    case success
    case failure
    case gameOver
}

/// Represents the state of a single ball in the current round.
struct BallState: Identifiable {
    let id: Int
    let color: UIColor
    let position: CGPoint
    let isMatch: Bool
    var isTapped: Bool = false
}

/// Central game state shared between SpriteKit and SwiftUI.
///
/// SpriteKit updates this during gameplay; SwiftUI reads it for overlays.
@Observable
@MainActor
final class GameState {

    // MARK: - Round State

    var phase: RoundPhase = .idle
    var balls: [BallState] = []
    var roundNumber: Int = 0

    // MARK: - Timer

    /// Progress from 1.0 (full) to 0.0 (expired). Updated by game scene.
    var timerProgress: Double = 1.0
    let timerDuration: Double = 2.0

    // MARK: - Score

    var score: Int = 0
    var lives: Int = 3
    var combo: Int = 0
    var roundsSurvived: Int = 0
    var bestCombo: Int = 0
    var consecutivePerfect: Int = 0

    // MARK: - Feedback

    var flashColor: FlashType = .none

    enum FlashType {
        case none, success, failure
    }

    // MARK: - Pause

    var isPaused: Bool = false
    var pausesRemaining: Int = 3

    // MARK: - Configuration

    var ballCount: Int = 5
    var palette: ColorPalette = .default

    // MARK: - Computed

    var matchingColor: UIColor? {
        balls.first(where: { $0.isMatch })?.color
    }

    var allMatchesTapped: Bool {
        balls.filter { $0.isMatch }.allSatisfy { $0.isTapped }
    }

    var matchCount: Int {
        balls.filter { $0.isMatch }.count
    }

    var tappedMatchCount: Int {
        balls.filter { $0.isMatch && $0.isTapped }.count
    }

    // MARK: - Actions

    func reset() {
        phase = .idle
        balls = []
        roundNumber = 0
        timerProgress = 1.0
        score = 0
        lives = 3
        combo = 0
        roundsSurvived = 0
        bestCombo = 0
        consecutivePerfect = 0
        flashColor = .none
        isPaused = false
        pausesRemaining = 3
        ballCount = 5
    }

    func markBallTapped(id: Int) {
        guard let index = balls.firstIndex(where: { $0.id == id }) else { return }
        balls[index].isTapped = true
    }
}
