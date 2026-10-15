import GameKit
import UIKit

/// Achievements. IDs must match the ones created in App Store Connect.
enum Achievement: String, CaseIterable {
    case firstPerfect = "neverlate.first_perfect"
    case reachReverse = "neverlate.reach_reverse"
    case reachDrift = "neverlate.reach_drift"
    case score25 = "neverlate.score_25"
    case score50 = "neverlate.score_50"
    case score100 = "neverlate.score_100"
    case perfectStreak5 = "neverlate.perfect_streak_5"
    case dailyStreak7 = "neverlate.daily_streak_7"

    var title: String {
        switch self {
        case .firstPerfect: "Dead Center"
        case .reachReverse: "Counter Clockwise"
        case .reachDrift: "Bezel Drift"
        case .score25: "Quarter Hour"
        case .score50: "Fifty Down"
        case .score100: "Centurion"
        case .perfectStreak5: "Chronometer"
        case .dailyStreak7: "Daily Wearer"
        }
    }

    var detail: String {
        switch self {
        case .firstPerfect: "Land a perfect hit."
        case .reachReverse: "Reach phase 2, Reverse."
        case .reachDrift: "Reach phase 3, Drift."
        case .score25: "Score 25 in one run."
        case .score50: "Score 50 in one run."
        case .score100: "Score 100 in one run."
        case .perfectStreak5: "Land 5 perfect hits in a row."
        case .dailyStreak7: "Play the Daily Challenge 7 days in a row."
        }
    }
}

/// Game Center sign-in, leaderboards and achievements.
/// Everything here fails quietly when the player is not signed in.
@MainActor
enum GameCenter {
    /// Must match the leaderboard IDs created in App Store Connect.
    static let classicLeaderboardID = "neverlate.highscore"
    static let dailyLeaderboardID = "neverlate.daily"   // recurring, resets every day

    static func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { viewController, _ in
            guard let viewController else { return }
            Task { @MainActor in
                topViewController()?.present(viewController, animated: true)
            }
        }
    }

    static var isSignedIn: Bool { GKLocalPlayer.local.isAuthenticated }

    static func submit(score: Int, daily: Bool) {
        guard isSignedIn, score > 0 else { return }
        let id = daily ? dailyLeaderboardID : classicLeaderboardID
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local,
                                  leaderboardIDs: [id]) { _ in }
    }

    /// Reports each achievement once per device; Game Center shows its own banner.
    static func unlock(_ achievement: Achievement) {
        let key = "ach." + achievement.rawValue
        guard isSignedIn, !UserDefaults.standard.bool(forKey: key) else { return }
        let report = GKAchievement(identifier: achievement.rawValue)
        report.percentComplete = 100
        report.showsCompletionBanner = true
        GKAchievement.report([report]) { error in
            if error == nil {
                Task { @MainActor in UserDefaults.standard.set(true, forKey: key) }
            }
        }
    }

    static func showLeaderboards() {
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
