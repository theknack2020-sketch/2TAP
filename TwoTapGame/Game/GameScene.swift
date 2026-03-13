import SpriteKit
import UIKit

/// The main SpriteKit game scene.
///
/// Manages ball spawning, touch detection, timer, and round cycling.
/// Communicates state to SwiftUI via GameState (@Observable).
///
/// **Threading model:** SpriteView runs the scene on the main thread.
/// All GameState access is guarded with MainActor.assumeIsolated to
/// prevent data races between SpriteKit's update loop and SwiftUI.
class GameScene: SKScene {

    // MARK: - Properties

    var gameState: GameState?

    private var ballNodes: [BallNode] = []
    private var lastUpdateTime: TimeInterval = 0
    private var timerActive: Bool = false

    // Local timer shadow — avoids reading GameState from render thread
    private var localTimerProgress: Double = 1.0
    private var localTimerDuration: Double = 2.0
    private var localPhase: RoundPhase = .idle

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

        // Cancel any pending actions
        removeAction(forKey: "countdown")
        removeAction(forKey: "nextRound")
        timerActive = false
        localPhase = .idle

        // Clear any leftover balls
        clearBallsImmediate()

        Task { @MainActor in
            state.reset()
        }

        runCountdown(isFirstRound: true)
    }

    /// Start the next round with 2-1 countdown between rounds.
    func startNextRound() {
        clearBalls { [weak self] in
            self?.runCountdown(isFirstRound: false)
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
            print("⚠️ Ball placement failed for \(state.ballCount) balls on \(screenSize)")
            return
        }

        let roundColors = ColorMatchEngine.generateRound(
            ballCount: state.ballCount,
            palette: state.palette
        )
        currentRoundColors = roundColors

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

    /// Clear all ball nodes immediately (no animation).
    private func clearBallsImmediate() {
        for node in ballNodes {
            node.removeFromParent()
        }
        ballNodes.removeAll()
    }

    // MARK: - Countdown (2-1, not 3-2-1)

    private func runCountdown(isFirstRound: Bool) {
        guard let state = gameState else { return }

        let countdownSequence = SKAction.sequence([
            SKAction.run {
                Task { @MainActor in state.phase = .countdown(number: 2) }
            },
            SKAction.wait(forDuration: 0.7),
            SKAction.run {
                Task { @MainActor in state.phase = .countdown(number: 1) }
            },
            SKAction.wait(forDuration: 0.7),
            SKAction.run { [weak self] in
                guard let self = self, let state = self.gameState else { return }
                Task { @MainActor in
                    if isFirstRound {
                        state.roundNumber = 1
                    } else {
                        state.roundNumber += 1
                    }
                    state.phase = .playing
                }
                self.localPhase = .playing
                self.spawnBalls()
                self.startTimer()
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

        localTimerProgress = 1.0
        localTimerDuration = state.timerDuration
        lastUpdateTime = 0
        timerActive = true
    }

    override func update(_ currentTime: TimeInterval) {
        guard timerActive else { return }
        guard localPhase == .playing else { return }

        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            return
        }

        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        // Update local shadow timer
        localTimerProgress = max(0, localTimerProgress - (deltaTime / localTimerDuration))
        let progress = localTimerProgress

        // Sync to GameState for UI
        Task { @MainActor in
            self.gameState?.timerProgress = progress
        }

        if progress <= 0 {
            timerActive = false
            // Don't set localPhase here — handleRoundFailure will do it
            handleTimeout()
        }
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Use local phase shadow to avoid cross-thread read
        guard localPhase == .playing else { return }
        guard let state = gameState else { return }
        guard !state.isPaused else { return } // pause guard
        guard let touch = touches.first else { return }

        let location = touch.location(in: self)

        for node in ballNodes {
            if node.hitTest(at: location) && !node.isTapped {
                handleBallTap(node)
                return
            }
        }
    }

    private func handleBallTap(_ node: BallNode) {
        guard let state = gameState else { return }
        guard localPhase == .playing else { return } // race guard

        if node.isMatch {
            node.tapCorrect()
            Task { @MainActor in
                AudioManager.shared.playCorrectTap()
                state.markBallTapped(id: node.ballId)

                if state.allMatchesTapped {
                    AudioManager.shared.playSuccess()
                    self.handleRoundSuccess()
                }
            }
        } else {
            // Wrong tap — explode red, handle failure synchronously
            node.tapWrong()
            handleRoundFailure()
            Task { @MainActor in
                AudioManager.shared.playWrongTap()
                state.markBallTapped(id: node.ballId)
            }
        }
    }

    // MARK: - Round Results

    private func handleRoundSuccess() {
        guard let state = gameState else { return }
        guard localPhase == .playing else { return } // prevent double-fire

        timerActive = false
        localPhase = .success

        // Celebrate matching balls
        for node in ballNodes where node.isMatch {
            node.celebrateMatch()
        }

        Task { @MainActor in
            state.phase = .success
            state.combo += 1
            state.consecutivePerfect += 1
            state.bestCombo = max(state.bestCombo, state.combo)
            state.roundsSurvived += 1

            let points = ScoreEngine.pointsForRound(combo: state.combo)
            state.score += points

            if ScoreEngine.shouldAwardBonusLife(consecutivePerfect: state.consecutivePerfect) {
                state.lives += 1
            }

            state.ballCount = DifficultyEngine.ballCount(forScore: state.score)
            state.flashColor = .success

            // Combo sound for streaks
            if state.combo > 1 {
                AudioManager.shared.playCombo()
            }
        }

        let nextAction = SKAction.sequence([
            SKAction.wait(forDuration: 0.4),
            SKAction.run { [weak self] in
                self?.startNextRound()
            }
        ])
        run(nextAction, withKey: "nextRound")
    }

    private func handleRoundFailure() {
        guard let state = gameState else { return }
        guard localPhase == .playing else { return } // only fire once

        timerActive = false
        localPhase = .failure
        removeAction(forKey: "nextRound")

        Task { @MainActor in
            state.phase = .failure
            state.combo = 0
            state.consecutivePerfect = 0
            state.lives -= 1
            state.flashColor = .failure
            AudioManager.shared.playLifeLost()

            let livesLeft = state.lives
            let delay: TimeInterval = livesLeft <= 0 ? 1.8 : 1.5

            try? await Task.sleep(for: .seconds(delay))

            // Check we're still in failure phase (user might have restarted)
            guard state.phase == .failure else { return }

            if livesLeft <= 0 {
                self.clearBalls {
                    Task { @MainActor in
                        state.phase = .gameOver
                    }
                }
            } else {
                self.startNextRound()
            }
        }
    }

    private func handleTimeout() {
        Task { @MainActor in
            AudioManager.shared.playError()
        }
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

    // MARK: - Cleanup

    func stopGame() {
        removeAction(forKey: "countdown")
        removeAction(forKey: "nextRound")
        timerActive = false
        localPhase = .idle
        clearBallsImmediate()
    }
}
