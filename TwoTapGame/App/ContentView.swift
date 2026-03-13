import SwiftUI

struct ContentView: View {
    @Environment(SettingsManager.self) private var settings
    @State private var showGame = false
    @State private var showSettings = false

    var body: some View {
        ZStack {
            if showGame {
                GameView(onHome: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showGame = false
                    }
                })
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
                    }
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
