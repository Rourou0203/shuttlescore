import Foundation
import SwiftUI

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @Published var currentLanguage: String = "system" {
        didSet {
            ProfileStore.shared.appLanguage = currentLanguage
            PhoneSessionManager.shared.sendLanguageSetting(currentLanguage)
        }
    }

    private init() {
        self.currentLanguage = ProfileStore.shared.appLanguage
    }

    var language: String {
        if currentLanguage == "system" {
            return Locale.current.language.languageCode?.identifier == "zh" ? "zh" : "en"
        }
        // Handle zh-Hans -> zh
        if currentLanguage.contains("zh") {
            return "zh"
        }
        return "en"
    }

    // MARK: - Tab Bar
    var tabLiveScore: String { language == "zh" ? "实时比分" : "Live Score" }
    var tabHistory: String { language == "zh" ? "历史统计" : "History" }
    var tabAchievements: String { language == "zh" ? "成就" : "Achievements" }
    var tabOpponents: String { language == "zh" ? "对手" : "Opponents" }
    var tabProfile: String { language == "zh" ? "我的" : "Profile" }

    // MARK: - Profile
    var profileTitle: String { language == "zh" ? "我的" : "Profile" }
    var profileFavoriteCat: String { language == "zh" ? "本命猫" : "Favorite Cat" }
    var profileMoreData: String { language == "zh" ? "更多数据" : "More Data" }
    var profileResetAvatar: String { language == "zh" ? "恢复本命猫头像" : "Reset Avatar" }
    var profileEditName: String { language == "zh" ? "修改昵称" : "Edit Name" }
    var profileAlertTitle: String { language == "zh" ? "修改昵称" : "Change Name" }
    var profileAlertMessage: String { language == "zh" ? "给自己取个响亮的名字吧" : "Give yourself a cool name" }
    var profileCancel: String { language == "zh" ? "取消" : "Cancel" }
    var profileConfirm: String { language == "zh" ? "确定" : "Confirm" }

    var profileStatWinRate: String { language == "zh" ? "胜率" : "Win Rate" }
    var profileStatMatches: String { language == "zh" ? "比赛数" : "Matches" }
    var profileStatDuration: String { language == "zh" ? "总时长" : "Duration" }

    var profileLongestWinStreak: String { language == "zh" ? "最长连胜" : "Win Streak" }
    var profileTotalWins: String { language == "zh" ? "总胜场" : "Total Wins" }
    var profileTotalMatches: String { language == "zh" ? "总比赛" : "Total Matches" }

    // MARK: - Live Score
    var liveWaitingForWatch: String { language == "zh" ? "等待手表连接..." : "Waiting for Watch..." }
    var livePleaseStartOnWatch: String { language == "zh" ? "请在 Apple Watch 上开始比赛" : "Start a match on Apple Watch" }
    var liveNoWatch: String { language == "zh" ? "没有 Apple Watch?" : "No Apple Watch?" }
    var livePhoneScore: String { language == "zh" ? "手机计分" : "Phone Scoring" }
    var liveGameScore: String { language == "zh" ? "局分" : "Games" }
    var liveGameNumber: String { language == "zh" ? "第" : "Game " }
    var liveMatchEnded: String { language == "zh" ? "比赛结束" : "Match Ended" }
    var liveGameEnded: String { language == "zh" ? "本局结束" : "Game Over" }
    var liveMatchTerminated: String { language == "zh" ? "比赛已中止" : "Match Terminated" }
    var liveMatchOver: String { language == "zh" ? "比赛已结束" : "Match Over" }
    var liveWaitingStart: String { language == "zh" ? "等待开始比赛" : "Waiting to Start" }
    var liveNewMatch: String { language == "zh" ? "新建比赛" : "New Match" }
    var liveDefaultTeamA: String { language == "zh" ? "我方" : "Us" }
    var liveDefaultTeamB: String { language == "zh" ? "对手" : "Them" }

    // MARK: - Settings
    var settingsTitle: String { language == "zh" ? "设置" : "Settings" }
    var settingsLanguage: String { language == "zh" ? "语言" : "Language" }
    var settingsFollowSystem: String { language == "zh" ? "跟随系统" : "Follow System" }
    var settingsChinese: String { language == "zh" ? "中文" : "中文" }
    var settingsEnglish: String { language == "zh" ? "English" : "English" }

    // MARK: - History
    var historyTitle: String { language == "zh" ? "历史统计" : "History" }
    var historyPeriodReport: String { language == "zh" ? "战绩报告" : "Report" }
    var historyDaily: String { language == "zh" ? "日" : "Daily" }
    var historyWeekly: String { language == "zh" ? "周" : "Weekly" }
    var historyMonthly: String { language == "zh" ? "月" : "Monthly" }
    var historyTotalMatches: String { language == "zh" ? "总场次" : "Matches" }
    var historyWinRate: String { language == "zh" ? "胜率" : "Win Rate" }
    var historyWinLoss: String { language == "zh" ? "胜/负" : "W/L" }
    var historyStreak: String { language == "zh" ? "连胜" : "Streak" }
    var historyDuration: String { language == "zh" ? "总时长" : "Duration" }
    var historyWeeklyAvg: String { language == "zh" ? "周均" : "Weekly Avg" }
    var historyRecords: String { language == "zh" ? "比赛记录" : "Records" }
    var historyToday: String { language == "zh" ? "当日记录" : "Today" }
    var historySeeAll: String { language == "zh" ? "查看全部" : "See All" }
    var historyDone: String { language == "zh" ? "完成" : "Done" }
    var historyEdit: String { language == "zh" ? "编辑" : "Edit" }
    var historyLongPressHint: String { language == "zh" ? "长按记录可编辑或删除" : "Long press to edit or delete" }
    var historyNoMatchesToday: String { language == "zh" ? "当天没有比赛记录" : "No matches today" }
    var historyNoRecords: String { language == "zh" ? "还没有比赛记录" : "No records yet" }
    var historyStartFirst: String { language == "zh" ? "在 Apple Watch 上开始你的第一场比赛吧" : "Start your first match on Apple Watch" }
    var historyEditScore: String { language == "zh" ? "编辑比赛" : "Edit Match" }
    var editMyTeam: String { language == "zh" ? "我方" : "My Team" }
    var editOpponent: String { language == "zh" ? "对手" : "Opponent" }
    var editMatchType: String { language == "zh" ? "类型" : "Type" }
    var editMatchTag: String { language == "zh" ? "标签" : "Tag" }
    var editTagNone: String { language == "zh" ? "无" : "None" }
    var historyDeleteRecord: String { language == "zh" ? "删除记录" : "Delete" }
    var historyDeselectAll: String { language == "zh" ? "取消全选" : "Deselect All" }
    var historySelectAll: String { language == "zh" ? "全选" : "Select All" }
    var historyCancel: String { language == "zh" ? "取消" : "Cancel" }
    var historyConfirmDelete: String { language == "zh" ? "确认删除" : "Confirm Delete" }
    var historySave: String { language == "zh" ? "保存" : "Save" }
    var historyShare: String { language == "zh" ? "分享战绩" : "Share" }
    var historyMatchDetail: String { language == "zh" ? "比赛详情" : "Match Detail" }
    var historyGameScores: String { language == "zh" ? "每局比分" : "Game Scores" }
    var historyAnalytics: String { language == "zh" ? "数据分析" : "Analytics" }
    var scoreProgression: String { language == "zh" ? "比分走势" : "Score Progression" }
    var noDetailData: String { language == "zh" ? "无详细数据" : "No detailed data" }
    var historyMyBestRun: String { language == "zh" ? "我方最长连分" : "My Best Run" }
    var historyOppBestRun: String { language == "zh" ? "对方最长连分" : "Opp Best Run" }
    var historyDeuceCount: String { language == "zh" ? "Deuce 次数" : "Deuce Count" }
    var historyComebackGames: String { language == "zh" ? "逆转局数" : "Comeback Games" }
    var historyServePoints: String { language == "zh" ? "发球得分" : "Serve Points" }
    var historyMatchTime: String { language == "zh" ? "比赛时间" : "Match Time" }
    var historyUnfinished: String { language == "zh" ? "未完赛" : "Unfinished" }
    var historyWinSuffix: String { language == "zh" ? " 胜" : " Win" }
    var historyGameLabel: String { language == "zh" ? "局" : "G" }

    // MARK: - Match Row (redesigned)
    var rowServeLabel: String { language == "zh" ? "发球" : "Serve" }
    var rowRunLabel: String { language == "zh" ? "连分" : "Run" }

    func formatMatchFormat(_ totalGames: Int) -> String {
        switch totalGames {
        case 1: return language == "zh" ? "单局" : "Single"
        case 3: return language == "zh" ? "三局两胜" : "Bo3"
        case 5: return language == "zh" ? "五局三胜" : "Bo5"
        default: return language == "zh" ? "\(totalGames)局" : "Bo\(totalGames)"
        }
    }
    var historyMinutes: String { language == "zh" ? "分钟" : "min" }
    var historyHour: String { language == "zh" ? "时" : "h" }
    var historyMin: String { language == "zh" ? "分" : "m" }
    var historyMatchesUnit: String { language == "zh" ? "场" : "" }

    func formatMinutesLocalized(_ minutes: Int) -> String {
        if minutes < 60 {
            return language == "zh" ? "\(minutes)分" : "\(minutes)m"
        }
        let hours = minutes / 60
        let mins = minutes % 60
        return language == "zh" ? "\(hours)时\(mins)分" : "\(hours)h\(mins)m"
    }

    func formatAvgMatches(_ avg: Double) -> String {
        language == "zh" ? String(format: "%.1f场", avg) : String(format: "%.1f", avg)
    }

    func formatWinLoss(wins: Int, losses: Int) -> String {
        language == "zh" ? "\(wins)胜\(losses)负" : "\(wins)W\(losses)L"
    }

    func formatElapsedMinutes(_ minutes: Int) -> String {
        language == "zh" ? "\(minutes)分钟" : "\(minutes)min"
    }

    func formatMatchCount(_ count: Int) -> String {
        language == "zh" ? "\(count)场" : "\(count)"
    }

    func formatGameNumber(_ n: Int) -> String {
        language == "zh" ? "第 \(n) 局" : "Game \(n)"
    }

    func formatPointSystem(_ score: Int) -> String {
        language == "zh" ? "\(score) 分制" : "\(score) pts"
    }

    func formatDeleteCount(_ count: Int) -> String {
        language == "zh" ? "删除\(count)条记录" : "Delete \(count)"
    }

    func formatBatchDeleteMessage(_ count: Int) -> String {
        language == "zh" ? "确定要删除选中的\(count)条比赛记录吗？此操作不可撤销。" : "Delete \(count) selected records? This cannot be undone."
    }

    func formatDeleteConfirmMessage(teamA: String, teamB: String) -> String {
        language == "zh" ? "确定要删除 \(teamA) vs \(teamB) 的比赛记录吗？" : "Delete the match \(teamA) vs \(teamB)?"
    }

    func formatTotalMatches(_ count: Int) -> String {
        language == "zh" ? "共 \(count) 场比赛" : "\(count) matches total"
    }

    // MARK: - Opponents
    var opponentsTitle: String { language == "zh" ? "对手战绩" : "Opponents" }
    var opponentsStats: String { language == "zh" ? "对阵数据" : "Stats" }
    var opponentsWins: String { language == "zh" ? "胜" : "Wins" }
    var opponentsLosses: String { language == "zh" ? "负" : "Losses" }
    var opponentsEnterName: String { language == "zh" ? "输入对手名称" : "Enter name" }
    var opponentsAdd: String { language == "zh" ? "添加" : "Add" }
    var opponentsSaved: String { language == "zh" ? "已保存对手" : "Saved" }
    var opponentsCount: String { language == "zh" ? "对手数" : "Count" }
    var opponentsTopRival: String { language == "zh" ? "最常对战" : "Top Rival" }
    var opponentsRecent: String { language == "zh" ? "近期" : "Recent" }
    var opponentsW: String { language == "zh" ? "胜" : "W" }
    var opponentsL: String { language == "zh" ? "负" : "L" }
    var opponentsNoRecords: String { language == "zh" ? "还没有对手记录" : "No opponents yet" }
    var opponentsPlayToSee: String { language == "zh" ? "完成比赛后这里会显示对手战绩" : "Play matches to see opponent stats" }

    func formatOpponentWinRate(_ rate: Double) -> String {
        language == "zh" ? "胜率 \(Int(rate * 100))%" : "WR \(Int(rate * 100))%"
    }

    // MARK: - Opponent Sorting
    var opponentSortByMatches: String { language == "zh" ? "按场次" : "By Matches" }
    var opponentSortByWinRate: String { language == "zh" ? "按胜率" : "By Win Rate" }
    var opponentSortByRecent: String { language == "zh" ? "按最近" : "By Recent" }

    // MARK: - Random Buddy
    var randomBuddy: String { language == "zh" ? "球友" : "Player" }

    // MARK: - Radar Chart
    var radarWinRate: String { language == "zh" ? "胜率" : "Win Rate" }
    var radarDuration: String { language == "zh" ? "用时" : "Duration" }
    var radarComeback: String { language == "zh" ? "逆转" : "Comeback" }
    var radarDeuce: String { language == "zh" ? "Deuce" : "Deuce" }
    var radarBestRun: String { language == "zh" ? "连得" : "Best Run" }

    // MARK: - ELO Rating
    var eloRating: String { language == "zh" ? "实力分" : "Rating" }
    var eloBronze: String { language == "zh" ? "铜" : "Bronze" }
    var eloSilver: String { language == "zh" ? "银" : "Silver" }
    var eloGold: String { language == "zh" ? "金" : "Gold" }
    var eloPlatinum: String { language == "zh" ? "铂金" : "Platinum" }
    var eloDiamond: String { language == "zh" ? "钻石" : "Diamond" }

    // MARK: - Achievements
    var achievementsTitle: String { language == "zh" ? "成就" : "Achievements" }
    var achievementsUnlocked: String { language == "zh" ? "已解锁成就" : "Unlocked" }
    var achievementBronze: String { language == "zh" ? "铜牌" : "Bronze" }
    var achievementSilver: String { language == "zh" ? "银牌" : "Silver" }
    var achievementGold: String { language == "zh" ? "金牌" : "Gold" }

    // MARK: - Period Report
    var periodDimension: String { language == "zh" ? "时间维度" : "Period" }
    var periodShare: String { language == "zh" ? "分享战绩" : "Share" }
    var periodReport: String { language == "zh" ? "战绩报告" : "Report" }
    var periodMatches: String { language == "zh" ? "总场次" : "Matches" }
    var periodWins: String { language == "zh" ? "胜场" : "Wins" }
    var periodLosses: String { language == "zh" ? "负场" : "Losses" }
    var periodBestStreak: String { language == "zh" ? "最长连胜" : "Best Streak" }
    var periodDeuces: String { language == "zh" ? "Deuce 次数" : "Deuces" }
    var periodWinRate: String { language == "zh" ? "胜率" : "Win Rate" }
    var periodTotalTime: String { language == "zh" ? "总用时" : "Total Time" }
    var periodComebacks: String { language == "zh" ? "逆转局数" : "Comebacks" }
    var periodBestRun: String { language == "zh" ? "最佳连分" : "Best Run" }
    var periodTopRivals: String { language == "zh" ? "常交手对手" : "Top Rivals" }
    var periodNoMatches: String { language == "zh" ? "该时段内没有比赛记录" : "No matches in this period" }
    var periodPlayOnWatch: String { language == "zh" ? "去 Apple Watch 上打一场吧" : "Play a match on Apple Watch" }
    var periodDay: String { language == "zh" ? "日" : "D" }
    var periodWeek: String { language == "zh" ? "周" : "W" }
    var periodMonth: String { language == "zh" ? "月" : "M" }
    var periodToday: String { language == "zh" ? "今天" : "Today" }
    var periodYesterday: String { language == "zh" ? "昨天" : "Yesterday" }
    var periodThisWeek: String { language == "zh" ? "本周" : "This week" }
    var periodWeekMatches: String { language == "zh" ? "本周比赛" : "This Week" }
    var periodMonthMatches: String { language == "zh" ? "本月比赛" : "This Month" }
    var periodWinSuffix: String { language == "zh" ? "胜" : "W" }
    var periodLossSuffix: String { language == "zh" ? "负" : "L" }

    // MARK: - Trend Charts
    var trendWinRate: String { language == "zh" ? "胜率趋势" : "Win Rate Trend" }
    var trendMatchCount: String { language == "zh" ? "比赛场次" : "Match Count" }
    var trendNoData: String { language == "zh" ? "数据不足，至少需要2周记录" : "Not enough data, need at least 2 weeks" }
    var trendMatches: String { language == "zh" ? "场" : "" }

    func formatPeriodMinutes(_ minutes: Int) -> String {
        if minutes < 60 { return language == "zh" ? "\(minutes)分钟" : "\(minutes)min" }
        let hours = minutes / 60
        let mins = minutes % 60
        return language == "zh" ? "\(hours)时\(mins)分" : "\(hours)h\(mins)m"
    }

    // MARK: - Phone Scoreboard
    var phoneContinue: String { language == "zh" ? "继续比赛" : "Continue" }
    var phoneSaveExit: String { language == "zh" ? "保存并退出" : "Save & Exit" }
    var phoneAbandon: String { language == "zh" ? "放弃本场" : "Abandon" }
    var phoneServe: String { language == "zh" ? "发球" : "Serve" }
    var phoneUndo: String { language == "zh" ? "撤销" : "Undo" }
    var phoneNextGame: String { language == "zh" ? "下一局" : "Next Game" }
    var phoneSaveBack: String { language == "zh" ? "保存并返回" : "Save & Back" }
    var phoneExitMatch: String { language == "zh" ? "退出比赛" : "Exit Match" }
    var phoneGameEnd: String { language == "zh" ? "局结束" : " Over" }
    var phoneWins: String { language == "zh" ? "获胜!" : "Wins!" }
    var phoneGameScore: String { language == "zh" ? "局分" : "Games" }
    var phoneMinutes: String { language == "zh" ? "分钟" : "min" }
    var phoneUpDown: String { language == "zh" ? "↑加分  ↓撤销" : "↑Score ↓Undo" }
    var phoneUsedTime: String { language == "zh" ? "用时" : "Time" }

    func formatPhoneGameEnd(_ n: Int) -> String {
        language == "zh" ? "第\(n)局结束" : "Game \(n) Over"
    }

    func formatPhoneGameInfo(_ type: String, _ gameNum: Int) -> String {
        language == "zh" ? "\(type) · 第\(gameNum)局" : "\(type) · Game \(gameNum)"
    }

    func formatPhoneServing(_ name: String) -> String {
        language == "zh" ? "\(name)发球" : "\(name) serves"
    }

    // MARK: - Phone Setup
    var setupTitle: String { language == "zh" ? "赛前设置" : "Match Setup" }
    var setupMatchType: String { language == "zh" ? "比赛类型" : "Match Type" }
    var setupTeamNames: String { language == "zh" ? "队伍名称" : "Team Names" }
    var setupQuickSelect: String { language == "zh" ? "快速选择对手" : "Quick Select" }
    var setupGames: String { language == "zh" ? "局数" : "Games" }
    var setupWinScore: String { language == "zh" ? "胜利分数" : "Win Score" }
    var setupFirstServe: String { language == "zh" ? "先发球方" : "First Serve" }
    var setupStartMatch: String { language == "zh" ? "开始比赛" : "Start Match" }
    var setupCancel: String { language == "zh" ? "取消" : "Cancel" }

    func formatGameOption(_ n: Int) -> String {
        if n == 1 {
            return language == "zh" ? "1局" : "1 game"
        }
        return language == "zh" ? "\(n)局\(n/2+1)胜" : "Bo\(n)"
    }

    func formatScoreOption(_ s: Int) -> String {
        language == "zh" ? "\(s)分" : "\(s)pts"
    }

    // MARK: - Calendar Heatmap
    var calendarWeekdays: [String] {
        language == "zh" ? ["日", "一", "二", "三", "四", "五", "六"] : ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
    }
    var calendarMatches: String { language == "zh" ? "场" : "M" }
    var calendarWins: String { language == "zh" ? "胜" : "W" }
    var calendarDays: String { language == "zh" ? "天" : "D" }

    func formatMonthTitle(_ date: Date) -> String {
        let fmt = DateFormatter()
        if language == "zh" {
            fmt.dateFormat = "yyyy年M月"
            fmt.locale = Locale(identifier: "zh_CN")
        } else {
            fmt.dateFormat = "MMM yyyy"
            fmt.locale = Locale(identifier: "en_US")
        }
        return fmt.string(from: date)
    }
}
