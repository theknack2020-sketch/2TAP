import SwiftUI

/// Premium timer bar with glass morphism and color transitions.
///
/// Green → Yellow → Orange → Red as time runs out.
/// Subtle glow effect and rounded ends.
struct TimerBarView: View {
    let progress: Double

    private var barColor: Color {
        switch progress {
        case 0.6...1.0:
            return Color(red: 0.2, green: 0.85, blue: 0.5)   // Green
        case 0.35..<0.6:
            return Color(red: 1.0, green: 0.8, blue: 0.2)     // Yellow
        case 0.15..<0.35:
            return Color(red: 1.0, green: 0.5, blue: 0.1)     // Orange
        default:
            return Color(red: 1.0, green: 0.2, blue: 0.2)     // Red
        }
    }

    private var glowColor: Color {
        barColor.opacity(0.5)
    }

    var body: some View {
        GeometryReader { geo in
            let barWidth = geo.size.width
            let barHeight: CGFloat = 8
            let fillWidth = barWidth * max(0, min(1, progress))

            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(.white.opacity(0.08))
                    .frame(height: barHeight)

                // Fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [barColor.opacity(0.9), barColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: fillWidth, height: barHeight)
                    .shadow(color: glowColor, radius: 8, y: 0)
                    .overlay(
                        // Glass highlight
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.4), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: barHeight * 0.4)
                            .offset(y: -barHeight * 0.15)
                            .clipShape(Capsule())
                    )

                // Danger pulse when low
                if progress < 0.25 && progress > 0 {
                    Capsule()
                        .fill(barColor.opacity(0.3))
                        .frame(width: fillWidth, height: barHeight)
                        .scaleEffect(x: 1, y: 1.8)
                        .blur(radius: 6)
                        .animation(
                            .easeInOut(duration: 0.3).repeatForever(autoreverses: true),
                            value: progress
                        )
                }
            }
        }
        .frame(height: 8)
        .animation(.linear(duration: 0.05), value: progress)
    }
}

#Preview {
    VStack(spacing: 20) {
        TimerBarView(progress: 1.0)
        TimerBarView(progress: 0.7)
        TimerBarView(progress: 0.4)
        TimerBarView(progress: 0.2)
        TimerBarView(progress: 0.05)
    }
    .padding()
    .background(Color.black)
}
