import Foundation

struct Achievement: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let requirement: (MatchHistoryStore) -> Bool

    var isUnlocked: Bool = false
}

struct AchievementManager {
    static func allAchievements() -> [Achievement] {
        [
            Achievement(
                id: "first_match",
                title: "初出茅庐",
                description: "完成第一场比赛",
                icon: "medal",
                requirement: { store in store.totalMatches >= 1 }
            ),
            Achievement(
                id: "gold_cat",
                title: "金牌橘猫",
                description: "赢得5场比赛",
                icon: "medal.fill",
                requirement: { store in store.totalWins >= 5 }
            ),
            Achievement(
                id: "win_streak",
                title: "连胜之王",
                description: "连续赢3场",
                icon: "flame",
                requirement: { store in store.longestWinStreak >= 3 }
            ),
            Achievement(
                id: "flash_win",
                title: "闪电战",
                description: "在10分钟内赢一场",
                icon: "bolt.fill",
                requirement: { store in store.hasFlashWin }
            ),
            Achievement(
                id: "legend",
                title: "百场传奇",
                description: "打完100场比赛",
                icon: "crown.fill",
                requirement: { store in store.totalMatches >= 100 }
            ),
        ]
    }

    static func evaluate(with store: MatchHistoryStore) -> [Achievement] {
        allAchievements().map { achievement in
            var a = achievement
            a.isUnlocked = achievement.requirement(store)
            return a
        }
    }
}
