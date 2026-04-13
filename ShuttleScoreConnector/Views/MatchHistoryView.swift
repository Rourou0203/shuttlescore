import SwiftUI
import Charts

// MARK: - Weekly Trend Data

struct WeeklyTrend: Identifiable {
    let id = UUID()
    let weekLabel: String
    let winRate: Double
    let matchCount: Int
}

// MARK: - Period Type

enum ReportPeriod: String, CaseIterable {
    case day = "day"
    case week = "week"
    case month = "month"

    var localizedName: String {
        let lang = LanguageManager.shared.language
        switch self {
        case .day: return lang == "zh" ? "日" : "D"
        case .week: return lang == "zh" ? "周" : "W"
        case .month: return lang == "zh" ? "月" : "M"
        }
    }
}

// MARK: - Match History View

struct MatchHistoryView: View {
    @StateObject private var store = MatchHistoryStore.shared
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var recordToEdit: MatchRecord?
    @State private var recordToDelete: MatchRecord?
    @State private var showDeleteConfirmation = false
    @State private var selectedDate: String?
    @State private var isEditing = false
    @State private var selectedRecordIds: Set<UUID> = []
    @State private var showBatchDeleteConfirm = false
    @State private var period: ReportPeriod = .day
    @State private var periodDate: Date = Date()
    @State private var showPeriodShareSheet = false

    private var calendar: Calendar { Calendar.current }

