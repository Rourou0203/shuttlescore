import Foundation

// MARK: - Enums

enum MatchType: String, CaseIterable, Codable {
    case singles = "单打"
    case mensDoubles = "男双"
    case womensDoubles = "女双"
    case mixedDoubles = "混双"

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        if raw == "双打" {
            self = .mixedDoubles
        } else {
            self = MatchType(rawValue: raw) ?? .singles
        }
    }
}

enum ServiceCourt {
    case right, left
    var label: String { self == .right ? "右区" : "左区" }
}

// MARK: - Game State

struct GameState: Codable {
    var scoreA: Int = 0
    var scoreB: Int = 0
    var servingTeamIsA: Bool
    var winningScore: Int = 21
    // History for undo: store snapshots
    var history: [GameSnapshot] = []

    struct GameSnapshot: Codable {
        var scoreA: Int
        var scoreB: Int
        var servingTeamIsA: Bool
    }

    // Which court the server stands in (based on serving team's current score)
    var serviceCourt: ServiceCourt {
        let servingScore = servingTeamIsA ? scoreA : scoreB
        return servingScore % 2 == 0 ? .right : .left
    }

    var isOver: Bool {
        ScoringEngine.isGameOver(scoreA: scoreA, scoreB: scoreB, winningScore: winningScore)
    }

    // true = team A won, false = team B won, nil = ongoing
    var winner: Bool? {
        guard isOver else { return nil }
        return scoreA > scoreB
    }

    // Is this a deciding game situation where sides swap at 11?
    var shouldAlertSideChange: Bool {
        let servingScore = servingTeamIsA ? scoreA : scoreB
        let receivingScore = servingTeamIsA ? scoreB : scoreA
        return max(servingScore, receivingScore) == 11 && min(servingScore, receivingScore) < 11
    }
}

// MARK: - Match State

class MatchState: ObservableObject, Codable {
    @Published var matchType: MatchType
    @Published var teamAName: String
    @Published var teamBName: String
    @Published var totalGames: Int          // 1, 3, or 5
    @Published var games: [GameState]
    @Published var currentGameIndex: Int
    @Published var startTime: Date
    @Published var endTime: Date?

    @Published var sideChangeEnabled: Bool
    @Published var winningScore: Int

    init(
        matchType: MatchType = .singles,
        teamAName: String = "我方",
        teamBName: String = "对手",
        totalGames: Int = 3,
        firstServeIsA: Bool = true,
        sideChangeEnabled: Bool = false,
        winningScore: Int = 21
    ) {
        self.matchType = matchType
        self.teamAName = teamAName
        self.teamBName = teamBName
        self.totalGames = totalGames
        self.sideChangeEnabled = sideChangeEnabled
        self.winningScore = winningScore
        self.games = [GameState(servingTeamIsA: firstServeIsA, winningScore: winningScore)]
        self.currentGameIndex = 0
        self.startTime = Date()
    }

    // MARK: Computed

    var currentGame: GameState {
        get { games[currentGameIndex] }
        set { games[currentGameIndex] = newValue }
    }

    var gamesWonByA: Int { games.filter { $0.winner == true }.count }
    var gamesWonByB: Int { games.filter { $0.winner == false }.count }
    var winsNeeded: Int { (totalGames + 1) / 2 }

    var isMatchOver: Bool {
        gamesWonByA >= winsNeeded || gamesWonByB >= winsNeeded
    }

    // true = A wins match, false = B wins
    var matchWinner: Bool? {
        guard isMatchOver else { return nil }
        return gamesWonByA > gamesWonByB
    }

    var elapsedMinutes: Int {
        let end = endTime ?? Date()
        return Int(end.timeIntervalSince(startTime) / 60)
    }

    // MARK: Codable
    enum CodingKeys: String, CodingKey {
        case matchType, teamAName, teamBName, totalGames, sideChangeEnabled, winningScore, games, currentGameIndex, startTime, endTime
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        matchType = try c.decode(MatchType.self, forKey: .matchType)
        teamAName = try c.decode(String.self, forKey: .teamAName)
        teamBName = try c.decode(String.self, forKey: .teamBName)
        totalGames = try c.decode(Int.self, forKey: .totalGames)
        sideChangeEnabled = try c.decodeIfPresent(Bool.self, forKey: .sideChangeEnabled) ?? false
        winningScore = try c.decodeIfPresent(Int.self, forKey: .winningScore) ?? 21
        games = try c.decode([GameState].self, forKey: .games)
        currentGameIndex = try c.decode(Int.self, forKey: .currentGameIndex)
        startTime = try c.decode(Date.self, forKey: .startTime)
        endTime = try c.decodeIfPresent(Date.self, forKey: .endTime)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(matchType, forKey: .matchType)
        try c.encode(teamAName, forKey: .teamAName)
        try c.encode(teamBName, forKey: .teamBName)
        try c.encode(totalGames, forKey: .totalGames)
        try c.encode(sideChangeEnabled, forKey: .sideChangeEnabled)
        try c.encode(winningScore, forKey: .winningScore)
        try c.encode(games, forKey: .games)
        try c.encode(currentGameIndex, forKey: .currentGameIndex)
        try c.encode(startTime, forKey: .startTime)
        try c.encode(endTime, forKey: .endTime)
    }
}
