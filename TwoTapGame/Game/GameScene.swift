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
        setupWalls()
        physicsWorld.gravity = .zero
    }

    /// Create wall boundaries so balls bounce off screen edges.
    /// Inset slightly so balls don't clip the edge visually.
    private func setupWalls() {
        // Remove old walls if resized
        childNode(withName: "walls")?.removeFromParent()

        let inset: CGFloat = 4
        let rect = CGRect(
            x: inset, y: inset,
            width: size.width - inset * 2,
            height: size.height - inset * 2
        )
        let wallBody = SKPhysicsBody(edgeLoopFrom: rect)
        wallBody.friction = 0
        wallBody.restitution = 1.0
        wallBody.categoryBitMask = 0x2   // wall
        wallBody.collisionBitMask = 0x1  // collide with balls

        let wallNode = SKNode()
        wallNode.name = "walls"
        wallNode.physicsBody = wallBody
        addChild(wallNode)
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
        applyBallRepulsion()

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

    // MARK: - Ball Repulsion

    /// Two-layer separation: soft repulsion field + hard position correction.
    /// Balls never touch — they repel like same-pole magnets.
    private func applyBallRepulsion() {
        let activeBalls = ballNodes.filter { !$0.isTapped }
        guard activeBalls.count > 1 else { return }

        let buffer: CGFloat = 14  // minimum gap between ball edges

        for i in 0..<activeBalls.count {
            for j in (i + 1)..<activeBalls.count {
                let a = activeBalls[i]
                let b = activeBalls[j]

                let dx = b.position.x - a.position.x
                let dy = b.position.y - a.position.y
                let dist = sqrt(dx * dx + dy * dy)
                guard dist > 0.01 else { continue }

                let minDist = a.radius + b.radius + buffer
                let nx = dx / dist
                let ny = dy / dist

                if dist < minDist {
                    // HARD CORRECTION: push apart immediately so they never overlap
                    let overlap = (minDist - dist) * 0.55 // each ball moves half
                    a.position.x -= nx * overlap
                    a.position.y -= ny * overlap
                    b.position.x += nx * overlap
                    b.position.y += ny * overlap

                    // Deflect velocities apart (like a magnetic repulsion bounce)
                    guard let bodyA = a.physicsBody, let bodyB = b.physicsBody else { continue }

                    let relVx = bodyB.velocity.dx - bodyA.velocity.dx
                    let relVy = bodyB.velocity.dy - bodyA.velocity.dy
                    let relDotN = relVx * nx + relVy * ny

                    // Only separate if they're moving toward each other
                    if relDotN < 0 {
                        let impulse = relDotN * 1.1 // slight extra push
                        bodyA.velocity.dx += impulse * nx
                        bodyA.velocity.dy += impulse * ny
                        bodyB.velocity.dx -= impulse * nx
                        bodyB.velocity.dy -= impulse * ny
                    }
                }

                // SOFT FIELD: gentle push when within 2× buffer range
                let fieldDist = a.radius + b.radius + buffer * 2.5
                if dist < fieldDist {
                    let strength = (fieldDist - dist) / fieldDist // 0→1 as closer
                    let push = strength * strength * 120 // quadratic falloff
                    a.physicsBody?.applyForce(CGVector(dx: -nx * push, dy: -ny * push))
                    b.physicsBody?.applyForce(CGVector(dx:  nx * push, dy:  ny * push))
                }
            }
        }

        // Clamp max speed
        let maxSpeed: CGFloat = 55
        for ball in activeBalls {
            guard let body = ball.physicsBody else { continue }
            let speed = sqrt(body.velocity.dx * body.velocity.dx + body.velocity.dy * body.velocity.dy)
            if speed > maxSpeed {
                let scale = maxSpeed / speed
                body.velocity = CGVector(dx: body.velocity.dx * scale, dy: body.velocity.dy * scale)
            }
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

        // Tapped empty space — that's a miss
        handleRoundFailure()
        Task { @MainActor in
            HapticManager.shared.wrongTap()
            AudioManager.shared.playWrongTap()
        }
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

        Task { @MainActor in
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

            // Check we're still in failure phase (user might have restarted)
            guard state.phase == .failure else { return }

            if livesLeft <= 0 {
                self.clearBalls {
                    Task { @MainActor in
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
        removeAction(forKey: "countdown")
        removeAction(forKey: "nextRound")
        timerActive = false
        localPhase = .idle
        clearBallsImmediate()
    }
}
