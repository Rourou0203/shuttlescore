import Foundation

struct GameScore: Codable {
    var scoreA: Int
    var scoreB: Int
    /// Point-by-point history: each snapshot records the score after each rally
    var history: [ScoreSnapshot]

    init(scoreA: Int, scoreB: Int, history: [ScoreSnapshot] = []) {
        self.scoreA = scoreA
        self.scoreB = scoreB
        self.history = history
    }
}

struct ScoreSnapshot: Codable {
    var scoreA: Int
    var scoreB: Int
    var servingTeamIsA: Bool
}
