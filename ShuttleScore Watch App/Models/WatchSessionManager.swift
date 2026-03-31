import Foundation
import WatchConnectivity

final class WatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = WatchSessionManager()

    private override init() {
        super.init()
    }

    // MARK: - Activate

    func activateSession() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    // MARK: - Send Match State

    func sendMatchState(match: MatchState) {
        guard WCSession.default.activationState == .activated else { return }

        let game = match.currentGame
        let payload: [String: Any] = [
            "scoreA": game.scoreA,
            "scoreB": game.scoreB,
            "gameA": match.gamesWonByA,
            "gameB": match.gamesWonByB,
            "servingTeamIsA": game.servingTeamIsA,
            "court": game.serviceCourt.label,
            "teamAName": match.teamAName,
            "teamBName": match.teamBName,
            "gameIndex": match.currentGameIndex,
            "totalGames": match.totalGames,
            "isMatchOver": match.isMatchOver,
            "isGameOver": game.isOver,
            "winningScore": match.winningScore
        ]

        // Real-time: sendMessage if reachable
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil) { error in
                print("[WatchSession] sendMessage failed: \(error.localizedDescription)")
                // Fallback to transferUserInfo
                WCSession.default.transferUserInfo(payload)
            }
        } else {
            // Background fallback
            WCSession.default.transferUserInfo(payload)
        }
    }

    // MARK: - WCSessionDelegate (watchOS)

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("[WatchSession] Activation failed: \(error.localizedDescription)")
        } else {
            print("[WatchSession] Activated: \(activationState.rawValue)")
        }
    }
}
