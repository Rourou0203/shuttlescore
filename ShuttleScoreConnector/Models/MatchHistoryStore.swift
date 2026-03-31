import Foundation
import SwiftUI

class MatchHistoryStore: ObservableObject {
    static let shared = MatchHistoryStore()

    private let historyKey = "match_history"

    @Published var records: [MatchRecord] = []

    init() {
        records = loadHistory()
    }

    func loadHistory() -> [MatchRecord] {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else { return [] }
        do {
            return try JSONDecoder().decode([MatchRecord].self, from: data)
        } catch {
            print("[MatchHistoryStore] 读取历史失败: \(error)")
            return []
        }
    }

    func refresh() {
        records = loadHistory()
    }

    // MARK: - Stats

    var totalMatches: Int { records.count }

    var totalWins: Int {
        records.filter { $0.teamAWon }.count
    }

    var winRate: Double {
        guard totalMatches > 0 else { return 0 }
        return Double(totalWins) / Double(totalMatches)
    }

    var totalMinutes: Int {
        records.reduce(0) { $0 + $1.elapsedMinutes }
    }

    var currentWinStreak: Int {
        var streak = 0
        for record in records {
            if record.teamAWon {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    var longestWinStreak: Int {
        var maxStreak = 0
        var currentStreak = 0
        for record in records {
            if record.teamAWon {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        return maxStreak
    }

    var hasFlashWin: Bool {
        records.contains { $0.teamAWon && $0.elapsedMinutes < 10 }
    }
}
