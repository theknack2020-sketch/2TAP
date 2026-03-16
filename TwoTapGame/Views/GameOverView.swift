import SwiftUI

/// Game over overlay — animated score card with stats, share, and navigation.
struct GameOverView: View {
    let gameState: GameState
    let settings: SettingsManager
    let gameOverScoreAnimated: Int
    let showNewBest: Bool
    let onPlayAgain: () -> Void
    let onShare: () -> Void
    let onHome: (() -> Void)?

    @State private var cardScale: CGFloat = 0.8
    @State private var cardOpacity: Double = 0

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Score card
                VStack(spacing: 20) {
                    // Header
                    Text("GAME OVER")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.35))
                        .tracking(6)

                    // Difficulty badge
                    HStack(spacing: 5) {
                        Text(gameState.difficultyMode.emoji)
                            .font(.system(size: 12))
                        Text(gameState.difficultyMode.displayName.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                            .tracking(2)
                    }

                    // Big animated score
                    VStack(spacing: 6) {
                        Text("\(gameOverScoreAnimated)")
                            .font(.system(size: 60, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())

                        if showNewBest {
                            HStack(spacing: 5) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 11))
                                Text("NEW BEST!")
                                    .font(.system(size: 13, weight: .black, design: .rounded))
                                    .tracking(2)
                            }
                            .foregroundStyle(.yellow)
                            .shadow(color: .yellow.opacity(0.4), radius: 8)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }

                    // Stats grid
                    HStack(spacing: 0) {
                        statBadge(
                            icon: "flame.fill",
                            value: "x\(gameState.bestCombo)",
                            label: "Combo",
                            color: .orange
                        )
                        statDivider
                        statBadge(
                            icon: "circle.hexagongrid",
                            value: "\(gameState.roundsSurvived)",
                            label: "Rounds",
                            color: .cyan
                        )
                        statDivider
                        statBadge(
                            icon: "bolt.fill",
                            value: DifficultyEngine.levelName(forScore: gameState.score),
                            label: "Level",
                            color: .purple
                        )
                    }
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.white.opacity(0.04))
                    )

                    // Streak
                    if settings.currentStreak > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                                .font(.system(size: 13))
                            Text("\(settings.currentStreak) day streak")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.45))
                        }
                    }

                    // Buttons
                    VStack(spacing: 10) {
                        Button(action: onPlayAgain) {
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

                        // Share button
                        Button(action: onShare) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 13))
                                Text("Share Score")
                            }
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.white.opacity(0.06))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                        }

                        // Leaderboard button
                        if GameCenterManager.shared.isAuthenticated {
                            Button {
                                GameCenterManager.shared.showLeaderboard()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "trophy.fill")
                                        .font(.system(size: 13))
                                    Text("Leaderboard")
                                }
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(.yellow.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(.yellow.opacity(0.06))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(.yellow.opacity(0.1), lineWidth: 1)
                                        )
                                )
                            }
                        }

                        if let onHome {
                            Button {
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
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(28)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(.white.opacity(0.08), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.4), radius: 30, y: 10)
                )
                .scaleEffect(cardScale)
                .opacity(cardOpacity)
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .transition(.opacity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                cardScale = 1.0
                cardOpacity = 1.0
            }
        }
    }

    private var statDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.08))
            .frame(width: 1, height: 30)
    }

    private func statBadge(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(color.opacity(0.6))
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
    }
}
