import Foundation

struct SessionState: Codable {
    var sessionId: UUID = UUID()
    var startDate: Date = Date()
    var matchCount: Int = 0
    var isPaused: Bool = false

    var isToday: Bool {
        Calendar.current.isDateInToday(startDate)
    }

    private static let key = "practice_session"

    static func load() -> SessionState? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(SessionState.self, from: data)
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
