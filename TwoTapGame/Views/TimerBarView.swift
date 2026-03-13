import SwiftUI

/// Visual countdown bar that drains from full to empty over 2 seconds.
///
/// Green when time is plenty, transitions to orange then red as time runs out.
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

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 6)
                    .fill(.white.opacity(0.15))

                // Filled portion
                RoundedRectangle(cornerRadius: 6)
                    .fill(barColor.gradient)
                    .frame(width: max(0, geometry.size.width * progress))
                    .animation(.linear(duration: 0.05), value: progress)
            }
        }
        .frame(height: 10)
    }
}

#Preview {
    VStack(spacing: 20) {
        TimerBarView(progress: 1.0)
        TimerBarView(progress: 0.7)
        TimerBarView(progress: 0.4)
        TimerBarView(progress: 0.15)
        TimerBarView(progress: 0.0)
    }
    .padding()
    .background(Color.black)
}
