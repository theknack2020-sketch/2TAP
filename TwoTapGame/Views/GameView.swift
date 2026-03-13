import SwiftUI
import SpriteKit

/// SwiftUI wrapper for the SpriteKit game scene.
///
/// Hosts the game scene via SpriteView and overlays SwiftUI HUD elements
/// (timer bar, countdown, pause button).
struct GameView: View {
    @State var gameState = GameState()

    private var scene: GameScene {
        let scene = GameScene()
        scene.size = UIScreen.main.bounds.size
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        scene.gameState = gameState
        return scene
    }

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
            VStack {
                // Timer bar at top
                TimerBarView(progress: gameState.timerProgress)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .opacity(gameState.phase == .playing ? 1 : 0)

                Spacer()

                // Score display at bottom
                HStack {
                    Text("Score: \(gameState.score)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Spacer()

                    // Lives
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { index in
                            Image(systemName: index < gameState.lives ? "heart.fill" : "heart")
                                .foregroundStyle(index < gameState.lives ? .red : .gray)
                                .font(.system(size: 16))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                .opacity(gameState.phase == .playing || gameState.phase == .success || gameState.phase == .failure ? 1 : 0)
            }

            // Countdown overlay
            CountdownView(phase: gameState.phase)

            // Game Over overlay (basic — refined in S04)
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

            // Start the game after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                gameScene?.startGame()
            }
        }
    }

    private var gameOverOverlay: some View {
        VStack(spacing: 20) {
            Text("GAME OVER")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(.red)

            Text("Score: \(gameState.score)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Rounds: \(gameState.roundsSurvived)")
                .font(.system(size: 18, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))

            Button {
                gameState.reset()
                gameScene?.startGame()
            } label: {
                Text("Play Again")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.orange.gradient)
                    )
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
