import Foundation
import SwiftUI

class MatchHistoryStore: ObservableObject {
    static let shared = MatchHistoryStore()

    private let historyKey = "match_history_phone"

    @Published var records: [MatchRecord] = []

    init() {
        records = loadHistory()
    }

    func loadHistory() -> [MatchRecord] {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else { return [] }
        do {
            return try JSONDecoder().decode([MatchRecord].self, from: data)
        } catch {
            print("[MatchHistoryStore] Failed to decode history: \(error)")
            return []
        }
    }

    func refresh() {
        records = loadHistory()
    }

    // MARK: - Overview Stats

    var totalMatches: Int { records.count }

    var totalWins: Int {
        records.filter { $0.teamAWon }.count
    }

    var totalLosses: Int {
        records.filter { !$0.teamAWon }.count
    }

    var winRate: Double {
        guard totalMatches > 0 else { return 0 }
        return Double(totalWins) / Double(totalMatches)
    }

    var totalMinutes: Int {
        records.reduce(0) { $0 + $1.elapsedMinutes }
    }

    var completedMatches: Int {
        records.filter { $0.isCompleted }.count
    }

    // MARK: - Streak Stats

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

    var currentLoseStreak: Int {
        var streak = 0
        for record in records {
            if !record.teamAWon {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    var longestWinStreak: Int {
        var maxStreak = 0
        var current = 0
        for record in records {
            if record.teamAWon {
                current += 1
                maxStreak = max(maxStreak, current)
            } else {
                current = 0
            }
        }
        return maxStreak
    }

    var longestLoseStreak: Int {
        var maxStreak = 0
        var current = 0
        for record in records {
            if !record.teamAWon {
                current += 1
                maxStreak = max(maxStreak, current)
            } else {
                current = 0
            }
        }
        return maxStreak
    }

    // MARK: - Recent form (last 10 matches)

    var recentRecords: [MatchRecord] {
        Array(records.prefix(10))
    }

    var recentWinRate: Double {
        let recent = recentRecords
        guard !recent.isEmpty else { return 0 }
        let wins = recent.filter { $0.teamAWon }.count
        return Double(wins) / Double(recent.count)
    }

    // MARK: - Aggregate game analysis

    var totalDeuces: Int {
        records.reduce(0) { $0 + $1.totalDeuces }
    }

    var totalComebacks: Int {
        records.reduce(0) { $0 + $1.comebackGames }
    }

    // MARK: - Date-based stats

    /// Records grouped by date string (yyyy-MM-dd)
    var recordsByDate: [(date: String, displayDate: String, records: [MatchRecord])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "M月d日 EEEE"
        displayFormatter.locale = Locale(identifier: "zh_CN")

        let grouped = Dictionary(grouping: records) { record in
            formatter.string(from: record.startTime)
        }

        return grouped.keys.sorted().reversed().map { key in
            let recs = grouped[key]!.sorted { $0.startTime > $1.startTime }
            let displayDate: String
            if Calendar.current.isDateInToday(recs[0].startTime) {
                displayDate = "今天"
            } else if Calendar.current.isDateInYesterday(recs[0].startTime) {
                displayDate = "昨天"
            } else {
                displayDate = displayFormatter.string(from: recs[0].startTime)
            }
            return (date: key, displayDate: displayDate, records: recs)
        }
    }

    /// Average matches per week (over the last 4 weeks)
    var avgMatchesPerWeek: Double {
        guard !records.isEmpty else { return 0 }
        let fourWeeksAgo = Calendar.current.date(byAdding: .day, value: -28, to: Date())!
        let recentCount = records.filter { $0.startTime > fourWeeksAgo }.count
        return Double(recentCount) / 4.0
    }

    /// Days with matches in the last 30 days
    var activeDaysLast30: Int {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dates = Set(records.filter { $0.startTime > thirtyDaysAgo }.map { formatter.string(from: $0.startTime) })
        return dates.count
    }

    // MARK: - Quick check

    var hasFlashWin: Bool {
        records.contains { $0.teamAWon && $0.elapsedMinutes < 10 }
    }

    // MARK: - CRUD Operations

    func addRecord(_ record: MatchRecord) {
        records.insert(record, at: 0)
        saveHistory()
    }

    func deleteRecord(id: UUID) {
        records.removeAll { $0.id == id }
        saveHistory()
    }

    func updateRecord(_ record: MatchRecord) {
        guard let index = records.firstIndex(where: { $0.id == record.id }) else { return }
        records[index] = record
        saveHistory()
    }

    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(records)
            UserDefaults.standard.set(data, forKey: historyKey)
        } catch {
            print("[MatchHistoryStore] Failed to encode history: \(error)")
        }
    }
}
