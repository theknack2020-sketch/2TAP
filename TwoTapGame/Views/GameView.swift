import SwiftUI
import SpriteKit
import StoreKit

/// Game screen — SpriteKit scene with premium SwiftUI HUD overlays.
struct GameView: View {
    var onHome: (() -> Void)?
    var difficultyMode: DifficultyMode = .normal
    @Environment(SettingsManager.self) private var settings
    @Environment(\.requestReview) private var requestReview
    @State var gameState = GameState()
    @State private var gameScene: GameScene?
    @State private var flashOpacity: Double = 0
    @State private var comboPopupText: String = ""
    @State private var showComboPopup = false
    @State private var scorePopupText: String = ""
    @State private var showScorePopup = false
    @State private var scorePopupOffset: CGFloat = 0
    @State private var gameOverScoreAnimated: Int = 0
    @State private var showNewBest = false

    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.03, blue: 0.10),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // SpriteKit Game Scene
            if let gameScene {
                SpriteView(scene: gameScene, options: [.allowsTransparency])
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
            }

            // Frame flash
            if gameState.flashColor != .none {
                frameFlashOverlay
            }

            // HUD — respects safe area for notch/Dynamic Island
            VStack(spacing: 0) {
                // Timer bar — stays visible during success for smooth transition
                TimerBarView(progress: gameState.timerProgress)
                    .padding(.horizontal, 20)
                    .opacity(gameState.phase == .playing || gameState.phase == .success ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: gameState.phase)

                // HUD row
                hudRow
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .opacity(isHUDVisible ? 1 : 0)

                // Target color indicator
                if gameState.phase == .playing, let matchColor = gameState.matchingColor {
                    HStack(spacing: 10) {
                        Text("FIND")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                            .tracking(2)

                        Circle()
                            .fill(Color(matchColor))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle().stroke(.white.opacity(0.35), lineWidth: 2)
                            )
                            .shadow(color: Color(matchColor).opacity(0.6), radius: 10)

                        Text("×\(gameState.matchCount - gameState.tappedMatchCount)")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(.white.opacity(0.08))
                    )
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .scale))
                }

                Spacer()

                // Score popup (flying points)
                if showScorePopup {
                    Text(scorePopupText)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                        .shadow(color: .yellow.opacity(0.4), radius: 8)
                        .offset(y: scorePopupOffset)
                        .transition(.opacity)
                }

                // Combo popup (center screen, briefly)
                if showComboPopup {
                    Text(comboPopupText)
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .orange.opacity(0.5), radius: 12)
                        .transition(.scale.combined(with: .opacity))
                }

                Spacer()
            }

            // Countdown
            CountdownView(phase: gameState.phase)

            // Pause overlay
            if gameState.isPaused {
                pauseOverlay
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("pauseOverlay")
            }

            // Game Over
            if gameState.phase == .gameOver {
                GameOverView(
                    gameState: gameState,
                    settings: settings,
                    gameOverScoreAnimated: gameOverScoreAnimated,
                    showNewBest: showNewBest,
                    onPlayAgain: {
                        gameScene?.skipCountdown = true
                        gameScene?.startGame()
                    },
                    onShare: { shareScore() },
                    onHome: onHome.map { home in
                        { gameScene?.stopGame(); home() }
                    }
                )
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear.onAppear {
                    let newScene = GameScene()
                    newScene.size = geo.size
                    newScene.scaleMode = .resizeFill
                    newScene.backgroundColor = .clear
                    newScene.gameState = gameState
                    gameScene = newScene

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        gameState.palette = settings.selectedPalette
                        gameState.difficultyMode = difficultyMode
                        gameScene?.startGame()
                    }
                }
            }
        )
        .onDisappear {
            gameScene?.stopGame()
        }
        .onChange(of: gameState.flashColor) { _, newValue in
            if newValue != .none {
                triggerFlash()
            }
        }
        .onChange(of: gameState.combo) { oldVal, newVal in
            if newVal > 1 {
                showCombo(newVal)
            }
        }
        .onChange(of: gameState.score) { oldVal, newVal in
            let diff = newVal - oldVal
            if diff > 0 {
                showScorePoints(diff)
            }
        }
        .onChange(of: gameState.phase) { _, newPhase in
            if newPhase == .gameOver {
                let isNewBest = gameState.score > settings.highScore(for: gameState.difficultyMode) && gameState.score > 0
                settings.updateHighScore(
                    score: gameState.score,
                    bestCombo: gameState.bestCombo,
                    rounds: gameState.roundsSurvived,
                    difficulty: gameState.difficultyMode
                )
                settings.recordGamePlayed()
                GameCenterManager.shared.submitScore(gameState.score, difficulty: gameState.difficultyMode)

                gameOverScoreAnimated = 0
                showNewBest = false

                // Count up score
                animateScoreCount(to: gameState.score)
                // New best badge with delay
                if isNewBest {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            showNewBest = true
                        }
                        HapticManager.shared.success()
                    }
                }

                // Request review after 5 total games with a decent score
                if settings.totalGamesPlayed == 5 && gameState.score >= 500 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        requestReview()
                    }
                }
            }
        }
    }

    // MARK: - HUD Row

    private var hudRow: some View {
        HStack(spacing: 0) {
            // Score
            HStack(spacing: 5) {
                Image(systemName: "star.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.yellow.opacity(0.8))
                Text("\(gameState.score)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .accessibilityIdentifier("scoreLabel")
            }

            // Combo badge
            if gameState.combo > 1 {
                Text("x\(gameState.combo)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(.orange.opacity(0.12))
                    )
                    .padding(.leading, 6)
                    .transition(.scale.combined(with: .opacity))
            }

            Spacer()

            // Pause
            if gameState.phase == .playing && gameState.pausesRemaining > 0 {
                Button {
                    gameScene?.togglePause()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 10))
                        Text("\(gameState.pausesRemaining)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(.white.opacity(0.08))
                    )
                }
                .accessibilityIdentifier("pauseButton")
            }

            Spacer()

            // Difficulty level
            Text(DifficultyEngine.levelName(forScore: gameState.score))
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.25))
                .padding(.trailing, 8)

            // Lives
            HStack(spacing: 4) {
                ForEach(0..<max(gameState.lives, 3), id: \.self) { index in
                    Image(systemName: index < gameState.lives ? "heart.fill" : "heart")
                        .foregroundStyle(index < gameState.lives ? .red : .white.opacity(0.15))
                        .font(.system(size: 13))
                }
            }
            .accessibilityIdentifier("livesDisplay")
        }
        .animation(.easeInOut(duration: 0.2), value: gameState.combo)
    }

    // MARK: - Score Popup

    private func showScorePoints(_ points: Int) {
        scorePopupText = "+\(points)"
        scorePopupOffset = 0
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showScorePopup = true
        }
        withAnimation(.easeOut(duration: 0.8)) {
            scorePopupOffset = -40
        }
        Task {
            try? await Task.sleep(for: .seconds(0.6))
            withAnimation(.easeOut(duration: 0.2)) {
                showScorePopup = false
            }
        }
    }

    // MARK: - Score Count-Up

    private func animateScoreCount(to target: Int) {
        guard target > 0 else {
            gameOverScoreAnimated = 0
            return
        }
        let steps = min(target, 30) // max 30 steps
        let perStep = max(target / steps, 1)
        let interval = 0.6 / Double(steps) // finish in ~0.6s

        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                gameOverScoreAnimated = min(perStep * i, target)
            }
        }
        // Ensure final value is exact
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            gameOverScoreAnimated = target
        }
    }

    // MARK: - Combo Popup

    private func showCombo(_ combo: Int) {
        comboPopupText = "x\(combo) COMBO!"
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            showComboPopup = true
        }
        Task {
            try? await Task.sleep(for: .seconds(0.6))
            withAnimation(.easeOut(duration: 0.2)) {
                showComboPopup = false
            }
        }
    }

    // MARK: - Share

    private func shareScore() {
        let text = "🎮 2TAP — I scored \(gameState.score) on \(gameState.difficultyMode.displayName) mode! Best combo: x\(gameState.bestCombo), survived \(gameState.roundsSurvived) rounds. Can you beat it?"

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }

        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)

        // iPad popover support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = root.view
            popover.sourceRect = CGRect(x: root.view.bounds.midX, y: root.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        root.present(activityVC, animated: true)
    }

    // MARK: - Flash

    private func triggerFlash() {
        withAnimation(.easeIn(duration: 0.08)) {
            flashOpacity = 0.5
        }
        Task {
            try? await Task.sleep(for: .seconds(0.12))
            withAnimation(.easeOut(duration: 0.25)) {
                flashOpacity = 0
            }
            try? await Task.sleep(for: .seconds(0.28))
            gameState.flashColor = .none
        }
    }

    private var frameFlashOverlay: some View {
        let color: Color = gameState.flashColor == .success ? .green : .red
        return RoundedRectangle(cornerRadius: 0)
            .stroke(color, lineWidth: 6)
            .ignoresSafeArea()
            .opacity(flashOpacity)
            .allowsHitTesting(false)
    }

    // MARK: - HUD visibility

    private var isHUDVisible: Bool {
        switch gameState.phase {
        case .playing, .success, .failure, .countdown:
            return true
        default:
            return false
        }
    }

    // MARK: - Pause Overlay

    private var pauseOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Pause icon
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white.opacity(0.6))

                Text("PAUSED")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .tracking(4)

                Button {
                    gameScene?.togglePause()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Resume")
                    }
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                }
                .accessibilityIdentifier("resumeButton")

                // Home button — exit to main menu
                if let onHome {
                    Button {
                        gameScene?.stopGame()
                        onHome()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 12))
                            Text("Home")
                        }
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.vertical, 8)
                    }
                    .accessibilityIdentifier("homeButton")
                    .padding(.top, 8)
                }
            }
        }
    }

}

#Preview {
    GameView()
        .environment(SettingsManager.shared)
}
