import Foundation
import WatchConnectivity

final class PhoneSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = PhoneSessionManager()

    @Published var scoreA: Int = 0
    @Published var scoreB: Int = 0
    @Published var gameA: Int = 0
    @Published var gameB: Int = 0
    @Published var servingTeamIsA: Bool = true
    @Published var court: String = "右区"
    @Published var teamAName: String = "我方"
    @Published var teamBName: String = "对手"
    @Published var gameIndex: Int = 0
    @Published var totalGames: Int = 3
    @Published var isMatchOver: Bool = false
    @Published var isGameOver: Bool = false
    @Published var isConnected: Bool = false
    @Published var winningScore: Int = 21

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

    // MARK: - WCSessionDelegate (iOS required)

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("[PhoneSession] Activation failed: \(error.localizedDescription)")
        } else {
            print("[PhoneSession] Activated: \(activationState.rawValue)")
            DispatchQueue.main.async {
                self.isConnected = session.isReachable
            }
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("[PhoneSession] Session became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("[PhoneSession] Session deactivated")
        // Re-activate for switching watches
        WCSession.default.activate()
    }

    // MARK: - Reachability

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isConnected = session.isReachable
        }
    }

    // MARK: - Receive Message (real-time)

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        updateFromPayload(message)
    }

    // MARK: - Receive UserInfo (background fallback)

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        updateFromPayload(userInfo)
    }

    // MARK: - Update Published Properties

    private func updateFromPayload(_ payload: [String: Any]) {
        DispatchQueue.main.async {
            self.scoreA = payload["scoreA"] as? Int ?? self.scoreA
            self.scoreB = payload["scoreB"] as? Int ?? self.scoreB
            self.gameA = payload["gameA"] as? Int ?? self.gameA
            self.gameB = payload["gameB"] as? Int ?? self.gameB
            self.servingTeamIsA = payload["servingTeamIsA"] as? Bool ?? self.servingTeamIsA
            self.court = payload["court"] as? String ?? self.court
            self.teamAName = payload["teamAName"] as? String ?? self.teamAName
            self.teamBName = payload["teamBName"] as? String ?? self.teamBName
            self.gameIndex = payload["gameIndex"] as? Int ?? self.gameIndex
            self.totalGames = payload["totalGames"] as? Int ?? self.totalGames
            self.isMatchOver = payload["isMatchOver"] as? Bool ?? self.isMatchOver
            self.isGameOver = payload["isGameOver"] as? Bool ?? self.isGameOver
            self.winningScore = payload["winningScore"] as? Int ?? self.winningScore
            self.isConnected = true
        }
    }
}
