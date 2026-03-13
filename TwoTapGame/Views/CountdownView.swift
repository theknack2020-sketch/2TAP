import SwiftUI

/// Large countdown overlay showing 2, 1 before each round.
/// Uses 2-1 instead of 3-2-1 — matching the game's "2 seconds" identity.
struct CountdownView: View {
    let phase: RoundPhase

    private var countdownNumber: Int? {
        if case .countdown(let number) = phase {
            return number
        }
        return nil
    }

    var body: some View {
        ZStack {
            if let number = countdownNumber {
                Text("\(number)")
                    .font(.system(size: 140, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: number == 2
                                ? [.green, .mint]
                                : [.yellow, .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: number == 2 ? .green.opacity(0.6) : .orange.opacity(0.6), radius: 25)
                    .scaleEffect(1.0)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 2.0).combined(with: .opacity),
                        removal: .scale(scale: 0.5).combined(with: .opacity)
                    ))
                    .id(number)
            }
        }
        .animation(.easeOut(duration: 0.3), value: countdownNumber)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        CountdownView(phase: .countdown(number: 2))
    }
}
