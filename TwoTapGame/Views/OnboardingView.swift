import SwiftUI

/// First-launch onboarding — 3 slides explaining the game.
struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0

    private let pages: [(icon: String, title: String, subtitle: String, color: Color)] = [
        ("circle.hexagongrid.fill", "Find the Match", "3 balls share the same color.\nFind and tap all of them!", .orange),
        ("timer", "2 Seconds", "You have exactly 2 seconds.\nEvery round. No exceptions.", .cyan),
        ("flame.fill", "Build Combos", "Chain perfect rounds for\nmassive score multipliers!", .yellow),
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        VStack(spacing: 24) {
                            Image(systemName: pages[index].icon)
                                .font(.system(size: 64))
                                .foregroundStyle(pages[index].color)
                                .shadow(color: pages[index].color.opacity(0.4), radius: 16)

                            Text(pages[index].title)
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundStyle(.white)

                            Text(pages[index].subtitle)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                Spacer()

                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? pages[currentPage].color : .white.opacity(0.2))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.bottom, 24)

                // Button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                        onComplete()
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Next" : "Let's Go!")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(pages[currentPage].color.gradient)
                        )
                }
                .padding(.horizontal, 40)

                // Skip
                if currentPage < pages.count - 1 {
                    Button {
                        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                        onComplete()
                    } label: {
                        Text("Skip")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.3))
                            .padding(.vertical, 12)
                    }
                } else {
                    Spacer().frame(height: 40)
                }

                Spacer().frame(height: 20)
            }
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
