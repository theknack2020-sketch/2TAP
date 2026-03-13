import SpriteKit
import UIKit

/// The main SpriteKit game scene.
///
/// Manages ball spawning, touch detection, timer, and round cycling.
/// Communicates state to SwiftUI via GameState (@Observable).
class GameScene: SKScene {

    // MARK: - Properties

    var gameState: GameState?

    private var ballNodes: [BallNode] = []
    private var lastUpdateTime: TimeInterval = 0
    private var timerActive: Bool = false

    // Round data
    private var currentRoundColors: RoundColors?

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
    }

    // MARK: - Round Management

    /// Start a new game from the beginning.
    func startGame() {
        guard let state = gameState else { return }

        Task { @MainActor in
            state.reset()
            state.phase = .countdown(number: 3)
        }

        runCountdown()
    }

    /// Start the next round (no countdown between rounds).
    func startNextRound() {
        guard let state = gameState else { return }

        // Clear existing balls
        clearBalls {
            self.spawnBalls()
            self.startTimer()
        }

        Task { @MainActor in
            state.roundNumber += 1
        }
    }

    /// Spawn balls for the current round.
    private func spawnBalls() {
        guard let state = gameState else { return }
        let screenSize = size

        let ballRadius = BallPlacementEngine.recommendedBallRadius(
            for: screenSize,
            ballCount: state.ballCount
        )

        guard let positions = BallPlacementEngine.generatePositions(
            count: state.ballCount,
            ballRadius: ballRadius,
            screenSize: screenSize
        ) else {
            // Placement failed — this shouldn't happen with reasonable ball counts
            print("⚠️ Ball placement failed for \(state.ballCount) balls on \(screenSize)")
            return
        }

        let roundColors = ColorMatchEngine.generateRound(
            ballCount: state.ballCount,
            palette: state.palette
        )
        currentRoundColors = roundColors

        // Create ball nodes
        var newBalls: [BallState] = []
        for (index, position) in positions.enumerated() {
            let color = roundColors.assignments[index]
            let isMatch = roundColors.matchingIndices.contains(index)

            let node = BallNode(
                id: index,
                color: color,
                radius: ballRadius,
                isMatch: isMatch
            )
            node.position = position
            node.animateAppear(delay: Double(index) * 0.05)

            addChild(node)
            ballNodes.append(node)

            newBalls.append(BallState(
                id: index,
                color: color,
                position: position,
                isMatch: isMatch
            ))
        }

        Task { @MainActor in
            state.balls = newBalls
        }
    }

    /// Clear all ball nodes with animation.
    private func clearBalls(completion: @escaping () -> Void) {
        guard !ballNodes.isEmpty else {
            completion()
            return
        }

        let group = DispatchGroup()

        for node in ballNodes {
            group.enter()
            node.animateDisappear {
                node.removeFromParent()
                group.leave()
            }
        }

        ballNodes.removeAll()

        group.notify(queue: .main) {
            completion()
        }
    }

    // MARK: - Countdown

    private func runCountdown() {
        guard let state = gameState else { return }

        let countdownSequence = SKAction.sequence([
            // "3"
            SKAction.run {
                Task { @MainActor in state.phase = .countdown(number: 3) }
            },
            SKAction.wait(forDuration: 0.8),
            // "2"
            SKAction.run {
                Task { @MainActor in state.phase = .countdown(number: 2) }
            },
            SKAction.wait(forDuration: 0.8),
            // "1"
            SKAction.run {
                Task { @MainActor in state.phase = .countdown(number: 1) }
            },
            SKAction.wait(forDuration: 0.8),
            // Start playing
            SKAction.run { [weak self] in
                Task { @MainActor in
                    state.phase = .playing
                    state.roundNumber = 1
                }
                self?.spawnBalls()
                self?.startTimer()
            }
        ])

        run(countdownSequence, withKey: "countdown")
    }

    // MARK: - Timer

    private func startTimer() {
        guard let state = gameState else { return }

        Task { @MainActor in
            state.timerProgress = 1.0
        }

        lastUpdateTime = 0
        timerActive = true
    }

    override func update(_ currentTime: TimeInterval) {
        guard timerActive, let state = gameState else { return }

        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            return
        }

        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        // Only update timer while playing
        guard state.phase == .playing else { return }

        let newProgress = max(0, state.timerProgress - (deltaTime / state.timerDuration))

        Task { @MainActor in
            state.timerProgress = newProgress

            if newProgress <= 0 {
                self.timerActive = false
                self.handleTimeout()
            }
        }
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let state = gameState, state.phase == .playing else { return }
        guard let touch = touches.first else { return }

        let location = touch.location(in: self)

        // Find which ball was tapped
        for node in ballNodes {
            if node.hitTest(at: location) && !node.isTapped {
                handleBallTap(node)
                return
            }
        }
        // Tapping empty space — do nothing (not a mistake)
    }

    private func handleBallTap(_ node: BallNode) {
        guard let state = gameState else { return }

        node.tap()

        Task { @MainActor in
            state.markBallTapped(id: node.ballId)
        }

        if node.isMatch {
            // Correct tap — check if all matches found
            Task { @MainActor in
                if state.allMatchesTapped {
                    self.handleRoundSuccess()
                }
            }
        } else {
            // Wrong tap — round failure
            node.showError()
            handleRoundFailure()
        }
    }

    // MARK: - Round Results

    private func handleRoundSuccess() {
        guard let state = gameState else { return }
        timerActive = false

        // Celebrate matching balls
        for node in ballNodes where node.isMatch {
            node.celebrateMatch()
        }

        Task { @MainActor in
            state.phase = .success
            state.combo += 1
            state.bestCombo = max(state.bestCombo, state.combo)
            state.roundsSurvived += 1
            state.score += 10 * state.combo // Basic scoring — refined in S02
        }

        // Brief pause then next round
        let nextAction = SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.run { [weak self] in
                guard let self = self, let state = self.gameState else { return }
                Task { @MainActor in
                    if state.lives > 0 {
                        state.phase = .playing
                    }
                }
                self.startNextRound()
            }
        ])
        run(nextAction, withKey: "nextRound")
    }

    private func handleRoundFailure() {
        guard let state = gameState else { return }
        timerActive = false

        Task { @MainActor in
            state.phase = .failure
            state.combo = 0
            state.lives -= 1

            if state.lives <= 0 {
                state.phase = .gameOver
            }
        }

        // Brief pause then next round (or game over)
        let nextAction = SKAction.sequence([
            SKAction.wait(forDuration: 0.8),
            SKAction.run { [weak self] in
                guard let self = self, let state = self.gameState else { return }
                Task { @MainActor in
                    if state.lives > 0 {
                        state.phase = .playing
                        self.startNextRound()
                    }
                    // If game over, SwiftUI handles the overlay
                }
            }
        ])
        run(nextAction, withKey: "nextRound")
    }

    private func handleTimeout() {
        handleRoundFailure()
    }

    // MARK: - Pause

    func togglePause() {
        guard let state = gameState else { return }

        Task { @MainActor in
            if state.isPaused {
                state.isPaused = false
                self.isPaused = false
            } else if state.pausesRemaining > 0 {
                state.isPaused = true
                state.pausesRemaining -= 1
                self.isPaused = true
            }
        }
    }
}
