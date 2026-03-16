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

    /// Stored reference to the failure-handling task for cancellation.
    private var failureTask: Task<Void, Never>?

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
        physicsWorld.gravity = .zero
        setupWalls()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        // Rebuild walls whenever scene size changes (rotation, initial layout)
        if size.width > 0 && size.height > 0 {
            setupWalls()
        }
    }

    /// Create wall boundaries so balls bounce off screen edges.
    /// Walls are inset by the max ball radius so balls never visually clip.
    private func setupWalls() {
        childNode(withName: "walls")?.removeFromParent()

        // Inset walls by max possible ball radius so the ball's visual edge
        // never extends past the screen. Max radius is 38pt (BallPlacementEngine).
        let wallInset: CGFloat = 40

        // In SpriteKit coords (y=0 at bottom), the ceiling sits below HUD.
        let ceilingY = size.height - hudTopInset

        let walls = SKNode()
        walls.name = "walls"

        let bottom = SKPhysicsBody(edgeFrom: CGPoint(x: wallInset, y: wallInset),
                                        to: CGPoint(x: size.width - wallInset, y: wallInset))
        let left   = SKPhysicsBody(edgeFrom: CGPoint(x: wallInset, y: wallInset),
                                        to: CGPoint(x: wallInset, y: ceilingY))
        let right  = SKPhysicsBody(edgeFrom: CGPoint(x: size.width - wallInset, y: wallInset),
                                        to: CGPoint(x: size.width - wallInset, y: ceilingY))
        let top    = SKPhysicsBody(edgeFrom: CGPoint(x: wallInset, y: ceilingY),
                                        to: CGPoint(x: size.width - wallInset, y: ceilingY))

        let compound = SKPhysicsBody(bodies: [bottom, left, right, top])
        compound.friction = 0
        compound.restitution = 1.0
        compound.categoryBitMask = 0x2
        compound.collisionBitMask = 0x1

        walls.physicsBody = compound
        addChild(walls)
    }

    // MARK: - Round Management

    /// Whether to skip countdown on next startGame call (quick restart from game over).
    var skipCountdown: Bool = false

    /// Start a new game from the beginning.
    func startGame() {
        guard let state = gameState else { return }

        // Cancel any pending actions
        failureTask?.cancel()
        failureTask = nil
        removeAction(forKey: "countdown")
        removeAction(forKey: "nextRound")
        timerActive = false
        localPhase = .idle

        // Clear any leftover balls
        clearBallsImmediate()

        Task { @MainActor in
            state.reset()
        }

        if skipCountdown {
            skipCountdown = false
            // Quick restart — skip countdown, jump straight to playing
            Task { @MainActor in
                state.roundNumber = 1
                state.phase = .playing
            }
            localPhase = .playing
            spawnBalls()
            startTimer()
        } else {
            runCountdown(isFirstRound: true)
        }
    }

    /// Start the next round with 2-1 countdown between rounds.
    func startNextRound() {
        clearBalls { [weak self] in
            self?.runCountdown(isFirstRound: false)
        }
    }

    /// Spawn balls for the current round.
    /// Top zone reserved for HUD — shared between walls and ball placement.
    private let hudTopInset: CGFloat = 160

    private func spawnBalls() {
        guard let state = gameState else { return }
        let screenSize = size

        let ballRadius = BallPlacementEngine.recommendedBallRadius(
            for: screenSize,
            ballCount: state.ballCount,
            topInset: hudTopInset
        )

        guard let positions = BallPlacementEngine.generatePositions(
            count: state.ballCount,
            ballRadius: ballRadius,
            screenSize: screenSize,
            topInset: hudTopInset
        ) else {
            print("⚠️ Ball placement failed for \(state.ballCount) balls on \(screenSize)")
            return
        }

        let roundColors = ColorMatchEngine.generateRound(
            ballCount: state.ballCount,
            palette: state.palette
        )
        currentRoundColors = roundColors

        // Build color → shape index mapping for accessibility
        var colorShapeMap: [UIColor: Int] = [:]
        var nextShapeIndex = 0
        for color in roundColors.assignments {
            if colorShapeMap[color] == nil {
                colorShapeMap[color] = nextShapeIndex
                nextShapeIndex += 1
            }
        }

        // Check system accessibility setting
        let useShapes = UIAccessibility.shouldDifferentiateWithoutColor

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
            // Ball speed scales with difficulty
            switch state.difficultyMode {
            case .easy:   node.speedMultiplier = 0.6
            case .normal: node.speedMultiplier = 1.0
            case .insane: node.speedMultiplier = 1.6
            }

            // Color-blind shape overlay
            node.shapeIndex = colorShapeMap[color] ?? 0
            node.showAccessibilityShape = useShapes

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
            node.stopMoving()
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
            node.stopMoving()
            node.removeFromParent()
        }
        ballNodes.removeAll()
    }

    // MARK: - Countdown (2-1, not 3-2-1)

    private func runCountdown(isFirstRound: Bool) {
        guard let state = gameState else { return }

        let countdownSequence = SKAction.sequence([
            SKAction.run {
                Task { @MainActor in
                    state.phase = .countdown(number: 2)
                    HapticManager.shared.countdownTick()
                }
            },
            SKAction.wait(forDuration: 0.7),
            SKAction.run {
                Task { @MainActor in
                    state.phase = .countdown(number: 1)
                    HapticManager.shared.countdownTick()
                }
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
        // Always run ball repulsion while balls exist
        BallPhysicsEngine.applyRepulsion(
            balls: ballNodes,
            sceneSize: size,
            hudTopInset: hudTopInset,
            difficultyMode: gameState?.difficultyMode
        )

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

        // Empty space tap — no penalty (D001: only wrong-ball taps cost lives)
    }

    private func handleBallTap(_ node: BallNode) {
        guard let state = gameState else { return }
        guard localPhase == .playing else { return } // race guard

        if node.isMatch {
            node.tapCorrect()
            Task { @MainActor in
                HapticManager.shared.correctTap()
                AudioManager.shared.playCorrectTap()
                state.markBallTapped(id: node.ballId)

                if state.allMatchesTapped {
                    HapticManager.shared.success()
                    AudioManager.shared.playSuccess()
                    self.handleRoundSuccess()
                }
            }
        } else {
            node.tapWrong()
            handleRoundFailure()
            Task { @MainActor in
                HapticManager.shared.wrongTap()
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
                HapticManager.shared.combo()
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
        failureTask?.cancel()

        failureTask = Task { @MainActor in
            state.phase = .failure
            state.combo = 0
            state.consecutivePerfect = 0
            state.lives -= 1
            state.flashColor = .failure
            AudioManager.shared.playLifeLost()
            HapticManager.shared.lifeLost()

            let livesLeft = state.lives
            let delay: TimeInterval = livesLeft <= 0 ? 1.8 : 1.5

            try? await Task.sleep(for: .seconds(delay))

            // Bail if cancelled (user restarted) or phase changed
            guard !Task.isCancelled else { return }
            guard state.phase == .failure else { return }

            if livesLeft <= 0 {
                self.clearBalls {
                    Task { @MainActor in
                        guard !Task.isCancelled else { return }
                        state.phase = .gameOver
                        HapticManager.shared.gameOver()
                        AudioManager.shared.playGameOver()
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
        failureTask?.cancel()
        failureTask = nil
        removeAction(forKey: "countdown")
        removeAction(forKey: "nextRound")
        timerActive = false
        localPhase = .idle
        clearBallsImmediate()
    }
}
