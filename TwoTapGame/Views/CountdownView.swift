import SwiftUI

/// Large countdown overlay showing 3, 2, 1 before the game starts.
struct CountdownView: View {
    let phase: RoundPhase

    private var countdownNumber: Int? {
        if case .countdown(let number) = phase {
            return number
        }
        return nil
    }

    var body: some View {
        if let number = countdownNumber {
            Text("\(number)")
                .font(.system(size: 120, weight: .black, design: .rounded))
                .foregroundStyle(.green)
                .shadow(color: .green.opacity(0.5), radius: 20)
                .transition(.scale.combined(with: .opacity))
                .id(number) // Force new view for animation
                .animation(.easeOut(duration: 0.3), value: number)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        CountdownView(phase: .countdown(number: 2))
    }
}
