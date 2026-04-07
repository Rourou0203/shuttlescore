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
    @Published var matchStatus: String = "idle"  // idle, playing, paused, ended, terminated

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
            // Handle special message types first
            if let type = payload["type"] as? String {
                switch type {
                case "matchHistory":
                    self.handleMatchHistory(payload)
                    return
                case "opponentList":
                    if let opponents = payload["opponents"] as? [String] {
                        PhoneOpponentStore.shared.mergeFromWatch(opponents)
                    }
                    return
                case "matchTerminated":
                    self.matchStatus = "terminated"
                    // Update names so UI can show who was playing
                    self.teamAName = payload["teamAName"] as? String ?? self.teamAName
                    self.teamBName = payload["teamBName"] as? String ?? self.teamBName
                    self.scoreA = payload["scoreA"] as? Int ?? self.scoreA
                    self.scoreB = payload["scoreB"] as? Int ?? self.scoreB
                    self.gameA = payload["gameA"] as? Int ?? self.gameA
                    self.gameB = payload["gameB"] as? Int ?? self.gameB
                    self.isConnected = true
                    return
                case "matchEnded":
                    self.matchStatus = "ended"
                    self.teamAName = payload["teamAName"] as? String ?? self.teamAName
                    self.teamBName = payload["teamBName"] as? String ?? self.teamBName
                    self.scoreA = payload["scoreA"] as? Int ?? self.scoreA
                    self.scoreB = payload["scoreB"] as? Int ?? self.scoreB
                    self.gameA = payload["gameA"] as? Int ?? self.gameA
                    self.gameB = payload["gameB"] as? Int ?? self.gameB
                    self.isMatchOver = true
                    self.isConnected = true
                    return
                default:
                    break
                }
            }

            // Regular score update
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
            self.matchStatus = "playing"
            self.isConnected = true
        }
    }

    // MARK: - Send Match History to Watch

    func sendMatchHistoryToWatch(_ record: MatchRecord) {
        guard WCSession.default.activationState == .activated else { return }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var gamesPayload: [[String: Any]] = []
        for game in record.gameScores {
            var historyArray: [[String: Any]] = []
            for snap in game.history {
                historyArray.append([
                    "scoreA": snap.scoreA,
                    "scoreB": snap.scoreB,
                    "servingTeamIsA": snap.servingTeamIsA
                ])
            }
            gamesPayload.append([
                "scoreA": game.scoreA,
                "scoreB": game.scoreB,
                "history": historyArray
            ])
        }

        let payload: [String: Any] = [
            "type": "matchHistoryFromPhone",
            "matchId": record.id.uuidString,
            "teamAName": record.teamAName,
            "teamBName": record.teamBName,
            "matchType": record.matchType.rawValue,
            "totalGames": record.totalGames,
            "winningScore": record.winningScore,
            "startTime": formatter.string(from: record.startTime),
            "endTime": formatter.string(from: record.endTime),
            "games": gamesPayload,
            "gamesWonByA": record.gamesWonByA,
            "gamesWonByB": record.gamesWonByB,
            "isCompleted": record.isCompleted
        ]

        WCSession.default.transferUserInfo(payload)
        print("[PhoneSession] Sent match history to Watch")
    }

    // MARK: - Handle Match History from Watch

    private func handleMatchHistory(_ payload: [String: Any]) {
        guard let record = MatchRecord.from(payload: payload) else {
            print("[PhoneSession] Failed to parse match history payload")
            return
        }

        // Store to iPhone-local UserDefaults
        let key = "match_history_phone"
        var history: [MatchRecord] = []
        if let data = UserDefaults.standard.data(forKey: key) {
            history = (try? JSONDecoder().decode([MatchRecord].self, from: data)) ?? []
        }

        // Deduplicate by matchId
        if !history.contains(where: { $0.id == record.id }) {
            history.insert(record, at: 0)
            // Sort by start time descending
            history.sort { $0.startTime > $1.startTime }

            if let data = try? JSONEncoder().encode(history) {
                UserDefaults.standard.set(data, forKey: key)
                print("[PhoneSession] Saved match history, total: \(history.count)")
            }
        } else {
            print("[PhoneSession] Duplicate match history ignored: \(record.id)")
        }

        // Notify MatchHistoryStore to refresh
        MatchHistoryStore.shared.refresh()
    }
}
