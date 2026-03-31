import Foundation
import WatchKit

struct ScoringEngine {

    // MARK: - Game Over Check

    static func isGameOver(scoreA: Int, scoreB: Int, winningScore: Int = 21) -> Bool {
        let hi = max(scoreA, scoreB)
        let lo = min(scoreA, scoreB)
        // BWF规则：决胜分制下封顶 = 目标分 + 9（如21分制封顶30，11分制封顶20）
        let cap = winningScore + 9
        if hi == cap { return true }                          // 封顶
        if hi >= winningScore && hi - lo >= 2 { return true } // 领先2分
        return false
    }

    // MARK: - Add Point

    /// Score a point for team A (teamA=true) or team B (teamA=false)
    /// Returns: true if serve changed, for haptic differentiation
    @discardableResult
    static func addPoint(to match: MatchState, teamAScores: Bool) -> Bool {
        guard !match.currentGame.isOver && !match.isMatchOver else { return false }

        var game = match.currentGame
        let wasServingA = game.servingTeamIsA

        // Save snapshot for undo
        game.history.append(.init(
            scoreA: game.scoreA,
            scoreB: game.scoreB,
            servingTeamIsA: game.servingTeamIsA
        ))

        // Add score
        if teamAScores { game.scoreA += 1 } else { game.scoreB += 1 }

        // Update serve: scorer gets/keeps serve
        game.servingTeamIsA = teamAScores

        match.currentGame = game

        let serveChanged = wasServingA != teamAScores

        // Haptic feedback
        if game.isOver {
            WKInterfaceDevice.current().play(.success)
        } else if serveChanged {
            WKInterfaceDevice.current().play(.retry)    // serve changes
        } else {
            WKInterfaceDevice.current().play(.click)    // normal point
        }

        // If match over, record end time
        if match.isMatchOver {
            match.endTime = Date()
        }

        return serveChanged
    }

    // MARK: - Undo

    static func undo(match: MatchState) {
        guard !match.currentGame.history.isEmpty else { return }
        var game = match.currentGame
        let prev = game.history.removeLast()
        game.scoreA = prev.scoreA
        game.scoreB = prev.scoreB
        game.servingTeamIsA = prev.servingTeamIsA
        match.currentGame = game

        WKInterfaceDevice.current().play(.directionDown)
    }

    // MARK: - Transfer Last Point (Quick Correction)

    /// Undo the last point and re-award it to the correct team.
    /// Use when the scorer accidentally tapped the wrong side.
    static func transferLastPoint(to match: MatchState, toTeamA: Bool) {
        guard !match.currentGame.history.isEmpty else { return }

        // Step 1: undo (restore to snapshot before last point)
        var game = match.currentGame
        let prev = game.history.removeLast()
        game.scoreA = prev.scoreA
        game.scoreB = prev.scoreB
        game.servingTeamIsA = prev.servingTeamIsA
        match.currentGame = game

        // Step 2: re-award the point to the correct team
        addPoint(to: match, teamAScores: toTeamA)
    }

    // MARK: - Start Next Game

    static func startNextGame(match: MatchState) {
        guard match.currentGame.isOver && !match.isMatchOver else { return }

        // Loser of previous game serves first (BWF rule)
        let prevWinnerIsA = match.currentGame.winner ?? true
        let nextServingIsA = !prevWinnerIsA

        match.games.append(GameState(servingTeamIsA: nextServingIsA, winningScore: match.winningScore))
        match.currentGameIndex += 1

        WKInterfaceDevice.current().play(.start)
    }

    // MARK: - Serve Description

    static func serveDescription(for match: MatchState) -> String {
        let game = match.currentGame
        let servingName = game.servingTeamIsA ? match.teamAName : match.teamBName
        let court = game.serviceCourt.label
        return "\(servingName) 发球 · \(court)"
    }
}
