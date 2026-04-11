import Foundation

class MatchStore: ObservableObject {
    static let shared = MatchStore()

    private let key = "current_match"

    @Published var currentMatch: MatchState?

    func save(_ match: MatchState) {
        do {
            let data = try JSONEncoder().encode(match)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("[MatchStore] 保存比赛失败: \(error)")
        }
        currentMatch = match
    }

    @discardableResult
    func load() -> MatchState? {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            currentMatch = nil
            return nil
        }
        do {
            let match = try JSONDecoder().decode(MatchState.self, from: data)
            currentMatch = match
            return match
        } catch {
            print("[MatchStore] 读取比赛失败: \(error)")
            currentMatch = nil
            return nil
        }
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
        currentMatch = nil
    }

    // MARK: - Match History

    private let historyKey = "match_history"

    func saveToHistory(_ match: MatchState) {
        guard let record = MatchRecord.from(match) else {
            print("[MatchStore] saveToHistory: MatchRecord.from returned nil (endTime=\(String(describing: match.endTime)))")
            return
        }

        var history = loadHistory()
        // Dedup by startTime — same match always has the same startTime,
        // whereas MatchRecord.id is a fresh UUID each call
        if history.contains(where: { $0.startTime == record.startTime }) { return }

        history.insert(record, at: 0)
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    func loadHistory() -> [MatchRecord] {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else { return [] }
        do {
            return try JSONDecoder().decode([MatchRecord].self, from: data)
        } catch {
            print("[MatchStore] 读取历史失败: \(error)")
            return []
        }
    }

    func todayRecords() -> [MatchRecord] {
        loadHistory().filter { $0.isToday }
    }

    /// 查询与指定对手的历史战绩（wins=我方胜场，losses=我方败场）
    func recordsAgainst(opponent: String) -> (wins: Int, losses: Int) {
        guard !opponent.isEmpty else { return (0, 0) }
        let history = loadHistory()
        let relevant = history.filter { $0.teamAName == opponent || $0.teamBName == opponent }
        let wins = relevant.filter { $0.winnerName != opponent }.count
        let losses = relevant.filter { $0.winnerName == opponent }.count
        return (wins, losses)
    }

    // MARK: - Last Match Settings (Quick Start)

    private let lastSettingsKey = "last_match_settings"

    struct MatchSettings: Codable {
        var matchType: MatchType
        var totalGames: Int
        var winningScore: Int
        var teamAName: String
        var teamBName: String
        var voiceAnnouncement: Bool = false
    }

    func saveLastSettings(_ settings: MatchSettings) {
        do {
            let data = try JSONEncoder().encode(settings)
            UserDefaults.standard.set(data, forKey: lastSettingsKey)
        } catch {
            print("[MatchStore] 保存设置失败: \(error)")
        }
    }

    func loadLastSettings() -> MatchSettings? {
        guard let data = UserDefaults.standard.data(forKey: lastSettingsKey) else { return nil }
        do {
            return try JSONDecoder().decode(MatchSettings.self, from: data)
        } catch {
            print("[MatchStore] 读取设置失败: \(error)")
            return nil
        }
    }
}
