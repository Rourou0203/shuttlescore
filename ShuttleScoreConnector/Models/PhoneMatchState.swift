import Foundation
import UIKit

// ServiceCourt: 发球区（iPhone 端独立定义，Watch 端有自己的版本）
enum ServiceCourt {
    case right, left
    var label: String { self == .right ? "右区" : "左区" }
}

// MARK: - Phone Game State

struct PhoneGameState: Codable {
    var scoreA: Int = 0
    var scoreB: Int = 0
    var servingTeamIsA: Bool
    var winningScore: Int = 21
    var history: [GameSnapshot] = []

    struct GameSnapshot: Codable {
        var scoreA: Int
        var scoreB: Int
        var servingTeamIsA: Bool
    }

    var serviceCourt: ServiceCourt {
        let s = servingTeamIsA ? scoreA : scoreB
        return s % 2 == 0 ? .right : .left
    }

    var isOver: Bool {
        let hi = max(scoreA, scoreB)
        let lo = min(scoreA, scoreB)
        let cap = winningScore + 9
        if hi == cap { return true }
        if hi >= winningScore && hi - lo >= 2 { return true }
        return false
    }

    var winner: Bool? {
        guard isOver else { return nil }
        return scoreA > scoreB
    }
}

// MARK: - Phone Match State

class PhoneMatchState: ObservableObject, Identifiable {
    let id = UUID()
    @Published var matchType: MatchType = .singles
    @Published var teamAName: String = "我方"
    @Published var teamBName: String = "对手"
    @Published var totalGames: Int = 3
    @Published var games: [PhoneGameState]
    @Published var currentGameIndex: Int = 0
    @Published var startTime: Date = Date()
    @Published var endTime: Date?
    @Published var winningScore: Int = 21

    init(matchType: MatchType = .singles, teamAName: String = "我方", teamBName: String = "对手",
         totalGames: Int = 3, firstServeIsA: Bool = true, winningScore: Int = 21) {
        self.matchType = matchType
        self.teamAName = teamAName
        self.teamBName = teamBName
        self.totalGames = totalGames
        self.winningScore = winningScore
        self.games = [PhoneGameState(servingTeamIsA: firstServeIsA, winningScore: winningScore)]
    }

    var currentGame: PhoneGameState {
        get { games[currentGameIndex] }
        set { games[currentGameIndex] = newValue }
    }

    var gamesWonByA: Int { games.filter { $0.winner == true }.count }
    var gamesWonByB: Int { games.filter { $0.winner == false }.count }
    var winsNeeded: Int { (totalGames + 1) / 2 }
    var isMatchOver: Bool { gamesWonByA >= winsNeeded || gamesWonByB >= winsNeeded }

    var matchWinner: Bool? {
        guard isMatchOver else { return nil }
        return gamesWonByA > gamesWonByB
    }

    var elapsedMinutes: Int {
        Int((endTime ?? Date()).timeIntervalSince(startTime) / 60)
    }

    // MARK: - Scoring

    func addPoint(teamA: Bool) {
        guard !currentGame.isOver && !isMatchOver else { return }
        var game = currentGame
        // 保存快照用于撤销
        game.history.append(.init(scoreA: game.scoreA, scoreB: game.scoreB, servingTeamIsA: game.servingTeamIsA))
        if teamA { game.scoreA += 1 } else { game.scoreB += 1 }
        // BWF 规则：得分方获得发球权
        game.servingTeamIsA = teamA
        currentGame = game

        if isMatchOver { endTime = Date() }

        // iPhone 触觉反馈
        let style: UIImpactFeedbackGenerator.FeedbackStyle = game.isOver ? .heavy : .light
        let impact = UIImpactFeedbackGenerator(style: style)
        impact.impactOccurred()
    }

    func undo() {
        guard !currentGame.history.isEmpty else { return }
        var game = currentGame
        let prev = game.history.removeLast()
        game.scoreA = prev.scoreA
        game.scoreB = prev.scoreB
        game.servingTeamIsA = prev.servingTeamIsA
        currentGame = game
        endTime = nil
    }

    func startNextGame() {
        guard currentGame.isOver && !isMatchOver else { return }
        // BWF 规则：下一局由输局方先发
        let prevWinnerIsA = currentGame.winner ?? true
        games.append(PhoneGameState(servingTeamIsA: !prevWinnerIsA, winningScore: winningScore))
        currentGameIndex += 1
    }

    // MARK: - 转为 MatchRecord 保存到历史

    func toMatchRecord() -> MatchRecord {
        let gameScores = games.map { game in
            GameScore(
                scoreA: game.scoreA,
                scoreB: game.scoreB,
                history: game.history.map {
                    ScoreSnapshot(scoreA: $0.scoreA, scoreB: $0.scoreB, servingTeamIsA: $0.servingTeamIsA)
                }
            )
        }
        let winner: String
        if let w = matchWinner {
            winner = w ? teamAName : teamBName
        } else {
            winner = "未分胜负"
        }
        return MatchRecord(
            teamAName: teamAName,
            teamBName: teamBName,
            matchType: matchType,
            winningScore: winningScore,
            totalGames: totalGames,
            gameScores: gameScores,
            gamesWonByA: gamesWonByA,
            gamesWonByB: gamesWonByB,
            winnerName: winner,
            startTime: startTime,
            endTime: endTime ?? Date(),
            isCompleted: isMatchOver
        )
    }
}
