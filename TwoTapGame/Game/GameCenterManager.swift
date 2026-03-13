import GameKit

/// Handles Game Center authentication and leaderboard submission.
@MainActor
final class GameCenterManager {
    static let shared = GameCenterManager()

    /// Leaderboard IDs — must match App Store Connect configuration.
    static let highScoreLeaderboardID = "com.ufuk.twotapgame.highscore"

    private(set) var isAuthenticated = false

    private init() {}

    /// Silently check if the player is already signed into Game Center.
    /// Never shows a login prompt — if they're not signed in, we just skip it.
    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            // Do NOT present the viewController — we don't force login
            if viewController != nil {
                // Player is not signed in; that's fine, skip GameCenter features
                Task { @MainActor in
                    self?.isAuthenticated = false
                }
                return
            }

            if let error {
                print("⚠️ GameCenter: \(error.localizedDescription)")
                return
            }

            Task { @MainActor in
                self?.isAuthenticated = GKLocalPlayer.local.isAuthenticated
            }
        }
    }

    /// Submit a score to the leaderboard.
    func submitScore(_ score: Int) {
        guard isAuthenticated, score > 0 else { return }

        Task {
            do {
                try await GKLeaderboard.submitScore(
                    score,
                    context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: [Self.highScoreLeaderboardID]
                )
                print("✅ Score \(score) submitted to GameCenter")
            } catch {
                print("⚠️ GameCenter score submit failed: \(error.localizedDescription)")
            }
        }
    }

    /// Show the Game Center leaderboard UI.
    func showLeaderboard() {
        guard isAuthenticated else { return }

        let gcVC = GKGameCenterViewController(leaderboardID: Self.highScoreLeaderboardID,
                                               playerScope: .global,
                                               timeScope: .allTime)

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            gcVC.gameCenterDelegate = GameCenterDismissHandler.shared
            root.present(gcVC, animated: true)
        }
    }
}

/// Handles dismissal of GameCenter view controller.
final class GameCenterDismissHandler: NSObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterDismissHandler()

    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
