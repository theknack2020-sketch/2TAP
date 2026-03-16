import SwiftUI

/// Main menu — premium game feel with animated floating orbs.
struct MainMenuView: View {
    let onPlay: () -> Void
    var onSettings: (() -> Void)?
    @Binding var selectedDifficulty: DifficultyMode

    @Environment(SettingsManager.self) private var settings

    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var buttonsVisible = false
    @State private var orbPhase: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Deep gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.04, blue: 0.12),
                    Color(red: 0.02, green: 0.02, blue: 0.08),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Animated ambient orbs
            ambientOrbs

            // Main content
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 80)

                // Animated logo
                logoSection
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                Spacer()
                    .frame(height: 24)

                // Title
                VStack(spacing: 6) {
                    Text("2TAP")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .orange.opacity(0.3), radius: 20, y: 4)

                    Text("FIND • TAP • 2 SECONDS")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.35))
                        .tracking(4)
                }
                .offset(y: titleOffset)
                .opacity(logoOpacity)

                Spacer()

                // Stats badges — show per-difficulty best
                if settings.highScore > 0 || settings.currentStreak > 0 {
                    HStack(spacing: 16) {
                        // Per-difficulty high score
                        let diffScore = settings.highScore(for: selectedDifficulty)
                        if diffScore > 0 {
                            HStack(spacing: 6) {
                                Image(systemName: "trophy.fill")
                                    .foregroundStyle(.yellow.opacity(0.8))
                                    .font(.system(size: 14))
                                Text("\(diffScore)")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.6))
                                    .contentTransition(.numericText())
                            }
                        }

                        if settings.currentStreak > 0 {
                            HStack(spacing: 6) {
                                Image(systemName: "flame.fill")
                                    .foregroundStyle(.orange.opacity(0.8))
                                    .font(.system(size: 14))
                                Text("\(settings.currentStreak) day\(settings.currentStreak == 1 ? "" : "s")")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.06))
                            .overlay(
                                Capsule().stroke(.white.opacity(0.08), lineWidth: 1)
                            )
                    )
                    .opacity(buttonsVisible ? 1 : 0)
                    .offset(y: buttonsVisible ? 0 : 15)
                    .padding(.bottom, 20)
                    .animation(.easeInOut(duration: 0.2), value: selectedDifficulty)
                }

                // Difficulty selector
                HStack(spacing: 0) {
                    ForEach(DifficultyMode.allCases) { mode in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedDifficulty = mode
                            }
                        } label: {
                            VStack(spacing: 3) {
                                Text(mode.emoji)
                                    .font(.system(size: 16))
                                Text(mode.displayName)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(selectedDifficulty == mode ? .white : .white.opacity(0.35))
                                Text("\(String(format: "%.1f", mode.timerDuration))s")
                                    .font(.system(size: 9, weight: .medium, design: .rounded))
                                    .foregroundStyle(selectedDifficulty == mode ? .white.opacity(0.6) : .white.opacity(0.2))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedDifficulty == mode ? .white.opacity(0.1) : .clear)
                            )
                        }
                        .accessibilityIdentifier("difficulty_\(mode.rawValue)")
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 12)
                .opacity(buttonsVisible ? 1 : 0)

                // Play button — big, bold, central
                Button(action: onPlay) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 22))
                        Text("PLAY")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .tracking(2)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.55, blue: 0.1),
                                        Color(red: 0.95, green: 0.35, blue: 0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .orange.opacity(0.35), radius: 16, y: 6)
                    )
                    .scaleEffect(pulseScale)
                }
                .padding(.horizontal, 40)
                .opacity(buttonsVisible ? 1 : 0)
                .offset(y: buttonsVisible ? 0 : 20)
                .accessibilityIdentifier("playButton")

                // Secondary buttons
                HStack(spacing: 24) {
                    // Settings
                    Button {
                        onSettings?()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 18))
                            Text("Settings")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(.white.opacity(0.35))
                        .frame(width: 70)
                    }
                    .accessibilityIdentifier("settingsButton")

                    // Leaderboard
                    if GameCenterManager.shared.isAuthenticated {
                        Button {
                            GameCenterManager.shared.showLeaderboard()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 18))
                                Text("Ranks")
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                            }
                            .foregroundStyle(.yellow.opacity(0.5))
                            .frame(width: 70)
                        }
                    }
                }
                .opacity(buttonsVisible ? 1 : 0)
                .padding(.top, 10)

                Spacer()
                    .frame(height: 60)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.65).delay(0.1)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                titleOffset = 0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                buttonsVisible = true
            }
            // Subtle pulse on play button
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(1)) {
                pulseScale = 1.03
            }
        }
    }

    // MARK: - Logo (Two metallic orbs)

    private var logoSection: some View {
        ZStack {
            // Glow behind
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.orange.opacity(0.15), .clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)

            // Orange ball
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 1.0, green: 0.75, blue: 0.3),
                            Color(red: 0.95, green: 0.55, blue: 0.1),
                            Color(red: 0.7, green: 0.35, blue: 0.05)
                        ],
                        center: UnitPoint(x: 0.35, y: 0.3),
                        startRadius: 5,
                        endRadius: 50
                    )
                )
                .frame(width: 72, height: 72)
                .overlay(
                    Ellipse()
                        .fill(.white.opacity(0.45))
                        .frame(width: 24, height: 14)
                        .offset(x: -10, y: -16)
                        .rotationEffect(.degrees(-15))
                )
                .shadow(color: .orange.opacity(0.4), radius: 12, y: 4)
                .offset(x: -22, y: 8)

            // Blue ball
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.5, green: 0.8, blue: 1.0),
                            Color(red: 0.2, green: 0.55, blue: 0.95),
                            Color(red: 0.1, green: 0.3, blue: 0.7)
                        ],
                        center: UnitPoint(x: 0.35, y: 0.3),
                        startRadius: 5,
                        endRadius: 45
                    )
                )
                .frame(width: 62, height: 62)
                .overlay(
                    Ellipse()
                        .fill(.white.opacity(0.45))
                        .frame(width: 20, height: 12)
                        .offset(x: -8, y: -14)
                        .rotationEffect(.degrees(-15))
                )
                .shadow(color: .blue.opacity(0.4), radius: 12, y: 4)
                .offset(x: 22, y: -8)
        }
    }

    // MARK: - Ambient orbs

    private var ambientOrbs: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                // Soft floating orbs
                let orbs: [(x: CGFloat, y: CGFloat, r: CGFloat, color: Color, speed: Double)] = [
                    (0.15, 0.2, 80, .orange.opacity(0.04), 0.4),
                    (0.85, 0.35, 100, .blue.opacity(0.03), 0.3),
                    (0.5, 0.75, 60, .purple.opacity(0.03), 0.5),
                    (0.2, 0.85, 70, .cyan.opacity(0.02), 0.35),
                ]

                for orb in orbs {
                    let offsetX = sin(t * orb.speed) * 20
                    let offsetY = cos(t * orb.speed * 0.7) * 15
                    let center = CGPoint(
                        x: size.width * orb.x + offsetX,
                        y: size.height * orb.y + offsetY
                    )

                    let gradient = Gradient(colors: [orb.color, .clear])
                    let shading = GraphicsContext.Shading.radialGradient(
                        gradient,
                        center: center,
                        startRadius: 0,
                        endRadius: orb.r
                    )

                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: center.x - orb.r,
                            y: center.y - orb.r,
                            width: orb.r * 2,
                            height: orb.r * 2
                        )),
                        with: shading
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    MainMenuView(onPlay: {}, selectedDifficulty: .constant(.normal))
        .environment(SettingsManager.shared)
}
