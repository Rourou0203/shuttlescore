import Foundation

// MARK: - Achievement Tier

enum AchievementTier: String, CaseIterable {
    case bronze
    case silver
    case gold

    var sortOrder: Int {
        switch self {
        case .bronze: return 0
        case .silver: return 1
        case .gold: return 2
        }
    }
}

// MARK: - Achievement

struct Achievement: Identifiable {
    let id: String
    let title: String
    let titleEn: String
    let description: String
    let descriptionEn: String
    let icon: String
    let tier: AchievementTier
    let maxProgress: Int
    let requirement: (MatchHistoryStore) -> Bool
    let progress: (MatchHistoryStore) -> Int

    var isUnlocked: Bool = false
    var currentProgress: Int = 0
}

// MARK: - Achievement Manager

struct AchievementManager {

    static func allAchievements() -> [Achievement] {
        // ── Bronze (入门) ──────────────────────────────

        let bronze: [Achievement] = [
            Achievement(
                id: "first_match",
                title: "初出茅庐",
                titleEn: "First Step",
                description: "完成第一场比赛",
                descriptionEn: "Complete your first match",
                icon: "figure.badminton",
                tier: .bronze,
                maxProgress: 1,
                requirement: { $0.totalMatches >= 1 },
                progress: { min($0.totalMatches, 1) }
            ),
            Achievement(
                id: "ten_matches",
                title: "小试牛刀",
                titleEn: "Getting Started",
                description: "完成10场比赛",
                descriptionEn: "Complete 10 matches",
                icon: "star",
                tier: .bronze,
                maxProgress: 10,
                requirement: { $0.totalMatches >= 10 },
                progress: { min($0.totalMatches, 10) }
            ),
            Achievement(
                id: "first_win",
                title: "首胜",
                titleEn: "First Win",
                description: "赢得第1场比赛",
                descriptionEn: "Win your first match",
                icon: "hand.thumbsup.fill",
                tier: .bronze,
                maxProgress: 1,
                requirement: { $0.totalWins >= 1 },
                progress: { min($0.totalWins, 1) }
            ),
            Achievement(
                id: "flash_win",
                title: "闪电战",
                titleEn: "Blitz",
                description: "在10分钟内赢一场",
                descriptionEn: "Win a match in under 10 minutes",
                icon: "bolt.fill",
                tier: .bronze,
                maxProgress: 1,
                requirement: { $0.hasFlashWin },
                progress: { $0.hasFlashWin ? 1 : 0 }
            ),
            Achievement(
                id: "win_streak_3",
                title: "初次连胜",
                titleEn: "First Streak",
                description: "连续赢3场",
                descriptionEn: "Win 3 in a row",
                icon: "flame",
                tier: .bronze,
                maxProgress: 3,
                requirement: { $0.longestWinStreak >= 3 },
                progress: { min($0.longestWinStreak, 3) }
            ),
            Achievement(
                id: "three_opponents",
                title: "新对手",
                titleEn: "New Rivals",
                description: "和3个不同对手交过手",
                descriptionEn: "Play against 3 different opponents",
                icon: "person.2.fill",
                tier: .bronze,
                maxProgress: 3,
                requirement: { $0.uniqueOpponentCount >= 3 },
                progress: { min($0.uniqueOpponentCount, 3) }
            ),
        ]

        // ── Silver (进阶) ──────────────────────────────

        let silver: [Achievement] = [
            Achievement(
                id: "gold_cat",
                title: "金牌橘猫",
                titleEn: "Gold Cat",
                description: "赢得5场比赛",
                descriptionEn: "Win 5 matches",
                icon: "medal.fill",
                tier: .silver,
                maxProgress: 5,
                requirement: { $0.totalWins >= 5 },
                progress: { min($0.totalWins, 5) }
            ),
            Achievement(
                id: "fifty_matches",
                title: "半百征程",
                titleEn: "Half Century",
                description: "完成50场比赛",
                descriptionEn: "Complete 50 matches",
                icon: "flag.checkered",
                tier: .silver,
                maxProgress: 50,
                requirement: { $0.totalMatches >= 50 },
                progress: { min($0.totalMatches, 50) }
            ),
            Achievement(
                id: "comeback_king",
                title: "逆转王",
                titleEn: "Comeback King",
                description: "逆转获胜3次",
                descriptionEn: "Win 3 comeback games",
                icon: "arrow.uturn.up",
                tier: .silver,
                maxProgress: 3,
                requirement: { $0.totalComebacks >= 3 },
                progress: { min($0.totalComebacks, 3) }
            ),
            Achievement(
                id: "deuce_master",
                title: "Deuce 达人",
                titleEn: "Deuce Master",
                description: "经历10次 Deuce",
                descriptionEn: "Experience 10 deuces",
                icon: "equal.circle.fill",
                tier: .silver,
                maxProgress: 10,
                requirement: { $0.totalDeuces >= 10 },
                progress: { min($0.totalDeuces, 10) }
            ),
            Achievement(
                id: "iron_man",
                title: "铁人",
                titleEn: "Iron Man",
                description: "一天内打5场以上",
                descriptionEn: "Play 5+ matches in a single day",
                icon: "bolt.heart.fill",
                tier: .silver,
                maxProgress: 5,
                requirement: { $0.maxMatchesInOneDay >= 5 },
                progress: { min($0.maxMatchesInOneDay, 5) }
            ),
            Achievement(
                id: "win_streak_5",
                title: "连胜高手",
                titleEn: "Streak Master",
                description: "连续赢5场",
                descriptionEn: "Win 5 in a row",
                icon: "flame.fill",
                tier: .silver,
                maxProgress: 5,
                requirement: { $0.longestWinStreak >= 5 },
                progress: { min($0.longestWinStreak, 5) }
            ),
        ]

        // ── Gold (大师) ────────────────────────────────

        let gold: [Achievement] = [
            Achievement(
                id: "legend",
                title: "百场传奇",
                titleEn: "Legend",
                description: "打完100场比赛",
                descriptionEn: "Play 100 matches",
                icon: "crown.fill",
                tier: .gold,
                maxProgress: 100,
                requirement: { $0.totalMatches >= 100 },
                progress: { min($0.totalMatches, 100) }
            ),
            Achievement(
                id: "win_streak_10",
                title: "连胜之王",
                titleEn: "Win Streak King",
                description: "连续赢10场",
                descriptionEn: "Win 10 in a row",
                icon: "trophy.fill",
                tier: .gold,
                maxProgress: 10,
                requirement: { $0.longestWinStreak >= 10 },
                progress: { min($0.longestWinStreak, 10) }
            ),
            Achievement(
                id: "marathon",
                title: "马拉松",
                titleEn: "Marathon",
                description: "单场比赛超过30分钟",
                descriptionEn: "A single match lasting 30+ minutes",
                icon: "clock.fill",
                tier: .gold,
                maxProgress: 1,
                requirement: { $0.hasMarathonMatch },
                progress: { $0.hasMarathonMatch ? 1 : 0 }
            ),
            Achievement(
                id: "weekend_warrior",
                title: "周末战士",
                titleEn: "Weekend Warrior",
                description: "连续4个周末都有打球",
                descriptionEn: "Play on 4 consecutive weekends",
                icon: "calendar.badge.checkmark",
                tier: .gold,
                maxProgress: 4,
                requirement: { $0.consecutiveWeekendsPlayed >= 4 },
                progress: { min($0.consecutiveWeekendsPlayed, 4) }
            ),
            Achievement(
                id: "versatile",
                title: "全能选手",
                titleEn: "Versatile",
                description: "单双打都赢过",
                descriptionEn: "Win both singles and doubles",
                icon: "star.fill",
                tier: .gold,
                maxProgress: 2,
                requirement: { $0.hasSinglesWin && $0.hasDoublesWin },
                progress: { ($0.hasSinglesWin ? 1 : 0) + ($0.hasDoublesWin ? 1 : 0) }
            ),
        ]

        return bronze + silver + gold
    }

    static func evaluate(with store: MatchHistoryStore) -> [Achievement] {
        allAchievements().map { achievement in
            var a = achievement
            a.isUnlocked = achievement.requirement(store)
            a.currentProgress = achievement.progress(store)
            return a
        }
    }
}
