import SwiftUI

/// Visual countdown bar with bubble/particle effect inside.
/// Drains from full to empty over 2 seconds.
/// Green → orange → red as time runs out.
struct TimerBarView: View {
    let progress: Double // 1.0 = full, 0.0 = empty

    private var barColor: Color {
        if progress > 0.5 {
            return .green
        } else if progress > 0.25 {
            return .orange
        } else {
            return .red
        }
    }

    private var glowColor: Color {
        barColor.opacity(0.4)
    }

    var body: some View {
        GeometryReader { geometry in
            let barWidth = geometry.size.width
            let filledWidth = max(0, barWidth * progress)

            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 10)
                    .fill(.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )

                // Filled portion with gradient
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [
                                barColor,
                                barColor.opacity(0.8),
                                barColor
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: filledWidth)
                    .overlay(
                        // Bubbles inside the bar
                        BubblesOverlay(
                            barWidth: filledWidth,
                            barHeight: geometry.size.height,
                            color: .white
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    )
                    .overlay(
                        // Glossy highlight on top
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.35),
                                        .white.opacity(0.05),
                                        .clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: filledWidth)
                            .frame(height: geometry.size.height * 0.5)
                            .offset(y: -geometry.size.height * 0.15)
                    )
                    .animation(.linear(duration: 0.05), value: progress)

                // Glow at the edge
                if filledWidth > 4 {
                    Circle()
                        .fill(glowColor)
                        .frame(width: 20, height: 20)
                        .blur(radius: 8)
                        .offset(x: filledWidth - 10)
                        .animation(.linear(duration: 0.05), value: progress)
                }
            }
        }
        .frame(height: 18)
        .shadow(color: barColor.opacity(0.3), radius: 6, y: 2)
    }
}

/// Animated bubbles inside the timer bar.
private struct BubblesOverlay: View {
    let barWidth: CGFloat
    let barHeight: CGFloat
    let color: Color

    @State private var bubbles: [(CGFloat, CGFloat, CGFloat, Double)] = []
    @State private var animationOffset: CGFloat = 0

    var body: some View {
        Canvas { context, size in
            for bubble in bubbles {
                let x = bubble.0.truncatingRemainder(dividingBy: max(1, barWidth))
                let y = bubble.1 + sin(animationOffset + bubble.3) * 2
                let radius = bubble.2

                let rect = CGRect(
                    x: x - radius,
                    y: y - radius,
                    width: radius * 2,
                    height: radius * 2
                )

                context.opacity = 0.3
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(color)
                )
            }
        }
        .onAppear {
            // Generate random bubble positions
            bubbles = (0..<12).map { _ in
                (
                    CGFloat.random(in: 0...400),    // x
                    CGFloat.random(in: 2...barHeight - 2),  // y
                    CGFloat.random(in: 1.5...3.5),   // radius
                    Double.random(in: 0...6.28)      // phase
                )
            }

            // Animate bubbles floating
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                animationOffset = .pi * 2
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    VStack(spacing: 30) {
        TimerBarView(progress: 1.0)
        TimerBarView(progress: 0.7)
        TimerBarView(progress: 0.4)
        TimerBarView(progress: 0.15)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 40)
    .background(Color.black)
}
