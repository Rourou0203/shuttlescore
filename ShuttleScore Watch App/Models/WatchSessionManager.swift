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

        // Real-time only: send if reachable, skip if not (avoid memory pressure from queued transfers)
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(payload, replyHandler: nil) { error in
            print("[WatchSession] sendMessage failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Send Match Terminated

    func sendMatchTerminated(match: MatchState) {
        guard WCSession.default.activationState == .activated else { return }

        let game = match.currentGame
        let payload: [String: Any] = [
            "type": "matchTerminated",
            "teamAName": match.teamAName,
            "teamBName": match.teamBName,
            "scoreA": game.scoreA,
            "scoreB": game.scoreB,
            "gameA": match.gamesWonByA,
            "gameB": match.gamesWonByB,
            "gameIndex": match.currentGameIndex
        ]

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil) { error in
                print("[WatchSession] sendMatchTerminated failed: \(error.localizedDescription)")
                WCSession.default.transferUserInfo(payload)
            }
        } else {
            WCSession.default.transferUserInfo(payload)
        }
    }

    // MARK: - Send Match Ended

    func sendMatchEnded(match: MatchState) {
        guard WCSession.default.activationState == .activated else { return }

        let game = match.currentGame
        let payload: [String: Any] = [
            "type": "matchEnded",
            "teamAName": match.teamAName,
            "teamBName": match.teamBName,
            "scoreA": game.scoreA,
            "scoreB": game.scoreB,
            "gameA": match.gamesWonByA,
            "gameB": match.gamesWonByB,
            "gameIndex": match.currentGameIndex,
            "totalGames": match.totalGames
        ]

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil) { error in
                print("[WatchSession] sendMatchEnded failed: \(error.localizedDescription)")
                WCSession.default.transferUserInfo(payload)
            }
        } else {
            WCSession.default.transferUserInfo(payload)
        }
    }

    // MARK: - Send Match History to iPhone

    func sendMatchHistory(match: MatchState) {
        guard WCSession.default.activationState == .activated else { return }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Build games array: each game includes final score + full history
        var gamesPayload: [[String: Any]] = []
        for game in match.games {
            // Only include games that have been played
            guard game.scoreA > 0 || game.scoreB > 0 else { continue }

            var historyArray: [[String: Any]] = []
            for snapshot in game.history {
                historyArray.append([
                    "scoreA": snapshot.scoreA,
                    "scoreB": snapshot.scoreB,
                    "servingTeamIsA": snapshot.servingTeamIsA
                ])
            }

            gamesPayload.append([
                "scoreA": game.scoreA,
                "scoreB": game.scoreB,
                "servingTeamIsA": game.servingTeamIsA,
                "history": historyArray
            ])
        }

        let endTime = match.endTime ?? Date()
        let payload: [String: Any] = [
            "type": "matchHistory",
            "matchId": UUID().uuidString,
            "teamAName": match.teamAName,
            "teamBName": match.teamBName,
            "matchType": match.matchType.rawValue,
            "totalGames": match.totalGames,
            "winningScore": match.winningScore,
            "startTime": formatter.string(from: match.startTime),
            "endTime": formatter.string(from: endTime),
            "games": gamesPayload,
            "gamesWonByA": match.gamesWonByA,
            "gamesWonByB": match.gamesWonByB,
            "isCompleted": match.isMatchOver
        ]

        // Use transferUserInfo for reliable background delivery
        WCSession.default.transferUserInfo(payload)
        print("[WatchSession] Sent match history to iPhone")
    }

    // MARK: - Receive UserInfo (from iPhone)

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let type = userInfo["type"] as? String else { return }

        switch type {
        case "matchHistoryFromPhone":
            handleMatchFromPhone(userInfo)
        case "opponentList":
            if let opponents = userInfo["opponents"] as? [String] {
                DispatchQueue.main.async {
                    for name in opponents {
                        OpponentStore.shared.add(name)
                    }
                }
            }
        default:
            break
        }
    }

    private func handleMatchFromPhone(_ payload: [String: Any]) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let matchId = payload["matchId"] as? String,
              let teamAName = payload["teamAName"] as? String,
              let teamBName = payload["teamBName"] as? String,
              let matchTypeRaw = payload["matchType"] as? String,
              let winningScore = payload["winningScore"] as? Int,
              let startTimeStr = payload["startTime"] as? String,
              let endTimeStr = payload["endTime"] as? String,
              let gamesArray = payload["games"] as? [[String: Any]],
              let gamesWonByA = payload["gamesWonByA"] as? Int,
              let gamesWonByB = payload["gamesWonByB"] as? Int,
              let startTime = formatter.date(from: startTimeStr),
              let endTime = formatter.date(from: endTimeStr)
        else {
            print("[WatchSession] Failed to parse matchHistoryFromPhone payload")
            return
        }

        let id = UUID(uuidString: matchId) ?? UUID()
        let matchType = MatchType(rawValue: matchTypeRaw) ?? .singles

        // Build Watch-side GameScore array (no history on Watch)
        var gameScores: [GameScore] = []
        for g in gamesArray {
            gameScores.append(GameScore(
                scoreA: g["scoreA"] as? Int ?? 0,
                scoreB: g["scoreB"] as? Int ?? 0
            ))
        }

        let winnerName: String
        if gamesWonByA > gamesWonByB {
            winnerName = teamAName
        } else if gamesWonByB > gamesWonByA {
            winnerName = teamBName
        } else {
            winnerName = "未分胜负"
        }

        // Deduplicate against existing history
        var history = MatchStore.shared.loadHistory()
        guard !history.contains(where: { $0.id == id }) else {
            print("[WatchSession] Duplicate match from phone ignored: \(id)")
            return
        }

        let record = MatchRecord(
            id: id,
            teamAName: teamAName,
            teamBName: teamBName,
            matchType: matchType,
            winningScore: winningScore,
            gameScores: gameScores,
            gamesWonByA: gamesWonByA,
            gamesWonByB: gamesWonByB,
            winnerName: winnerName,
            startTime: startTime,
            endTime: endTime
        )

        history.insert(record, at: 0)
        history.sort { $0.startTime > $1.startTime }
        // Keep 30 days
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        history = history.filter { $0.startTime > cutoff }

        do {
            let data = try JSONEncoder().encode(history)
            UserDefaults.standard.set(data, forKey: "match_history")
            print("[WatchSession] Saved match from phone, total: \(history.count)")
        } catch {
            print("[WatchSession] Failed to save match from phone: \(error)")
        }

        // Also save opponent name
        DispatchQueue.main.async {
            OpponentStore.shared.add(teamBName)
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
