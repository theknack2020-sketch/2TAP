import SwiftUI
import SpriteKit

/// SwiftUI wrapper for the SpriteKit game scene.
struct GameView: View {
    var onHome: (() -> Void)?
    @Environment(SettingsManager.self) private var settings
    @State var gameState = GameState()
    @State private var gameScene: GameScene?
    @State private var showFlash = false
    @State private var flashOpacity: Double = 0

    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()

            // SpriteKit Game Scene
            if let gameScene {
                SpriteView(
                    scene: gameScene,
                    options: [.allowsTransparency]
                )
                .ignoresSafeArea()
            }

            // Frame flash overlay
            if gameState.flashColor != .none {
                frameFlashOverlay
            }

            // HUD Overlays
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                // Timer bar
                TimerBarView(progress: gameState.timerProgress)
                    .padding(.horizontal, 20)
                    .opacity(gameState.phase == .playing ? 1 : 0)

                // Score / Combo / Pause / Lives row
                HStack(spacing: 0) {
                    // Score on left
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.yellow)
                        Text("\(gameState.score)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                    }

                    // Combo badge
                    if gameState.combo > 1 {
                        Text("x\(gameState.combo)")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(.orange.opacity(0.15))
                            )
                            .padding(.leading, 6)
                            .transition(.scale.combined(with: .opacity))
                    }

                    Spacer()

                    // Pause button (center-ish)
                    if gameState.phase == .playing && gameState.pausesRemaining > 0 {
                        Button {
                            gameScene?.togglePause()
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "pause.fill")
                                    .font(.system(size: 11))
                                Text("\(gameState.pausesRemaining)")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(.white.opacity(0.1))
                            )
                        }
                    }

                    Spacer()

                    // Lives on right (dynamic count)
                    HStack(spacing: 3) {
                        ForEach(0..<max(gameState.lives, 3), id: \.self) { index in
                            Image(systemName: index < gameState.lives ? "heart.fill" : "heart")
                                .foregroundStyle(index < gameState.lives ? .red : .gray.opacity(0.4))
                                .font(.system(size: 14))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 6)
                .opacity(isHUDVisible ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: gameState.combo)

                Spacer()
            }

            // Countdown overlay
            CountdownView(phase: gameState.phase)

            // Pause overlay
            if gameState.isPaused {
                pauseOverlay
            }

            // Game Over overlay
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
        .onChange(of: gameState.phase) { _, newPhase in
            if newPhase == .gameOver {
                settings.updateHighScore(
                    score: gameState.score,
                    bestCombo: gameState.bestCombo,
                    rounds: gameState.roundsSurvived
                )
            }
        }
    }

    // MARK: - Flash

    private func triggerFlash() {
        withAnimation(.easeIn(duration: 0.1)) {
            flashOpacity = 0.4
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.3)) {
                flashOpacity = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            gameState.flashColor = .none
        }
    }

    private var frameFlashOverlay: some View {
        let color: Color = gameState.flashColor == .success ? .green : .red

        return RoundedRectangle(cornerRadius: 0)
            .stroke(color, lineWidth: 8)
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
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("PAUSED")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Button {
                    gameScene?.togglePause()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Resume")
                    }
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.green.gradient)
                    )
                }
            }
        }
    }

    // MARK: - Game Over

    private var gameOverOverlay: some View {
        VStack(spacing: 20) {
            Text("GAME OVER")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(.red)

            VStack(spacing: 8) {
                Text("\(gameState.score)")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("POINTS")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .tracking(3)
            }

            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("x\(gameState.bestCombo)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                    Text("Best Combo")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }

                VStack(spacing: 2) {
                    Text("\(gameState.roundsSurvived)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.cyan)
                    Text("Rounds")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }

                VStack(spacing: 2) {
                    Text(DifficultyEngine.levelName(forScore: gameState.score))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.purple)
                    Text("Level")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(.top, 4)

            VStack(spacing: 12) {
                Button {
                    gameScene?.startGame()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Play Again")
                    }
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.orange.gradient)
                    )
                }

                if let onHome {
                    Button {
                        gameScene?.stopGame()
                        onHome()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "house.fill")
                            Text("Home")
                        }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .padding(36)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.black.opacity(0.9))
                .shadow(color: .red.opacity(0.2), radius: 20)
        )
    }
}

#Preview {
    GameView()
        .environment(SettingsManager.shared)
}
