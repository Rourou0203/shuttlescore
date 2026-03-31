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

    func load() -> MatchState? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(MatchState.self, from: data)
        } catch {
            print("[MatchStore] 读取比赛失败: \(error)")
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
        guard let record = MatchRecord.from(match) else { return }
        var history = loadHistory()
        history.insert(record, at: 0)
        // Only keep records from the last 30 days
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        history = history.filter { $0.startTime > cutoff }
        do {
            let data = try JSONEncoder().encode(history)
            UserDefaults.standard.set(data, forKey: historyKey)
        } catch {
            print("[MatchStore] 保存历史失败: \(error)")
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

    // MARK: - Last Match Settings (Quick Start)

    private let lastSettingsKey = "last_match_settings"

    struct MatchSettings: Codable {
        var matchType: MatchType
        var totalGames: Int
        var winningScore: Int
        var teamAName: String
        var teamBName: String
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
