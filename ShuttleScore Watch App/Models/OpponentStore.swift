import Foundation

class OpponentStore: ObservableObject {
    static let shared = OpponentStore()
    private let key = "opponent_list"

    @Published var opponents: [String] = []

    init() { load() }

    func add(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              trimmed != "我方", trimmed != "对手",
              !opponents.contains(trimmed) else { return }
        opponents.insert(trimmed, at: 0)
        if opponents.count > 30 { opponents = Array(opponents.prefix(30)) }
        save()
    }

    func remove(at index: Int) {
        guard opponents.indices.contains(index) else { return }
        opponents.remove(at: index)
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        opponents = (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    private func save() {
        if let data = try? JSONEncoder().encode(opponents) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
