import Foundation

// MARK: - Game Score (Codable-friendly replacement for tuple)

struct GameScore: Codable {
    var scoreA: Int
    var scoreB: Int
}

// MARK: - Match Record

struct MatchRecord: Codable, Identifiable {
    var id: UUID = UUID()
    var teamAName: String
    var teamBName: String
    var matchType: MatchType
    var winningScore: Int
    var gameScores: [GameScore]
    var gamesWonByA: Int
    var gamesWonByB: Int
    var winnerName: String
    var startTime: Date
    var endTime: Date

    var elapsedMinutes: Int {
        Int(endTime.timeIntervalSince(startTime) / 60)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(startTime)
    }

    // Build a MatchRecord from a finished or partially-finished MatchState
    static func from(_ match: MatchState) -> MatchRecord? {
        guard let endTime = match.endTime else { return nil }

        let winnerName: String
        if match.gamesWonByA > match.gamesWonByB {
            winnerName = match.teamAName
        } else if match.gamesWonByB > match.gamesWonByA {
            winnerName = match.teamBName
        } else {
            winnerName = "未分胜负"
        }

        // 包含所有有得分的局（含未打完的当前局）
        let gameScores = match.games.compactMap { g in
            (g.scoreA > 0 || g.scoreB > 0) ? GameScore(scoreA: g.scoreA, scoreB: g.scoreB) : nil
        }

        return MatchRecord(
            teamAName: match.teamAName,
            teamBName: match.teamBName,
            matchType: match.matchType,
            winningScore: match.winningScore,
            gameScores: gameScores,
            gamesWonByA: match.gamesWonByA,
            gamesWonByB: match.gamesWonByB,
            winnerName: winnerName,
            startTime: match.startTime,
            endTime: endTime
        )
    }
}
