import SwiftUI

/// Main menu screen — first thing the player sees.
/// Logo, game name, Play button, Settings button.
struct MainMenuView: View {
    let onPlay: () -> Void

    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var ballsVisible = false
    @State private var titleOffset: CGFloat = 30

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.15),
                    Color(red: 0.12, green: 0.05, blue: 0.20),
                    Color(red: 0.05, green: 0.05, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Floating decorative balls
            if ballsVisible {
                FloatingBallsBackground()
            }

            // Content
            VStack(spacing: 0) {
                Spacer()

                // Game Logo / Title
                HStack(spacing: 0) {
                    Text("2")
                        .font(.system(size: 100, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .orange.opacity(0.5), radius: 20)

                    Text("TAP")
                        .font(.system(size: 100, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .yellow.opacity(0.4), radius: 15)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                Text("Find the match. Beat the clock.")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.top, 8)
                    .offset(y: titleOffset)
                    .opacity(logoOpacity)

                Spacer()
                Spacer()

                // Play Button
                Button(action: onPlay) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.title2)
                        Text("PLAY")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 50)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .orange.opacity(0.4), radius: 12, y: 4)
                    )
                }
                .opacity(logoOpacity)

                // Settings button (placeholder — wired in S03)
                Button {
                    // Settings — implemented in S03
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.vertical, 12)
                }
                .padding(.top, 16)
                .opacity(logoOpacity)

                Spacer()
                    .frame(height: 60)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                logoScale = 1.0
                logoOpacity = 1.0
                titleOffset = 0
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.3)) {
                ballsVisible = true
            }
        }
    }
}

/// Decorative floating balls in the background.
private struct FloatingBallsBackground: View {
    @State private var positions: [(CGFloat, CGFloat, Color, CGFloat)] = []

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<8, id: \.self) { i in
                if i < positions.count {
                    Circle()
                        .fill(positions[i].2.opacity(0.15))
                        .frame(width: positions[i].3, height: positions[i].3)
                        .position(x: positions[i].0, y: positions[i].1)
                        .blur(radius: 2)
                }
            }
        }
        .onAppear {
            let colors: [Color] = [.orange, .red, .yellow, .pink, .purple, .blue, .green, .cyan]
            positions = (0..<8).map { i in
                (
                    CGFloat.random(in: 30...360),
                    CGFloat.random(in: 100...750),
                    colors[i % colors.count],
                    CGFloat.random(in: 30...60)
                )
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    MainMenuView(onPlay: {})
}
