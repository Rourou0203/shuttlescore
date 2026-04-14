import Foundation
import SwiftUI

class WatchLanguageManager: ObservableObject {
    static let shared = WatchLanguageManager()

    @Published var currentLanguage: String = "system" {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "app_language")
        }
    }

    private init() {
        self.currentLanguage = UserDefaults.standard.string(forKey: "app_language") ?? "system"
    }

    var language: String {
        if currentLanguage == "system" {
            return Locale.current.language.languageCode?.identifier == "zh" ? "zh" : "en"
        }
        if currentLanguage.contains("zh") { return "zh" }
        return "en"
    }

    // MARK: - Home

    var homeQuickStart: String { language == "zh" ? "快速开始" : "Quick Start" }
    var homeNewMatch: String { language == "zh" ? "新建比赛" : "New Match" }
    var homeContinue: String { language == "zh" ? "继续上场" : "Continue" }
    var homeHistory: String { language == "zh" ? "历史记录" : "History" }
    var homePracticeActive: String { language == "zh" ? "练球进行中" : "Practice On" }
    var homePracticePaused: String { language == "zh" ? "练球暂停中" : "Practice Paused" }
    var homeEndSession: String { language == "zh" ? "结束今日练球" : "End Session" }
    func homeMatchCount(_ n: Int) -> String { language == "zh" ? "\(n)场" : "\(n)M" }

    // MARK: - Match Setup

    var setupTitle: String { language == "zh" ? "赛前设置" : "Match Setup" }
    var setupMatchType: String { language == "zh" ? "类型" : "Type" }
    var setupTeamNames: String { language == "zh" ? "队伍名称" : "Teams" }
    var setupTeamAPlaceholder: String { language == "zh" ? "A队名称" : "Team A" }
    var setupTeamBPlaceholder: String { language == "zh" ? "B队名称" : "Team B" }
    var setupSelectOpponent: String { language == "zh" ? "选择对手" : "Select Opponent" }
    var setupGames: String { language == "zh" ? "局数" : "Games" }
    var setupWinScore: String { language == "zh" ? "胜利分数" : "Win Score" }
    var setupFirstServe: String { language == "zh" ? "先发球方" : "First Serve" }
    var setupSideChange: String { language == "zh" ? "决胜局换边提醒" : "Side Change Alert" }
    var setupVoiceAnnounce: String { language == "zh" ? "语音播报" : "Voice Announce" }
    var setupStartMatch: String { language == "zh" ? "开始比赛" : "Start Match" }
    var setupCustom: String { language == "zh" ? "自定义" : "Custom" }
    var setupMatchTag: String { language == "zh" ? "比赛性质" : "Match Tag" }
    var setupOpponentRecord: String { language == "zh" ? "历史战绩" : "Record" }
    var setupFirstMeeting: String { language == "zh" ? "首次对阵" : "First Match" }

    func formatWins(_ n: Int) -> String { language == "zh" ? "\(n)胜" : "\(n)W" }
    func formatLosses(_ n: Int) -> String { language == "zh" ? "\(n)负" : "\(n)L" }

    func setupGameOption(_ n: Int) -> String {
        if n == 1 { return language == "zh" ? "一局定胜负" : "1 Game" }
        if n == 3 { return language == "zh" ? "三局两胜" : "Best of 3" }
        return language == "zh" ? "五局三胜" : "Best of 5"
    }

    func setupScoreOption(_ s: Int) -> String {
        language == "zh" ? "\(s)分" : "\(s)pts"
    }

    // MARK: - Scoreboard

    var scoreExitTitle: String { language == "zh" ? "退出比赛" : "Exit Match" }
    var scoreContinue: String { language == "zh" ? "继续比赛" : "Continue" }
    var scoreSaveExit: String { language == "zh" ? "保存并退出" : "Save & Exit" }
    var scoreAbandon: String { language == "zh" ? "放弃本场" : "Abandon" }
    var scoreUndo: String { language == "zh" ? "撤销" : "Undo" }

    func scoreUndoMessage(_ name: String) -> String {
        language == "zh" ? "撤销 \(name) 得分" : "Undo \(name) score"
    }

    func scoreNotLastPoint(_ name: String) -> String {
        language == "zh" ? "最后一分不是\(name)得的" : "Last point wasn't \(name)'s"
    }

    func scoreMatchInfo(_ type: String, _ gameNum: Int) -> String {
        language == "zh" ? "\(type) · 第\(gameNum)局" : "\(type) · G\(gameNum)"
    }

    // MARK: - Game Summary

    func gameSummaryWinner(_ name: String, _ gameNum: Int) -> String {
        language == "zh" ? "\(name)赢得第\(gameNum)局" : "\(name) won Game \(gameNum)"
    }

    var gameSummaryChangeSide: String { language == "zh" ? "⇄ 请换边！" : "⇄ Switch Sides!" }

    func gameSummaryNextGame(_ gameNum: Int) -> String {
        language == "zh" ? "开始第\(gameNum)局" : "Start Game \(gameNum)"
    }

    // MARK: - Match Summary

    func matchWinText(_ name: String) -> String {
        language == "zh" ? "\(name)赢了！" : "\(name) Won!"
    }

    func matchElapsedTime(_ minutes: Int) -> String {
        language == "zh" ? "用时 \(minutes) 分钟" : "Time: \(minutes) min"
    }

    var matchNextMatch: String { language == "zh" ? "下一场" : "Next Match" }
    var matchNewMatch: String { language == "zh" ? "新建比赛" : "New Match" }
    var matchEndMatch: String { language == "zh" ? "结束比赛" : "End" }

    // MARK: - Side Change Alert

    var sideChangeMessage: String { language == "zh" ? "请换边！继续加油" : "Switch Sides!" }
    var sideChangeConfirm: String { language == "zh" ? "确认" : "Confirm" }

    // MARK: - Match Detail
    var detailFormat: String { language == "zh" ? "赛制" : "Format" }
    var detailType: String { language == "zh" ? "类型" : "Type" }
    func detailScoreFormat(_ s: Int) -> String { language == "zh" ? "\(s)分制" : "\(s)-pt" }
    func detailGameCount(_ n: Int) -> String { language == "zh" ? "\(n)局" : "\(n)G" }
    var detailGameScores: String { language == "zh" ? "各局比分" : "Game Scores" }
    func detailGameN(_ n: Int) -> String { language == "zh" ? "第\(n)局" : "G\(n)" }
    var detailTime: String { language == "zh" ? "时间" : "Time" }
    var detailStart: String { language == "zh" ? "开始" : "Start" }
    var detailEnd: String { language == "zh" ? "结束" : "End" }
    var detailDuration: String { language == "zh" ? "用时" : "Duration" }
    func detailMinutes(_ n: Int) -> String { language == "zh" ? "\(n)分钟" : "\(n)min" }

    // MARK: - Calendar / History
    var calendarTitle: String { language == "zh" ? "历史记录" : "History" }
    var calendarNoRecords: String { language == "zh" ? "本月暂无记录" : "No matches this month" }
    func calendarMonthLabel(year: Int, month: Int, currentYear: Int) -> String {
        if language == "zh" {
            return year == currentYear ? "\(month)月" : "\(year)年\(month)月"
        } else {
            let names = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
            return year == currentYear ? names[month] : "\(names[month]) \(year)"
        }
    }
    func calendarDateLabel(day: Int, weekday: Int) -> String {
        if language == "zh" {
            let names = ["", "周日", "周一", "周二", "周三", "周四", "周五", "周六"]
            return "\(day)日 \(names[weekday])"
        } else {
            let names = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            return "\(names[weekday]) \(day)"
        }
    }
    func calendarSectionHeader(dateLabel: String, count: Int) -> String {
        language == "zh" ? "\(dateLabel) · \(count)场" : "\(dateLabel) · \(count)"
    }

    var historyTitle: String { language == "zh" ? "今日记录" : "Today" }
    var historyNoRecords: String { language == "zh" ? "今天还没有比赛记录" : "No matches today" }
    func historySummary(count: Int, minutes: Int) -> String {
        language == "zh" ? "共\(count)场 · \(minutes)分钟" : "\(count) matches · \(minutes)min"
    }

    // MARK: - Opponent Picker
    var opponentTitle: String { language == "zh" ? "选择对手" : "Select Opponent" }
    var opponentNew: String { language == "zh" ? "新对手" : "New" }
    var opponentInputPlaceholder: String { language == "zh" ? "输入名字" : "Enter name" }
    var opponentHistory: String { language == "zh" ? "历史对手" : "Past Opponents" }
    var opponentEmpty: String { language == "zh" ? "还没有对手记录，打完比赛后自动保存" : "No opponents yet. Saved after matches." }

    // MARK: - Random Buddy
    var randomBuddy: String { language == "zh" ? "球友" : "Player" }

    // MARK: - Common
    var defaultTeamA: String { language == "zh" ? "我方" : "My Team" }
    var defaultTeamB: String { language == "zh" ? "对手" : "Opponent" }
    var vsText: String { language == "zh" ? "对" : "vs" }
    var drawText: String { language == "zh" ? "未分胜负" : "Draw" }

    // MARK: - Match Types
    var matchTypeSingles: String { language == "zh" ? "单打" : "Singles" }
    var matchTypeMensDoubles: String { language == "zh" ? "男双" : "Men's Doubles" }
    var matchTypeWomensDoubles: String { language == "zh" ? "女双" : "Women's Doubles" }
    var matchTypeMixedDoubles: String { language == "zh" ? "混双" : "Mixed Doubles" }

    func matchTypeDisplayName(_ type: MatchType) -> String {
        switch type {
        case .singles: return matchTypeSingles
        case .mensDoubles: return matchTypeMensDoubles
        case .womensDoubles: return matchTypeWomensDoubles
        case .mixedDoubles: return matchTypeMixedDoubles
        }
    }

    // MARK: - Service Court
    var courtRight: String { language == "zh" ? "右区" : "R" }
    var courtLeft: String { language == "zh" ? "左区" : "L" }

    // MARK: - Milestones

    func milestoneStreak(_ n: Int) -> String? {
        if n >= 10 { return language == "zh" ? "★ \(n)连胜！无人能挡！" : "★ \(n) wins in a row!" }
        if n >= 5 { return language == "zh" ? "★ \(n)连胜！势不可挡！" : "★ \(n)-win streak!" }
        if n >= 3 { return language == "zh" ? "✦ \(n)连胜！继续保持！" : "✦ \(n)-win streak!" }
        return nil
    }

    func milestoneMatch(_ total: Int) -> String? {
        if total == 1 { return language == "zh" ? "✦ 第一场比赛！旅程开始！" : "✦ First match ever!" }
        if total == 10 { return language == "zh" ? "★ 第10场比赛！初露锋芒！" : "★ 10th match!" }
        if total == 50 { return language == "zh" ? "★ 第50场！羽毛球达人！" : "★ 50th match!" }
        if total == 100 { return language == "zh" ? "★ 第100场！传奇之路！" : "★ 100th match!" }
        if total % 50 == 0 { return language == "zh" ? "★ 第\(total)场！里程碑！" : "★ \(total) matches!" }
        return nil
    }
}
