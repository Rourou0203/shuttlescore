import Foundation

// MARK: - Match Record

struct MatchRecord: Codable, Identifiable {
    var id: UUID = UUID()
    var teamAName: String
    var teamBName: String
    var matchType: MatchType
    var winningScore: Int
    var totalGames: Int
    var gameScores: [GameScore]
    var gamesWonByA: Int
    var gamesWonByB: Int
    var winnerName: String
    var startTime: Date
    var endTime: Date
    var isCompleted: Bool

    var elapsedMinutes: Int {
        Int(endTime.timeIntervalSince(startTime) / 60)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(startTime)
    }

    var teamAWon: Bool {
        gamesWonByA > gamesWonByB
    }

    // MARK: - Per-game analysis

    /// Count of deuce situations (score tied at winningScore-1 or beyond) across all games
    var totalDeuces: Int {
        gameScores.reduce(0) { total, game in
            total + deuceCount(for: game)
        }
    }

    /// Number of games where a team came back from 5+ points behind to win
    var comebackGames: Int {
        gameScores.filter { isComebackGame($0) }.count
    }

    /// Longest scoring run by team A across all games
    var longestRunA: Int {
        gameScores.reduce(0) { max($0, longestRun(for: true, in: $1)) }
    }

    /// Longest scoring run by team B across all games
    var longestRunB: Int {
        gameScores.reduce(0) { max($0, longestRun(for: false, in: $1)) }
    }

    // MARK: - Analysis helpers

    private func deuceCount(for game: GameScore) -> Int {
        let deuceThreshold = winningScore - 1  // e.g. 20 for 21-point game
        var count = 0
        for snap in game.history {
            if snap.scoreA >= deuceThreshold && snap.scoreB >= deuceThreshold && snap.scoreA == snap.scoreB {
                count += 1
            }
        }
        return count
    }

    private func isComebackGame(_ game: GameScore) -> Bool {
        guard !game.history.isEmpty else { return false }
        let winnerIsA = game.scoreA > game.scoreB

        var maxDeficit = 0
        for snap in game.history {
            let deficit = winnerIsA ? (snap.scoreB - snap.scoreA) : (snap.scoreA - snap.scoreB)
            maxDeficit = max(maxDeficit, deficit)
        }
        return maxDeficit >= 5
    }

    private func longestRun(for teamA: Bool, in game: GameScore) -> Int {
        guard game.history.count >= 2 else { return 0 }
        var maxRun = 0
        var currentRun = 0

        for i in 1..<game.history.count {
            let prev = game.history[i - 1]
            let curr = game.history[i]
            let teamScored = teamA ? (curr.scoreA > prev.scoreA) : (curr.scoreB > prev.scoreB)
            if teamScored {
                currentRun += 1
                maxRun = max(maxRun, currentRun)
            } else {
                currentRun = 0
            }
        }
        return maxRun
    }

    // MARK: - Build from WatchConnectivity payload

    static func from(payload: [String: Any]) -> MatchRecord? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let matchId = payload["matchId"] as? String,
              let teamAName = payload["teamAName"] as? String,
              let teamBName = payload["teamBName"] as? String,
              let matchTypeRaw = payload["matchType"] as? String,
              let totalGames = payload["totalGames"] as? Int,
              let winningScore = payload["winningScore"] as? Int,
              let startTimeStr = payload["startTime"] as? String,
              let endTimeStr = payload["endTime"] as? String,
              let gamesArray = payload["games"] as? [[String: Any]],
              let gamesWonByA = payload["gamesWonByA"] as? Int,
              let gamesWonByB = payload["gamesWonByB"] as? Int,
              let isCompleted = payload["isCompleted"] as? Bool,
              let startTime = formatter.date(from: startTimeStr),
              let endTime = formatter.date(from: endTimeStr)
        else {
            print("[MatchRecord] Failed to parse payload")
            return nil
        }

        let matchType = MatchType(rawValue: matchTypeRaw) ?? .singles

        // Parse games
        var gameScores: [GameScore] = []
        for gameDict in gamesArray {
            let scoreA = gameDict["scoreA"] as? Int ?? 0
            let scoreB = gameDict["scoreB"] as? Int ?? 0
            var history: [ScoreSnapshot] = []
            if let historyArray = gameDict["history"] as? [[String: Any]] {
                for snap in historyArray {
                    history.append(ScoreSnapshot(
                        scoreA: snap["scoreA"] as? Int ?? 0,
                        scoreB: snap["scoreB"] as? Int ?? 0,
                        servingTeamIsA: snap["servingTeamIsA"] as? Bool ?? true
                    ))
                }
            }
            gameScores.append(GameScore(scoreA: scoreA, scoreB: scoreB, history: history))
        }

        let winnerName: String
        if gamesWonByA > gamesWonByB {
            winnerName = teamAName
        } else if gamesWonByB > gamesWonByA {
            winnerName = teamBName
        } else {
            winnerName = "未分胜负"
        }

        return MatchRecord(
            id: UUID(uuidString: matchId) ?? UUID(),
            teamAName: teamAName,
            teamBName: teamBName,
            matchType: matchType,
            winningScore: winningScore,
            totalGames: totalGames,
            gameScores: gameScores,
            gamesWonByA: gamesWonByA,
            gamesWonByB: gamesWonByB,
            winnerName: winnerName,
            startTime: startTime,
            endTime: endTime,
            isCompleted: isCompleted
        )
    }
}
