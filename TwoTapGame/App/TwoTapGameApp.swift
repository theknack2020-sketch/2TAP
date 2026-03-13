import SwiftUI

@main
struct TwoTapGameApp: App {
    @State private var settings = SettingsManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(settings)
                .preferredColorScheme(settings.theme.colorScheme)
                .onAppear {
                    GameCenterManager.shared.authenticate()
                }
        }
    }
}