    private var dateFmt: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }

    // MARK: - Period date range

    private var currentDateRange: (start: Date, end: Date) {
        switch period {
        case .day:
            let base: Date
            if let ds = selectedDate, let d = dateFmt.date(from: ds) {
                base = d
            } else {
                base = periodDate
            }
            let start = calendar.startOfDay(for: base)
            return (start, start)
        case .week:
            var cal = calendar
            cal.firstWeekday = 2
            let weekday = cal.component(.weekday, from: periodDate)
            let daysToMonday = (weekday + 5) % 7
            let monday = cal.date(byAdding: .day, value: -daysToMonday, to: cal.startOfDay(for: periodDate))!
            let sunday = cal.date(byAdding: .day, value: 6, to: monday)!
            return (monday, sunday)
        case .month:
            let comps = calendar.dateComponents([.year, .month], from: periodDate)
            let firstDay = calendar.date(from: comps)!
            let lastDay = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstDay)!
            return (firstDay, lastDay)
        }
    }

    private var periodFilteredRecords: [MatchRecord] {
        let range = currentDateRange
        return store.records(from: range.start, to: range.end)
    }

    private var periodStats: PeriodStats {
        store.aggregateStats(for: periodFilteredRecords)
    }

    // MARK: - Period title

    private var periodTitle: String {
        switch period {
        case .day:
            let date: Date
            if let ds = selectedDate, let d = dateFmt.date(from: ds) {
                date = d
            } else {
                date = periodDate
            }
            if calendar.isDateInToday(date) { return languageManager.periodToday }
            if calendar.isDateInYesterday(date) { return languageManager.periodYesterday }
            let fmt = DateFormatter()
            if languageManager.language == "zh" {
                fmt.locale = Locale(identifier: "zh_CN")
                fmt.dateFormat = "M月d日 EEEE"
            } else {
                fmt.locale = Locale(identifier: "en_US")
                fmt.dateFormat = "MMM d, EEEE"
            }
            return fmt.string(from: date)
        case .week:
            let range = currentDateRange
            let sf = DateFormatter()
            sf.dateFormat = "M/d"
            let label = languageManager.periodThisWeek
            return "\(label) \(sf.string(from: range.start)) - \(sf.string(from: range.end))"
        case .month:
            return languageManager.formatMonthTitle(periodDate)
        }
    }

    private var shareTitle: String {
        let fmt = DateFormatter()
        if languageManager.language == "zh" {
            fmt.locale = Locale(identifier: "zh_CN")
        } else {
            fmt.locale = Locale(identifier: "en_US")
        }
        switch period {
        case .day:
            let date: Date
            if let ds = selectedDate, let d = dateFmt.date(from: ds) { date = d } else { date = periodDate }
            fmt.dateFormat = languageManager.language == "zh" ? "yyyy年M月d日" : "MMM d, yyyy"
            return "\(fmt.string(from: date)) \(languageManager.periodReport)"
        case .week:
            let range = currentDateRange
            let sf = DateFormatter(); sf.dateFormat = "M/d"
            return "\(sf.string(from: range.start))-\(sf.string(from: range.end)) \(languageManager.periodReport)"
        case .month:
            fmt.dateFormat = languageManager.language == "zh" ? "yyyy年M月" : "MMM yyyy"
            return "\(fmt.string(from: periodDate)) \(languageManager.periodReport)"
        }
    }

    private var canNavigatePeriodForward: Bool {
        let next: Date
        switch period {
        case .day: next = calendar.date(byAdding: .day, value: 1, to: periodDate)!
        case .week: next = calendar.date(byAdding: .weekOfYear, value: 1, to: periodDate)!
        case .month: next = calendar.date(byAdding: .month, value: 1, to: periodDate)!
        }
        return next <= Date()
    }

    private func navigatePeriod(by offset: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            switch period {
            case .day:
                periodDate = calendar.date(byAdding: .day, value: offset, to: periodDate)!
                selectedDate = dateFmt.string(from: periodDate)
            case .week:
                periodDate = calendar.date(byAdding: .weekOfYear, value: offset, to: periodDate)!
            case .month:
                periodDate = calendar.date(byAdding: .month, value: offset, to: periodDate)!
            }
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            Text(languageManager.historyTitle)
                                .font(.system(.title2, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Spacer()
                        }

                        // Simplified 1-row overview (Total, WinRate, Streak)
                        overviewCards

                        // D/W/M period picker
                        Picker(languageManager.periodDimension, selection: $period) {
                            ForEach(ReportPeriod.allCases, id: \.self) { p in
                                Text(p.localizedName).tag(p)
                            }
                        }
                        .pickerStyle(.segmented)

                        // Period navigator (week always; day only when date selected)
                        if period == .week || (period == .day && selectedDate != nil) {
                            periodNavigator
                        }

                        // Calendar heatmap
                        CalendarHeatmapView(
                            records: store.records,
                            selectedDate: $selectedDate,
                            period: period,
                            periodDate: $periodDate
                        )

                        // Period stats (day: only when date selected; week/month: always)
                        if period != .day || selectedDate != nil {
                            periodStatsSection
                        }

                        // Trend charts (win rate + match frequency)
                        trendChartsSection

                        // Match list
                        matchListByDate
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear { store.refresh() }
        .onChange(of: period) { _ in
            withAnimation {
                selectedDate = nil
                periodDate = Date()
            }
            isEditing = false
            selectedRecordIds.removeAll()
        }
        .onChange(of: selectedDate) { newDate in
            if period == .day, let ds = newDate, let d = dateFmt.date(from: ds) {
                periodDate = d
            }
        }
        .sheet(item: $recordToEdit) { record in
            EditScoreSheet(record: record, store: store)
        }
        .sheet(isPresented: $showPeriodShareSheet) {
            let card = PeriodShareCardView(title: shareTitle, stats: periodStats)
            if let image = card.renderImage() {
                ShareSheetView(items: [image])
            }
        }
        .alert(languageManager.historyConfirmDelete, isPresented: $showDeleteConfirmation) {
            Button(languageManager.historyDeleteRecord, role: .destructive) {
                if let record = recordToDelete {
                    withAnimation { store.deleteRecord(id: record.id) }
                }
            }
            Button(languageManager.historyCancel, role: .cancel) {}
        } message: {
            if let record = recordToDelete {
                Text(languageManager.formatDeleteConfirmMessage(teamA: record.teamAName, teamB: record.teamBName))
            }
        }
        .alert(languageManager.historyConfirmDelete, isPresented: $showBatchDeleteConfirm) {
            Button(languageManager.formatDeleteCount(selectedRecordIds.count), role: .destructive) {
                withAnimation {
                    for id in selectedRecordIds { store.deleteRecord(id: id) }
                    selectedRecordIds.removeAll()
                    isEditing = false
                }
            }
            Button(languageManager.historyCancel, role: .cancel) {}
        } message: {
            Text(languageManager.formatBatchDeleteMessage(selectedRecordIds.count))
        }
    }

    // MARK: - Overview Cards (simplified: 1 row of 3)

    private var overviewCards: some View {
        HStack(spacing: 12) {
            StatCard(title: languageManager.historyTotalMatches, value: "\(store.totalMatches)", icon: "sportscourt", color: .orange)
            StatCard(
                title: languageManager.historyWinRate,
                value: store.totalMatches > 0 ? "\(Int(store.winRate * 100))%" : "-",
                icon: "trophy",
                color: .yellow
            )
            StatCard(
                title: languageManager.historyStreak,
                value: store.currentWinStreak > 0 ? "\(store.currentWinStreak)" : "-",
                icon: "flame",
                color: .red
            )
        }
    }

    // MARK: - Period Navigator

    private var periodNavigator: some View {
        HStack {
            Button { navigatePeriod(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(.body, weight: .semibold))
                    .foregroundColor(.orange)
            }
            Spacer()
            Text(periodTitle)
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white)
            Spacer()
            Button { navigatePeriod(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .font(.system(.body, weight: .semibold))
                    .foregroundColor(canNavigatePeriodForward ? .orange : .gray.opacity(0.3))
            }
            .disabled(!canNavigatePeriodForward)
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Period Stats Section

    private var periodStatsSection: some View {
        let stats = periodStats
        return VStack(alignment: .leading, spacing: 12) {
            // Header with share button
            HStack {
                Text(periodTitle)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundColor(.white)
                Spacer()
                Button { showPeriodShareSheet = true } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(.subheadline))
                        .foregroundColor(.orange)
                }
            }

            if stats.totalMatches == 0 {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .foregroundColor(.brandSecondary.opacity(0.4))
                    Text(languageManager.periodNoMatches)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.brandSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                // Row 1: matches / wins / losses
                HStack(spacing: 8) {
                    periodStatPill(value: "\(stats.totalMatches)", label: languageManager.periodMatches, color: .orange)
                    periodStatPill(value: "\(stats.wins)", label: languageManager.periodWins, color: .green)
                    periodStatPill(value: "\(stats.losses)", label: languageManager.periodLosses, color: .red)
                }

                // Row 2: win rate / total time / best streak
                HStack(spacing: 8) {
                    periodStatPill(value: "\(Int(stats.winRate * 100))%", label: languageManager.periodWinRate, color: .yellow)
                    periodStatPill(value: languageManager.formatPeriodMinutes(stats.totalMinutes), label: languageManager.periodTotalTime, color: .cyan)
                    periodStatPill(value: "\(stats.longestWinStreak)", label: languageManager.periodBestStreak, color: .red)
                }

                // Top opponents
                if !stats.topOpponents.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(languageManager.periodTopRivals)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.brandSecondary)
                        ForEach(stats.topOpponents) { opp in
                            HStack {
                                Text(opp.name)
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(opp.wins)\(languageManager.periodWinSuffix)")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.green)
                                Text("\(opp.losses)\(languageManager.periodLossSuffix)")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Weekly Trend Data

    private var weeklyTrendData: [WeeklyTrend] {
        let cal = Calendar.current
        let today = Date()
        let labelFmt = DateFormatter()
        labelFmt.dateFormat = "M/d"

        var trends: [WeeklyTrend] = []

        // Build 8 weeks, from oldest (7 weeks ago) to most recent (this week)
        for weeksAgo in stride(from: 7, through: 0, by: -1) {
            let weekEnd = cal.date(byAdding: .day, value: -(weeksAgo * 7), to: today)!
            let weekStart = cal.date(byAdding: .day, value: -6, to: weekEnd)!
            let startOfWeekStart = cal.startOfDay(for: weekStart)
            let endOfWeekEnd = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: weekEnd))!

            let weekRecords = store.records.filter {
                $0.startTime >= startOfWeekStart && $0.startTime < endOfWeekEnd
            }

            let matchCount = weekRecords.count
            let wins = weekRecords.filter { $0.teamAWon }.count
            let winRate = matchCount > 0 ? Double(wins) / Double(matchCount) * 100.0 : 0

            let label = labelFmt.string(from: weekStart)
            trends.append(WeeklyTrend(weekLabel: label, winRate: winRate, matchCount: matchCount))
        }

        return trends
    }

    // MARK: - Trend Charts Section

    private var trendChartsSection: some View {
        let data = weeklyTrendData
        // Only show charts when at least 2 weeks have match data
        let weeksWithData = data.filter { $0.matchCount > 0 }.count

        return Group {
            if weeksWithData < 2 {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2)
                        .foregroundColor(.brandSecondary.opacity(0.4))
                    Text(languageManager.trendNoData)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.brandSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                VStack(spacing: 16) {
                    // Win Rate Trend (Line Chart)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(languageManager.trendWinRate)
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundColor(.white)

                        Chart(data) { item in
                            LineMark(
                                x: .value("Week", item.weekLabel),
                                y: .value("WinRate", item.winRate)
                            )
                            .foregroundStyle(Color.orange)
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Week", item.weekLabel),
                                y: .value("WinRate", item.winRate)
                            )
                            .foregroundStyle(Color.orange)
                            .symbol(Circle())
                            .symbolSize(30)
                        }
                        .chartYScale(domain: 0...100)
                        .chartYAxis {
                            AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                                    .foregroundStyle(Color.white.opacity(0.1))
                                AxisValueLabel {
                                    if let v = value.as(Int.self) {
                                        Text("\(v)%")
                                            .font(.system(.caption2, design: .rounded))
                                            .foregroundColor(.brandSecondary)
                                    }
                                }
                            }
                        }
                        .chartXAxis {
                            AxisMarks { value in
                                AxisValueLabel {
                                    if let label = value.as(String.self) {
                                        Text(label)
                                            .font(.system(.caption2, design: .rounded))
                                            .foregroundColor(.brandSecondary)
                                    }
                                }
                            }
                        }
                        .frame(height: 180)
                    }

                    // Match Count (Bar Chart)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(languageManager.trendMatchCount)
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundColor(.white)

                        Chart(data) { item in
                            BarMark(
                                x: .value("Week", item.weekLabel),
                                y: .value("Count", item.matchCount)
                            )
                            .foregroundStyle(Color.orange.gradient)
                            .cornerRadius(4)
                        }
                        .chartYAxis {
                            AxisMarks { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                                    .foregroundStyle(Color.white.opacity(0.1))
                                AxisValueLabel {
                                    if let v = value.as(Int.self) {
                                        Text("\(v)")
                                            .font(.system(.caption2, design: .rounded))
                                            .foregroundColor(.brandSecondary)
                                    }
                                }
                            }
                        }
                        .chartXAxis {
                            AxisMarks { value in
                                AxisValueLabel {
                                    if let label = value.as(String.self) {
                                        Text(label)
                                            .font(.system(.caption2, design: .rounded))
                                            .foregroundColor(.brandSecondary)
                                    }
                                }
                            }
                        }
                        .frame(height: 180)
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private func periodStatPill(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundColor(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(.brandSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Match List by Date

    private var filteredRecordsByDate: [(date: String, displayDate: String, records: [MatchRecord])] {
        switch period {
        case .day:
            if let selected = selectedDate {
                return store.recordsByDate.filter { $0.date == selected }
            }
            return store.recordsByDate
        case .week, .month:
            let range = currentDateRange
            let startDay = calendar.startOfDay(for: range.start)
            let endPlusOne = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: range.end))!
            return store.recordsByDate.filter { group in
                guard let date = dateFmt.date(from: group.date) else { return false }
                return date >= startDay && date < endPlusOne
            }
        }
    }

    private var matchListTitle: String {
        switch period {
        case .day:
            return selectedDate != nil ? languageManager.historyToday : languageManager.historyRecords
        case .week:
            return languageManager.periodWeekMatches
        case .month:
            return languageManager.periodMonthMatches
        }
    }

    private var matchListByDate: some View {
        VStack(alignment: .leading, spacing: 16) {
            if store.records.isEmpty {
                emptyState
            } else {
                HStack {
                    Text(matchListTitle)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    if period == .day && selectedDate != nil && !isEditing {
                        Button {
                            withAnimation { selectedDate = nil }
                        } label: {
                            Text(languageManager.historySeeAll)
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.orange)
                        }
                    }

                    Button {
                        withAnimation {
                            isEditing.toggle()
                            if !isEditing { selectedRecordIds.removeAll() }
                        }
                    } label: {
                        Text(isEditing ? languageManager.historyDone : languageManager.historyEdit)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.orange)
                    }
                }

                if period == .day && selectedDate == nil && !isEditing {
                    Text(languageManager.historyLongPressHint)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.brandSecondary.opacity(0.6))
                }

                if filteredRecordsByDate.isEmpty && (selectedDate != nil || period != .day) {
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.title2)
                            .foregroundColor(.brandSecondary.opacity(0.4))
                        Text(languageManager.historyNoMatchesToday)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.brandSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                }

                ForEach(filteredRecordsByDate, id: \.date) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(group.displayDate)
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .foregroundColor(.orange)
                            Spacer()
                            let wins = group.records.filter { $0.teamAWon }.count
                            let total = group.records.count
                            Text(languageManager.formatWinLoss(wins: wins, losses: total - wins))
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.brandSecondary)
                        }

                        ForEach(group.records) { record in
                            if isEditing {
                                HStack(spacing: 12) {
                                    Image(systemName: selectedRecordIds.contains(record.id) ? "checkmark.circle.fill" : "circle")
                                        .font(.system(.title3))
                                        .foregroundColor(selectedRecordIds.contains(record.id) ? .orange : .gray)
                                    MatchRowView(record: record)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        if selectedRecordIds.contains(record.id) {
                                            selectedRecordIds.remove(record.id)
                                        } else {
                                            selectedRecordIds.insert(record.id)
                                        }
                                    }
                                }
                            } else {
                                NavigationLink(destination: MatchDetailView(record: record, allRecords: store.records)) {
                                    MatchRowView(record: record)
                                }
                                .contextMenu {
                                    Button {
                                        recordToEdit = record
                                    } label: {
                                        Label(languageManager.historyEditScore, systemImage: "pencil")
                                    }
                                    Button(role: .destructive) {
                                        recordToDelete = record
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label(languageManager.historyDeleteRecord, systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }

                // Batch action bar in edit mode
                if isEditing {
                    HStack {
                        Button {
                            withAnimation {
                                let allIds = Set(filteredRecordsByDate.flatMap { $0.records.map { $0.id } })
                                if selectedRecordIds.isSuperset(of: allIds) {
                                    selectedRecordIds.removeAll()
                                } else {
                                    selectedRecordIds.formUnion(allIds)
                                }
                            }
                        } label: {
                            let allIds = Set(filteredRecordsByDate.flatMap { $0.records.map { $0.id } })
                            Text(selectedRecordIds.isSuperset(of: allIds) ? languageManager.historyDeselectAll : languageManager.historySelectAll)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.orange)
                        }

                        Spacer()

                        Button {
                            showBatchDeleteConfirm = true
                        } label: {
                            Text(languageManager.formatDeleteCount(selectedRecordIds.count))
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .foregroundColor(selectedRecordIds.isEmpty ? .gray : .red)
                        }
                        .disabled(selectedRecordIds.isEmpty)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            TeamAvatarView(isTeamA: true, size: 120)
                .opacity(0.5)

            Text(languageManager.historyNoRecords)
                .font(.system(.body, design: .rounded))
                .foregroundColor(.brandSecondary)

            Text(languageManager.historyStartFirst)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.brandSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Edit Score Sheet

struct EditScoreSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var languageManager = LanguageManager.shared
    @State var record: MatchRecord
    let store: MatchHistoryStore

    // Editable fields
    @State private var editableGames: [(scoreA: Int, scoreB: Int)] = []
    @State private var teamAName: String = ""
    @State private var teamBName: String = ""
    @State private var matchType: MatchType = .singles
    @State private var matchTag: MatchTag? = nil

    init(record: MatchRecord, store: MatchHistoryStore) {
        self.store = store
        self._record = State(initialValue: record)
        self._editableGames = State(initialValue: record.gameScores.map { ($0.scoreA, $0.scoreB) })
        self._teamAName = State(initialValue: record.teamAName)
        self._teamBName = State(initialValue: record.teamBName)
        self._matchType = State(initialValue: record.matchType)
        self._matchTag = State(initialValue: record.matchTag)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        matchInfoEditor

                        // Editable game scores
                        ForEach(Array(editableGames.indices), id: \.self) { index in
                            VStack(spacing: 8) {
                                Text(languageManager.formatGameNumber(index + 1))
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.brandSecondary)

                                HStack(spacing: 20) {
                                    // Team A score
                                    VStack(spacing: 4) {
                                        Text(record.teamAName)
                                            .font(.system(.caption2, design: .rounded))
                                            .foregroundColor(.orange)

                                        HStack(spacing: 12) {
                                            Button {
                                                if editableGames[index].scoreA > 0 {
                                                    editableGames[index].scoreA -= 1
                                                }
                                            } label: {
                                                Image(systemName: "minus.circle.fill")
                                                    .font(.title2)
                                                    .foregroundColor(.brandSecondary)
                                            }

                                            Text("\(editableGames[index].scoreA)")
                                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                                .frame(minWidth: 44)

                                            Button {
                                                editableGames[index].scoreA += 1
                                            } label: {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.title2)
                                                    .foregroundColor(.orange)
                                            }
                                        }
                                    }

                                    Text(":")
                                        .font(.system(.title2, design: .rounded))
                                        .foregroundColor(.brandSecondary)

                                    // Team B score
                                    VStack(spacing: 4) {
                                        Text(record.teamBName)
                                            .font(.system(.caption2, design: .rounded))
                                            .foregroundColor(.cyan)

                                        HStack(spacing: 12) {
                                            Button {
                                                if editableGames[index].scoreB > 0 {
                                                    editableGames[index].scoreB -= 1
                                                }
                                            } label: {
                                                Image(systemName: "minus.circle.fill")
                                                    .font(.title2)
                                                    .foregroundColor(.brandSecondary)
                                            }

                                            Text("\(editableGames[index].scoreB)")
                                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                                .frame(minWidth: 44)

                                            Button {
                                                editableGames[index].scoreB += 1
                                            } label: {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.title2)
                                                    .foregroundColor(.cyan)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Result preview
                        let gamesA = editableGames.filter { $0.scoreA > $0.scoreB }.count
                        let gamesB = editableGames.filter { $0.scoreB > $0.scoreA }.count
                        let winner = gamesA > gamesB ? record.teamAName : (gamesB > gamesA ? record.teamBName : (languageManager.language == "zh" ? "未分胜负" : "Draw"))

                        VStack(spacing: 4) {
                            Text("\(languageManager.phoneGameScore) \(gamesA) : \(gamesB)")
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .foregroundColor(.white)
                            Text("\(winner)\(languageManager.historyWinSuffix)")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.yellow)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .navigationTitle(languageManager.historyEditScore)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(languageManager.historyCancel) { dismiss() }
                        .foregroundColor(.brandSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(languageManager.historySave) {
                        saveChanges()
                        dismiss()
                    }
                    .foregroundColor(.orange)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    @ObservedObject private var opponentStore = PhoneOpponentStore.shared

    private var matchInfoEditor: some View {
        VStack(spacing: 12) {
            // Team A name
            VStack(alignment: .leading, spacing: 4) {
                Text(languageManager.editMyTeam)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.orange)
                TextField(languageManager.editMyTeam, text: $teamAName)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Team B name with opponent picker
            VStack(alignment: .leading, spacing: 4) {
                Text(languageManager.editOpponent)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.cyan)
                TextField(languageManager.editOpponent, text: $teamBName)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                if !opponentStore.opponents.isEmpty {
                    opponentQuickPicker
                }
            }

            // Match type & tag pickers
            HStack(spacing: 12) {
                Picker(languageManager.editMatchType, selection: $matchType) {
                    ForEach(MatchType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .tint(.orange)

                Picker(languageManager.editMatchTag, selection: $matchTag) {
                    Text(languageManager.editTagNone).tag(MatchTag?.none)
                    ForEach(MatchTag.allCases, id: \.self) { tag in
                        Text(tag.displayName).tag(MatchTag?.some(tag))
                    }
                }
                .pickerStyle(.menu)
                .tint(.orange)

                Spacer()
            }
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var opponentQuickPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(opponentStore.opponents.prefix(10), id: \.self) { name in
                    Button {
                        teamBName = name
                    } label: {
                        Text(name)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(teamBName == name ? .black : .cyan)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(teamBName == name ? Color.cyan : Color.cyan.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func saveChanges() {
        var updatedRecord = record

        // Update team names & match info
        let trimmedA = teamAName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedB = teamBName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedA.isEmpty { updatedRecord.teamAName = trimmedA }
        if !trimmedB.isEmpty { updatedRecord.teamBName = trimmedB }
        updatedRecord.matchType = matchType
        updatedRecord.matchTag = matchTag

        // Update game scores (keep history intact)
        for i in editableGames.indices where i < updatedRecord.gameScores.count {
            updatedRecord.gameScores[i] = GameScore(
                scoreA: editableGames[i].scoreA,
                scoreB: editableGames[i].scoreB,
                history: updatedRecord.gameScores[i].history
            )
        }

        // Recalculate games won
        updatedRecord.gamesWonByA = editableGames.filter { $0.scoreA > $0.scoreB }.count
        updatedRecord.gamesWonByB = editableGames.filter { $0.scoreB > $0.scoreA }.count

        // Update winner based on new team names
        if updatedRecord.gamesWonByA > updatedRecord.gamesWonByB {
            updatedRecord.winnerName = updatedRecord.teamAName
        } else if updatedRecord.gamesWonByB > updatedRecord.gamesWonByA {
            updatedRecord.winnerName = updatedRecord.teamBName
        } else {
            updatedRecord.winnerName = languageManager.language == "zh" ? "未分胜负" : "Draw"
        }

        store.updateRecord(updatedRecord)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(.title2, design: .rounded))
                .foregroundColor(color)

            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundColor(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(title)
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(.brandSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Match Row

struct MatchRowView: View {
    let record: MatchRecord
    @ObservedObject private var languageManager = LanguageManager.shared

    // MARK: - Quick stats helpers

    /// 我方发球得分率（0~1），nil 表示无数据
    private var serveWinRate: Double? {
        var servePoints = 0
        var totalServes = 0
        for game in record.gameScores {
            guard game.history.count >= 2 else { continue }
            for i in 1..<game.history.count {
                let prev = game.history[i - 1]
                let curr = game.history[i]
                if prev.servingTeamIsA {
                    totalServes += 1
                    if curr.scoreA > prev.scoreA { servePoints += 1 }
                }
            }
        }
        guard totalServes > 0 else { return nil }
        return Double(servePoints) / Double(totalServes)
    }

    /// 我方最长连分
    private var myLongestRun: Int {
        record.longestRunA
    }

    /// 是否有发球数据
    private var hasServingData: Bool {
        record.gameScores.contains { $0.history.count >= 2 }
    }

    /// 每局比分的文字描述，例如 "21:18 / 15:21 / 21:19"
    private var gameByGameText: String {
        record.gameScores.map { "\($0.scoreA):\($0.scoreB)" }.joined(separator: " / ")
    }

    var body: some View {
        HStack(spacing: 12) {
            // Cat avatar: custom/orange for win, robe for loss
            TeamAvatarView(isTeamA: record.teamAWon, size: 50)

            VStack(alignment: .leading, spacing: 4) {
                // Row 1: win/loss dot + names + match format (+ tag)
                HStack(spacing: 6) {
                    Circle()
                        .fill(record.teamAWon ? Color.green : Color.red)
                        .frame(width: 8, height: 8)

                    Text(record.teamAName)
                        .foregroundColor(record.teamAWon ? .orange : .white)
                    Text("vs")
                        .foregroundColor(.brandSecondary)
                    Text(record.teamBName)
                        .foregroundColor(record.teamAWon ? .white : .cyan)

                    Spacer()

                    // 赛制 + 标签
                    HStack(spacing: 4) {
                        Text(languageManager.formatMatchFormat(record.totalGames))
                        if let tag = record.matchTag {
                            Text("·")
                            Text(tag.displayName)
                        }
                        if !record.isCompleted {
                            Text("·")
                            Text(languageManager.historyUnfinished)
                                .foregroundColor(.red)
                        }
                    }
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.brandSecondary)
                }
                .font(.system(.subheadline, design: .rounded, weight: .medium))

                // Row 2: main score
                if record.totalGames == 1, let game = record.gameScores.first {
                    // 单局：显示局内比分
                    Text("\(game.scoreA) : \(game.scoreB)")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    // 多局：显示局数比分
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(record.gamesWonByA) : \(record.gamesWonByB)")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundColor(.white)
                        // 每局比分明细
                        Text(gameByGameText)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.brandSecondary)
                    }
                }

                // Row 3: stats line
                HStack(spacing: 0) {
                    if let rate = serveWinRate {
                        Text("\(languageManager.rowServeLabel) \(Int(rate * 100))%")
                    }
                    if myLongestRun > 0 {
                        if serveWinRate != nil {
                            Text(" · ")
                        }
                        Text("\(languageManager.rowRunLabel) \(myLongestRun)")
                    }
                    if serveWinRate != nil || myLongestRun > 0 {
                        Text(" · ")
                    }
                    Text(languageManager.formatElapsedMinutes(record.elapsedMinutes))
                }
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.brandSecondary.opacity(0.5))
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Score Chart Data Point

/// Data point for the score progression chart (defined at file level for Swift Charts compatibility)
struct ScoreChartPoint: Identifiable {
    let id = UUID()
    let rally: Int
    let score: Int
    let team: String
}

// MARK: - Match Detail View

struct MatchDetailView: View {
    let record: MatchRecord
    var allRecords: [MatchRecord] = []
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var showShareSheet = false

    var body: some View {
        ZStack {
            Color.brandBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    winnerBanner
                    matchInfoChips
                    gameByGameSection
                    scoreProgressionSection
                    analysisSection
                    dateSection

                    // Share button
                    Button(action: { showShareSheet = true }) {
                        Label(languageManager.historyShare, systemImage: "square.and.arrow.up")
                            .font(.system(.body, design: .rounded))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .padding(.top, 10)
                }
                .padding()
            }
        }
        .navigationTitle(languageManager.historyMatchDetail)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showShareSheet) {
            if let image = ShareCardView(record: record).renderImage() {
                ShareSheetView(items: [image])
            }
        }
    }

    // MARK: - Winner Banner

    private var winnerBanner: some View {
        VStack(spacing: 8) {
            TeamAvatarView(isTeamA: record.teamAWon, size: 80)
                .overlay(
                    Circle().stroke(Color.yellow, lineWidth: 3)
                )

            if record.isCompleted {
                Text(record.winnerName + languageManager.historyWinSuffix)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundColor(.yellow)
            } else {
                Text(languageManager.historyUnfinished)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundColor(.red)
            }

            Text("\(record.gamesWonByA) : \(record.gamesWonByB)")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.top, 10)
    }

    // MARK: - Info Chips

    private var matchInfoChips: some View {
        HStack(spacing: 20) {
            infoChip(icon: "clock", text: languageManager.formatElapsedMinutes(record.elapsedMinutes))
            infoChip(icon: "sportscourt", text: record.matchType.rawValue)
            infoChip(icon: "target", text: languageManager.formatPointSystem(record.winningScore))
        }
    }

    // MARK: - Game by Game

    private var gameByGameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(languageManager.historyGameScores)
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white)

            ForEach(Array(record.gameScores.enumerated()), id: \.offset) { index, game in
                VStack(spacing: 0) {
                    HStack {
                        Text(languageManager.formatGameNumber(index + 1))
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.brandSecondary)

                        Spacer()

                        Text("\(game.scoreA)")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundColor(game.scoreA > game.scoreB ? .orange : .white)

                        Text(":")
                            .font(.system(.title3, design: .rounded))
                            .foregroundColor(.brandSecondary)

                        Text("\(game.scoreB)")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundColor(game.scoreB > game.scoreA ? .cyan : .white)

                        // 多局时显示赢/输标记
                        if record.totalGames > 1 {
                            Text(game.scoreA > game.scoreB ? "✅" : "❌")
                                .font(.system(.caption, design: .rounded))
                        }
                    }
                    .padding()

                    // Score progression mini chart if history available
                    if !game.history.isEmpty {
                        scoreProgressionChart(game: game)
                            .frame(height: 40)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    }
                }
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Score Progression Section (Charts)

    private var scoreProgressionSection: some View {
        let hasAnyHistory = record.gameScores.contains { !$0.history.isEmpty }

        return VStack(alignment: .leading, spacing: 12) {
            Text(languageManager.scoreProgression)
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white)

            if hasAnyHistory {
                ForEach(Array(record.gameScores.enumerated()), id: \.offset) { index, game in
                    if !game.history.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            if record.totalGames > 1 {
                                Text(languageManager.formatGameNumber(index + 1))
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.brandSecondary)
                            }

                            chartForGame(game)
                                .frame(height: 160)

                            // Legend
                            HStack(spacing: 16) {
                                HStack(spacing: 4) {
                                    Circle().fill(Color.orange).frame(width: 8, height: 8)
                                    Text(record.teamAName)
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundColor(.orange)
                                }
                                HStack(spacing: 4) {
                                    Circle().fill(Color.cyan).frame(width: 8, height: 8)
                                    Text(record.teamBName)
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundColor(.cyan)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            } else {
                Text(languageManager.noDetailData)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.brandSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    /// Build a SwiftUI Chart for one game's score history
    private func chartForGame(_ game: GameScore) -> some View {
        // history snapshots are pre-point states; add final score as last point
        var points: [ScoreChartPoint] = []
        for (i, snap) in game.history.enumerated() {
            points.append(ScoreChartPoint(rally: i, score: snap.scoreA, team: record.teamAName))
            points.append(ScoreChartPoint(rally: i, score: snap.scoreB, team: record.teamBName))
        }
        // Append final score
        let lastRally = game.history.count
        points.append(ScoreChartPoint(rally: lastRally, score: game.scoreA, team: record.teamAName))
        points.append(ScoreChartPoint(rally: lastRally, score: game.scoreB, team: record.teamBName))

        return Chart(points) { point in
            LineMark(
                x: .value("Rally", point.rally),
                y: .value("Score", point.score)
            )
            .foregroundStyle(by: .value("Team", point.team))
            .interpolationMethod(.stepEnd)
        }
        .chartForegroundStyleScale([
            record.teamAName: Color.orange,
            record.teamBName: Color.cyan
        ])
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                    .foregroundStyle(Color.white.opacity(0.2))
                AxisValueLabel()
                    .foregroundStyle(Color.gray)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                    .foregroundStyle(Color.white.opacity(0.2))
                AxisValueLabel()
                    .foregroundStyle(Color.gray)
            }
        }
        .chartLegend(.hidden)
    }

    // MARK: - Analysis Section

    private var analysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(languageManager.historyAnalytics)
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white)

            if record.totalGames == 1 {
                // 单局：只显示最长连分，隐藏 Deuce 和逆转
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    analysisCard(title: languageManager.historyMyBestRun, value: "\(record.longestRunA)", color: .orange)
                    analysisCard(title: languageManager.historyOppBestRun, value: "\(record.longestRunB)", color: .cyan)
                }
            } else {
                // 多局：显示完整分析，含 Deuce 和逆转
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    analysisCard(title: languageManager.historyMyBestRun, value: "\(record.longestRunA)", color: .orange)
                    analysisCard(title: languageManager.historyOppBestRun, value: "\(record.longestRunB)", color: .cyan)
                    analysisCard(title: languageManager.historyDeuceCount, value: "\(record.totalDeuces)", color: .yellow)
                    analysisCard(title: languageManager.historyComebackGames, value: "\(record.comebackGames)", color: .green)
                }
            }

            // Serving stats if available
            if hasServingData {
                let (servePointsA, servePointsB, totalServeA, totalServeB) = servingStats
                VStack(alignment: .leading, spacing: 8) {
                    Text(languageManager.historyServePoints)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.brandSecondary)

                    HStack(spacing: 20) {
                        VStack {
                            Text(record.teamAName)
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.orange)
                            Text("\(servePointsA)/\(totalServeA)")
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundColor(.white)
                            if totalServeA > 0 {
                                let rateA = Double(servePointsA) / Double(totalServeA)
                                HStack(spacing: 2) {
                                    Text("\(Int(rateA * 100))%")
                                        .font(.system(.caption2, design: .rounded))
                                        .foregroundColor(.brandSecondary)
                                    if let avg = avgServeWinRate {
                                        if rateA > avg {
                                            Text("↑")
                                                .font(.system(.caption2, design: .rounded))
                                                .foregroundColor(.green)
                                        } else if rateA < avg {
                                            Text("↓")
                                                .font(.system(.caption2, design: .rounded))
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)

                        VStack {
                            Text(record.teamBName)
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.cyan)
                            Text("\(servePointsB)/\(totalServeB)")
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundColor(.white)
                            if totalServeB > 0 {
                                Text("\(Int(Double(servePointsB) / Double(totalServeB) * 100))%")
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundColor(.brandSecondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Date Section

    private var dateSection: some View {
        VStack(spacing: 4) {
            Text(languageManager.historyMatchTime)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.brandSecondary)
            Text(record.startTime, format: .dateTime.year().month().day().hour().minute())
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.top, 10)
    }

    // MARK: - Helpers

    private func infoChip(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(.caption, design: .rounded))
            Text(text)
                .font(.system(.caption, design: .rounded))
        }
        .foregroundColor(.white.opacity(0.8))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.1))
        .clipShape(Capsule())
    }

    private func analysisCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundColor(color)
            Text(title)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.brandSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Score Progression Chart

    private func scoreProgressionChart(game: GameScore) -> some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let count = game.history.count
            guard count > 1 else { return AnyView(EmptyView()) }

            let maxScore = max(Double(game.scoreA), Double(game.scoreB), 1.0)
            let stepX = width / Double(count - 1)

            return AnyView(
                ZStack {
                    // Team A line (orange)
                    Path { path in
                        for (i, snap) in game.history.enumerated() {
                            let x = Double(i) * stepX
                            let y = height - (Double(snap.scoreA) / maxScore) * height
                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color.orange, lineWidth: 1.5)

                    // Team B line (cyan)
                    Path { path in
                        for (i, snap) in game.history.enumerated() {
                            let x = Double(i) * stepX
                            let y = height - (Double(snap.scoreB) / maxScore) * height
                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color.cyan, lineWidth: 1.5)
                }
            )
        }
    }

    // MARK: - Average serve win rate across all records

    /// 所有历史记录的我方平均发球得分率（仅含有发球数据的场次）
    private var avgServeWinRate: Double? {
        var rates: [Double] = []
        for rec in allRecords {
            var sp = 0; var ts = 0
            for game in rec.gameScores {
                guard game.history.count >= 2 else { continue }
                for i in 1..<game.history.count {
                    let prev = game.history[i - 1]
                    let curr = game.history[i]
                    if prev.servingTeamIsA {
                        ts += 1
                        if curr.scoreA > prev.scoreA { sp += 1 }
                    }
                }
            }
            if ts > 0 { rates.append(Double(sp) / Double(ts)) }
        }
        guard !rates.isEmpty else { return nil }
        return rates.reduce(0, +) / Double(rates.count)
    }

    /// 本场我方发球得分率
    private var thisMatchServeWinRate: Double? {
        let (sp, _, ts, _) = servingStats
        guard ts > 0 else { return nil }
        return Double(sp) / Double(ts)
    }

    // MARK: - Serving Stats

    private var hasServingData: Bool {
        record.gameScores.contains { game in
            game.history.count >= 2
        }
    }

    private var servingStats: (Int, Int, Int, Int) {
        var servePointsA = 0
        var servePointsB = 0
        var totalServeA = 0
        var totalServeB = 0

        for game in record.gameScores {
            guard game.history.count >= 2 else { continue }
            for i in 1..<game.history.count {
                let prev = game.history[i - 1]
                let curr = game.history[i]
                let teamAScored = curr.scoreA > prev.scoreA

                if prev.servingTeamIsA {
                    totalServeA += 1
                    if teamAScored { servePointsA += 1 }
                } else {
                    totalServeB += 1
                    if !teamAScored { servePointsB += 1 }
                }
            }
        }

        return (servePointsA, servePointsB, totalServeA, totalServeB)
    }
}

#Preview {
    MatchHistoryView()
        .preferredColorScheme(.dark)
}
