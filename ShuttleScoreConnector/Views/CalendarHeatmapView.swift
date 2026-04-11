import SwiftUI

struct CalendarHeatmapView: View {
    let records: [MatchRecord]
    @Binding var selectedDate: String?
    var period: ReportPeriod = .day
    @Binding var periodDate: Date
    @ObservedObject private var languageManager = LanguageManager.shared

    @State private var displayedMonth: Date = Date()

    private let calendar = Calendar.current

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }

    private var matchCountByDate: [String: Int] {
        var result: [String: Int] = [:]
        let fmt = dateFormatter
        for record in records {
            let key = fmt.string(from: record.startTime)
            result[key, default: 0] += 1
        }
        return result
    }

    // MARK: - Month info

    private var monthTitle: String {
        languageManager.formatMonthTitle(displayedMonth)
    }

    private var daysInMonth: [Date?] {
        let range = calendar.range(of: .day, in: .month, for: displayedMonth)!
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        let firstWeekday = calendar.component(.weekday, from: firstDay) // 1=Sun

        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }

    private var isCurrentMonth: Bool {
        calendar.isDate(displayedMonth, equalTo: Date(), toGranularity: .month)
    }

    // MARK: - Week range helper

    private func weekRange(for date: Date) -> (start: Date, end: Date) {
        var cal = calendar
        cal.firstWeekday = 2
        let weekday = cal.component(.weekday, from: date)
        let daysToMonday = (weekday + 5) % 7
        let monday = cal.date(byAdding: .day, value: -daysToMonday, to: cal.startOfDay(for: date))!
        let sunday = cal.date(byAdding: .day, value: 6, to: monday)!
        return (monday, sunday)
    }

    private func isInCurrentWeek(_ date: Date) -> Bool {
        guard period == .week else { return false }
        let range = weekRange(for: periodDate)
        let dayStart = calendar.startOfDay(for: date)
        return dayStart >= range.start && dayStart <= range.end
    }

    // MARK: - Stats for displayed month

    private var monthStats: (matches: Int, wins: Int, days: Int) {
        let fmt = dateFormatter
        let comp = calendar.dateComponents([.year, .month], from: displayedMonth)
        var matches = 0, wins = 0, activeDays = Set<String>()

        for record in records {
            let rc = calendar.dateComponents([.year, .month], from: record.startTime)
            if rc.year == comp.year && rc.month == comp.month {
                matches += 1
                if record.teamAWon { wins += 1 }
                activeDays.insert(fmt.string(from: record.startTime))
            }
        }
        return (matches, wins, activeDays.count)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Month nav header — hidden in week mode (parent handles navigation)
            if period != .week {
                HStack {
                    Button {
                        withAnimation { goToPreviousMonth() }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.orange)
                    }

                    Spacer()

                    Text(monthTitle)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    if isCurrentMonth {
                        Image(systemName: "chevron.right")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.gray.opacity(0.3))
                    } else {
                        Button {
                            withAnimation { goToNextMonth() }
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.orange)
                        }
                    }
                }
            }

            // Month stats summary (day mode only, to avoid duplication with period stats section)
            if period == .day {
                let stats = monthStats
                if stats.matches > 0 {
                    HStack(spacing: 16) {
                        miniStat(value: "\(stats.matches)", label: languageManager.calendarMatches)
                        miniStat(value: "\(stats.wins)", label: languageManager.calendarWins)
                        miniStat(value: "\(stats.days)", label: languageManager.calendarDays)
                    }
                }
            }

            // Weekday headers
            HStack(spacing: 0) {
                ForEach(languageManager.calendarWeekdays, id: \.self) { day in
                    Text(day)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.gray.opacity(0.6))
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        let key = dateFormatter.string(from: date)
                        let count = matchCountByDate[key] ?? 0
                        let isToday = calendar.isDateInToday(date)
                        let isSelected = period == .day && selectedDate == key
                        let isWeekHighlight = isInCurrentWeek(date)
                        let isFuture = date > Date()
                        let isMonthMode = period == .month

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                switch period {
                                case .day:
                                    selectedDate = selectedDate == key ? nil : key
                                case .week:
                                    periodDate = date
                                case .month:
                                    break
                                }
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(cellBackground(count: count, isSelected: isSelected, isWeekHighlight: isWeekHighlight))
                                    .frame(height: 38)

                                VStack(spacing: 2) {
                                    Text("\(calendar.component(.day, from: date))")
                                        .font(.system(.caption, design: .rounded, weight: isToday ? .bold : .regular))
                                        .foregroundColor(cellTextColor(isFuture: isFuture, isSelected: isSelected, isWeekHighlight: isWeekHighlight, isMonthMode: isMonthMode))

                                    if count > 0 {
                                        HStack(spacing: 2) {
                                            ForEach(0..<min(count, 3), id: \.self) { _ in
                                                Circle()
                                                    .fill(dotColor(isSelected: isSelected, isWeekHighlight: isWeekHighlight))
                                                    .frame(width: 4, height: 4)
                                            }
                                            if count > 3 {
                                                Text("+")
                                                    .font(.system(size: 6))
                                                    .foregroundColor(dotColor(isSelected: isSelected, isWeekHighlight: isWeekHighlight))
                                            }
                                        }
                                    }
                                }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isToday ? Color.orange : Color.clear, lineWidth: 2)
                            )
                        }
                        .disabled(isFuture || isMonthMode)
                    } else {
                        Color.clear.frame(height: 38)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            syncDisplayedMonth()
        }
        .onChange(of: period) { _ in
            syncDisplayedMonth()
        }
        .onChange(of: periodDate) { _ in
            if period == .week || period == .month {
                withAnimation { syncDisplayedMonth() }
            }
        }
    }

    // MARK: - Helpers

    private func syncDisplayedMonth() {
        if period == .week || period == .month {
            displayedMonth = periodDate
        }
    }

    private func cellBackground(count: Int, isSelected: Bool, isWeekHighlight: Bool) -> Color {
        if isSelected { return .orange }
        if isWeekHighlight { return Color.orange.opacity(0.18) }
        if count == 0 { return Color.white.opacity(0.04) }
        if count == 1 { return Color.orange.opacity(0.15) }
        if count == 2 { return Color.orange.opacity(0.3) }
        return Color.orange.opacity(0.45)
    }

    private func cellTextColor(isFuture: Bool, isSelected: Bool, isWeekHighlight: Bool, isMonthMode: Bool) -> Color {
        if isFuture { return .gray.opacity(0.3) }
        if isSelected { return .black }
        return .white
    }

    private func dotColor(isSelected: Bool, isWeekHighlight: Bool) -> Color {
        if isSelected { return Color.black.opacity(0.6) }
        return Color.orange
    }

    private func miniStat(value: String, label: String) -> some View {
        HStack(spacing: 2) {
            Text(value)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundColor(.orange)
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(.gray)
        }
    }

    private func goToPreviousMonth() {
        if let prev = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
            displayedMonth = prev
            selectedDate = nil
            if period == .month {
                periodDate = prev
            }
        }
    }

    private func goToNextMonth() {
        if let next = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
            if next <= Date() {
                displayedMonth = next
                selectedDate = nil
                if period == .month {
                    periodDate = next
                }
            }
        }
    }
}
