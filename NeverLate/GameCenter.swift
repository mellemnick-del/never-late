import GameKit
import UIKit

/// Game Center sign-in, score submission, and the leaderboard sheet.
/// Everything here fails quietly when the player is not signed in.
@MainActor
enum GameCenter {
    /// Must match the leaderboard ID you create in App Store Connect.
    static let leaderboardID = "neverlate.highscore"

    static func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { viewController, _ in
            guard let viewController else { return }
            Task { @MainActor in
                topViewController()?.present(viewController, animated: true)
            }
        }
    }

    static var isSignedIn: Bool { GKLocalPlayer.local.isAuthenticated }

    static func submit(score: Int) {
        guard isSignedIn, score > 0 else { return }
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local,
                                  leaderboardIDs: [leaderboardID]) { _ in }
    }

    static func showLeaderboard() {
        guard isSignedIn else {
            authenticate()
            return
        }
        GKAccessPoint.shared.trigger(state: .leaderboards) {}
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var top = scene?.windows.first { $0.isKeyWindow }?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
