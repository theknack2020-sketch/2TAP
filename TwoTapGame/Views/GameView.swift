import SwiftUI
import SpriteKit

/// SwiftUI wrapper for the SpriteKit game scene.
///
/// Hosts the game scene via SpriteView and overlays SwiftUI HUD elements
/// (timer bar, countdown, pause button).
struct GameView: View {
    var onHome: (() -> Void)?
    @State var gameState = GameState()
    @State private var gameScene: GameScene?

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

            // HUD Overlays
            VStack(spacing: 0) {
                // Spacer to push bar below status bar / notch area
                Spacer()
                    .frame(height: 60)

                // Timer bar — with bubble effect
                TimerBarView(progress: gameState.timerProgress)
                    .padding(.horizontal, 20)
                    .opacity(gameState.phase == .playing ? 1 : 0)

                // Score (left) and Lives (right) — just below timer bar
                HStack {
                    // Score on left
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.yellow)
                        Text("\(gameState.score)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    // Round in center
                    Text("R\(gameState.roundNumber)")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))

                    Spacer()

                    // Lives on right
                    HStack(spacing: 3) {
                        ForEach(0..<3, id: \.self) { index in
                            Image(systemName: index < gameState.lives ? "heart.fill" : "heart")
                                .foregroundStyle(index < gameState.lives ? .red : .gray.opacity(0.4))
                                .font(.system(size: 14))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 6)
                .opacity(isHUDVisible ? 1 : 0)

                Spacer()
            }

            // Countdown overlay
            CountdownView(phase: gameState.phase)

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
                gameScene?.startGame()
            }
        }
        .onDisappear {
            gameScene?.stopGame()
        }
    }

    private var isHUDVisible: Bool {
        switch gameState.phase {
        case .playing, .success, .failure, .countdown:
            return true
        default:
            return false
        }
    }

    private var gameOverOverlay: some View {
        VStack(spacing: 20) {
            Text("GAME OVER")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(.red)

            VStack(spacing: 8) {
                Text("Score: \(gameState.score)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Best Combo: x\(gameState.bestCombo)")
                    .font(.system(size: 18, design: .rounded))
                    .foregroundStyle(.orange)

                Text("Rounds Survived: \(gameState.roundsSurvived)")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }

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
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.black.opacity(0.85))
        )
    }
}

#Preview {
    GameView()
}
