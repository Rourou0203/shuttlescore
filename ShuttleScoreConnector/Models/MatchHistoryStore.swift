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

    // MARK: - Achievement helpers

    /// Number of unique opponents (by teamBName)
    var uniqueOpponentCount: Int {
        Set(records.map { $0.teamBName }).count
    }

    /// Maximum matches played in a single day
    var maxMatchesInOneDay: Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let grouped = Dictionary(grouping: records) { formatter.string(from: $0.startTime) }
        return grouped.values.map(\.count).max() ?? 0
    }

    /// Whether any single match lasted 30+ minutes
    var hasMarathonMatch: Bool {
        records.contains { $0.elapsedMinutes >= 30 }
    }

    /// Number of consecutive recent weekends with at least one match
    var consecutiveWeekendsPlayed: Int {
        let calendar = Calendar.current
        // Build a set of "weekend identifiers" (year-weekOfYear) where user played
        var weekendSet = Set<String>()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        for record in records {
            let weekday = calendar.component(.weekday, from: record.startTime)
            // Sunday=1, Saturday=7
            if weekday == 1 || weekday == 7 {
                let year = calendar.component(.yearForWeekOfYear, from: record.startTime)
                let week = calendar.component(.weekOfYear, from: record.startTime)
                weekendSet.insert("\(year)-\(week)")
            }
        }

        // Count consecutive weekends going back from the most recent weekend
        guard !weekendSet.isEmpty else { return 0 }

        // Find today's weekend reference, then walk backwards
        var checkDate = Date()
        var consecutive = 0

        // Go back up to 52 weekends
        for _ in 0..<52 {
            // Find the Saturday of the week containing checkDate
            let weekday = calendar.component(.weekday, from: checkDate)
            // Move to Saturday of this week
            let daysToSaturday = (7 - weekday) % 7
            guard let saturday = calendar.date(byAdding: .day, value: daysToSaturday == 0 && weekday != 7 ? -1 : daysToSaturday, to: checkDate) else { break }

            let year = calendar.component(.yearForWeekOfYear, from: saturday)
            let week = calendar.component(.weekOfYear, from: saturday)
            let key = "\(year)-\(week)"

            if weekendSet.contains(key) {
                consecutive += 1
            } else {
                // Allow skipping the current weekend if it hasn't happened yet
                if consecutive == 0 {
                    // Move to previous week and try again
                    guard let prevWeek = calendar.date(byAdding: .day, value: -7, to: checkDate) else { break }
                    checkDate = prevWeek
                    continue
                }
                break
            }

            guard let prevWeek = calendar.date(byAdding: .day, value: -7, to: checkDate) else { break }
            checkDate = prevWeek
        }

        return consecutive
    }

    /// Whether user has won at least one singles match
    var hasSinglesWin: Bool {
        records.contains { $0.teamAWon && $0.matchType == .singles }
    }

    /// Whether user has won at least one doubles match
    var hasDoublesWin: Bool {
        records.contains { $0.teamAWon && $0.matchType != .singles }
    }

    // MARK: - Period Filtering

    /// Filter records within a date range (inclusive of both start and end days)
    func records(from startDate: Date, to endDate: Date) -> [MatchRecord] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate))!
        return records.filter { $0.startTime >= start && $0.startTime < end }
    }

    /// Aggregate stats for a set of records
    func aggregateStats(for filtered: [MatchRecord]) -> PeriodStats {
        let wins = filtered.filter { $0.teamAWon }.count
        let losses = filtered.count - wins
        let totalMin = filtered.reduce(0) { $0 + $1.elapsedMinutes }
        let deuces = filtered.reduce(0) { $0 + $1.totalDeuces }
        let comebacks = filtered.reduce(0) { $0 + $1.comebackGames }

        // Longest win streak within this period (records are newest-first, reverse for chronological)
        let chronological = filtered.sorted { $0.startTime < $1.startTime }
        var maxWinStreak = 0
        var currentStreak = 0
        for r in chronological {
            if r.teamAWon {
                currentStreak += 1
                maxWinStreak = max(maxWinStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }

        // Best scoring run across all matches/games in the period
        var bestRun = 0
        for r in filtered {
            bestRun = max(bestRun, r.longestRunA)
        }

        // Top 3 opponents by match count
        var opponentMap: [String: (wins: Int, losses: Int)] = [:]
        for r in filtered {
            let opponent = r.teamBName
            var entry = opponentMap[opponent] ?? (0, 0)
            if r.teamAWon { entry.wins += 1 } else { entry.losses += 1 }
            opponentMap[opponent] = entry
        }
        let topOpponents = opponentMap
            .sorted { ($0.value.wins + $0.value.losses) > ($1.value.wins + $1.value.losses) }
            .prefix(3)
            .map { OpponentRecord(name: $0.key, wins: $0.value.wins, losses: $0.value.losses) }

        return PeriodStats(
            totalMatches: filtered.count,
            wins: wins,
            losses: losses,
            winRate: filtered.isEmpty ? 0 : Double(wins) / Double(filtered.count),
            totalMinutes: totalMin,
            longestWinStreak: maxWinStreak,
            totalDeuces: deuces,
            comebackGames: comebacks,
            bestScoringRun: bestRun,
            topOpponents: topOpponents
        )
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

// MARK: - Period Stats Model

struct PeriodStats {
    let totalMatches: Int
    let wins: Int
    let losses: Int
    let winRate: Double
    let totalMinutes: Int
    let longestWinStreak: Int
    let totalDeuces: Int
    let comebackGames: Int
    let bestScoringRun: Int
    let topOpponents: [OpponentRecord]
}

struct OpponentRecord: Identifiable {
    let id = UUID()
    let name: String
    let wins: Int
    let losses: Int
}
