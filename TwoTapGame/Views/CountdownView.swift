import SwiftUI

/// Full-screen countdown overlay — dramatic 2→1 with scale + fade.
struct CountdownView: View {
    let phase: RoundPhase

    @State private var scale: CGFloat = 2.5
    @State private var opacity: Double = 0
    @State private var ringScale: CGFloat = 0.5

    private var countdownNumber: Int? {
        if case .countdown(let n) = phase { return n }
        return nil
    }

    var body: some View {
        if let number = countdownNumber {
            ZStack {
                // Expanding ring
                Circle()
                    .stroke(
                        number == 2 ? Color.orange.opacity(0.3) : Color.cyan.opacity(0.3),
                        lineWidth: 3
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(ringScale)
                    .opacity(opacity * 0.6)

                // Number
                Text("\(number)")
                    .font(.system(size: 88, weight: .black, design: .rounded))
                    .foregroundStyle(
                        number == 2
                            ? LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .top, endPoint: .bottom
                              )
                            : LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .top, endPoint: .bottom
                              )
                    )
                    .shadow(
                        color: (number == 2 ? Color.orange : Color.cyan).opacity(0.5),
                        radius: 20
                    )
                    .scaleEffect(scale)
                    .opacity(opacity)
            }
            .onChange(of: number) { _, _ in
                animateIn()
            }
            .onAppear {
                animateIn()
            }
        }
    }

    private func animateIn() {
        scale = 2.5
        opacity = 0
        ringScale = 0.5

        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            scale = 1.0
            opacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.6)) {
            ringScale = 1.5
        }

        // Fade out
        withAnimation(.easeIn(duration: 0.15).delay(0.45)) {
            opacity = 0
            scale = 0.8
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        CountdownView(phase: .countdown(number: 2))
    }
}
