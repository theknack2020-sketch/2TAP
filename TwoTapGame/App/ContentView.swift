import SwiftUI

struct ContentView: View {
    @Environment(SettingsManager.self) private var settings
    @State private var showGame = false
    @State private var showSettings = false
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    @State private var selectedDifficulty: DifficultyMode = .normal

    var body: some View {
        ZStack {
            if showOnboarding {
                OnboardingView(onComplete: {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showOnboarding = false
                    }
                })
                .transition(.opacity)
            } else if showGame {
                GameView(
                    onHome: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showGame = false
                        }
                    },
                    difficultyMode: selectedDifficulty
                )
                .ignoresSafeArea()
                .transition(.opacity)
            } else {
                MainMenuView(
                    onPlay: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showGame = true
                        }
                    },
                    onSettings: {
                        showSettings = true
                    },
                    selectedDifficulty: $selectedDifficulty
                )
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(onDismiss: {
                showSettings = false
            })
            .environment(settings)
        }
    }
}

#Preview {
    ContentView()
        .environment(SettingsManager.shared)
}
