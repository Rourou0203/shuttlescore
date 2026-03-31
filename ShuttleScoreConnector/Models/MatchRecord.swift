import Foundation

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

    var teamAWon: Bool {
        gamesWonByA > gamesWonByB
    }
}
