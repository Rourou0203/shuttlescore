import Foundation
import WatchConnectivity

class PhoneOpponentStore: ObservableObject {
    static let shared = PhoneOpponentStore()
    private let key = "opponent_list_phone"

    @Published var opponents: [String] = []

    init() { load() }

    func add(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed != "我方", trimmed != "对手",
              !opponents.contains(trimmed) else { return }
        opponents.insert(trimmed, at: 0)
        if opponents.count > 30 { opponents = Array(opponents.prefix(30)) }
        save()
        syncToWatch()
    }

    func remove(at index: Int) {
        guard opponents.indices.contains(index) else { return }
        opponents.remove(at: index)
        save()
        syncToWatch()
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        opponents = (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    func save() {
        if let data = try? JSONEncoder().encode(opponents) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func mergeFromWatch(_ watchOpponents: [String]) {
        var changed = false
        for name in watchOpponents {
            let trimmed = name.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty && trimmed != "我方" && trimmed != "对手" && !opponents.contains(trimmed) {
                opponents.append(trimmed)
                changed = true
            }
        }
        if changed { save() }
    }

    private func syncToWatch() {
        guard WCSession.default.activationState == .activated else { return }
        let payload: [String: Any] = [
            "type": "opponentList",
            "opponents": opponents
        ]
        WCSession.default.transferUserInfo(payload)
    }
}
