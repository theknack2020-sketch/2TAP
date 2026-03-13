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
    @State private var gamesPlayed: Int = 0
    @State private var comboPopupText: String = ""
    @State private var showComboPopup = false
    @State private var scorePopupText: String = ""
    @State private var showScorePopup = false
    @State private var scorePopupOffset: CGFloat = 0

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
            }

            // Frame flash
            if gameState.flashColor != .none {
                frameFlashOverlay
            }

            // HUD
            VStack(spacing: 0) {
                Spacer().frame(height: 58)

                // Timer bar
                TimerBarView(progress: gameState.timerProgress)
                    .padding(.horizontal, 20)
                    .opacity(gameState.phase == .playing ? 1 : 0)

                // HUD row
                hudRow
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .opacity(isHUDVisible ? 1 : 0)

                // Target color indicator
                if gameState.phase == .playing, let matchColor = gameState.matchingColor {
                    HStack(spacing: 8) {
                        Text("FIND")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                            .tracking(2)

                        Circle()
                            .fill(Color(matchColor))
                            .frame(width: 22, height: 22)
                            .overlay(
                                Circle().stroke(.white.opacity(0.3), lineWidth: 1.5)
                            )
                            .shadow(color: Color(matchColor).opacity(0.5), radius: 6)

                        Text("×\(gameState.matchCount - gameState.tappedMatchCount)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(.white.opacity(0.06))
                    )
                    .padding(.top, 6)
                    .transition(.opacity)
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
            }

            // Game Over
            if gameState.phase == .gameOver {
                gameOverOverlay
            }
        }
        .onAppear {
            let newScene = GameScene()
            newScene.size = UIScreen.main.bounds.size
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
                settings.updateHighScore(
                    score: gameState.score,
                    bestCombo: gameState.bestCombo,
                    rounds: gameState.roundsSurvived
                )
                settings.recordGamePlayed()
                gamesPlayed += 1
                if gamesPlayed == 5 && gameState.score >= 500 {
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.2)) {
                showScorePopup = false
            }
        }
    }

    // MARK: - Combo Popup

    private func showCombo(_ combo: Int) {
        comboPopupText = "x\(combo) COMBO!"
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            showComboPopup = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.2)) {
                showComboPopup = false
            }
        }
    }

    // MARK: - Flash

    private func triggerFlash() {
        withAnimation(.easeIn(duration: 0.08)) {
            flashOpacity = 0.5
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeOut(duration: 0.25)) {
                flashOpacity = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
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
            }
        }
    }

    // MARK: - Game Over

    private var gameOverOverlay: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.75)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Score card
                VStack(spacing: 20) {
                    Text("GAME OVER")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                        .tracking(6)

                    // Big score
                    VStack(spacing: 4) {
                        Text("\(gameState.score)")
                            .font(.system(size: 56, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())

                        if gameState.score >= settings.highScore && gameState.score > 0 {
                            Text("NEW BEST!")
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundStyle(.yellow)
                                .tracking(2)
                        }
                    }

                    // Stats row
                    HStack(spacing: 28) {
                        statBadge(
                            value: "x\(gameState.bestCombo)",
                            label: "Best Combo",
                            color: .orange
                        )
                        statBadge(
                            value: "\(gameState.roundsSurvived)",
                            label: "Rounds",
                            color: .cyan
                        )
                        statBadge(
                            value: DifficultyEngine.levelName(forScore: gameState.score),
                            label: "Level",
                            color: .purple
                        )
                    }

                    // Buttons
                    VStack(spacing: 12) {
                        Button {
                            gameScene?.startGame()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Play Again")
                            }
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [.orange, .orange.opacity(0.8)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                        }

                        if let onHome {
                            Button {
                                gameScene?.stopGame()
                                onHome()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "house.fill")
                                        .font(.system(size: 13))
                                    Text("Home")
                                }
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                                .padding(.vertical, 10)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 28)

                Spacer()
            }
        }
        .transition(.opacity)
    }

    private func statBadge(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
        }
    }
}

#Preview {
    GameView()
        .environment(SettingsManager.shared)
}
