import SwiftUI

struct ContentView: View {
    @State private var showGame = false

    var body: some View {
        if showGame {
            GameView(onHome: {
                showGame = false
            })
            .ignoresSafeArea()
            .transition(.opacity)
        } else {
            MainMenuView(onPlay: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showGame = true
                }
            })
            .transition(.opacity)
        }
    }
}

#Preview {
    ContentView()
}
