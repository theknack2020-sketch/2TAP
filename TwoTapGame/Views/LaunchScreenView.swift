import SwiftUI

/// Branded launch screen — shown during app startup.
struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 12) {
                // Two overlapping circles (matches app icon)
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.orange, .orange.opacity(0.7)],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                        .frame(width: 60, height: 60)
                        .offset(x: -15, y: 5)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.blue, .blue.opacity(0.7)],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 36
                            )
                        )
                        .frame(width: 52, height: 52)
                        .offset(x: 15, y: -5)
                }

                Text("2TAP")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
