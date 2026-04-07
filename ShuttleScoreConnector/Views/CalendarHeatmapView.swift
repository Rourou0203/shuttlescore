import SwiftUI

struct CalendarHeatmapView: View {
    let records: [MatchRecord]
    @Binding var selectedDate: String?

    @State private var displayedMonth: Date = Date()

    private let calendar = Calendar.current
    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]

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
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy年M月"
        fmt.locale = Locale(identifier: "zh_CN")
        return fmt.string(from: displayedMonth)
    }

    private var daysInMonth: [Date?] {
        let range = calendar.range(of: .day, in: .month, for: displayedMonth)!
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        let firstWeekday = calendar.component(.weekday, from: firstDay) // 1=Sun

        // Leading empty cells
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        // Actual days
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
            // Month nav header
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
                    // Disabled forward button
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

            // Month stats summary
            let stats = monthStats
            if stats.matches > 0 {
                HStack(spacing: 16) {
                    miniStat(value: "\(stats.matches)", label: "场")
                    miniStat(value: "\(stats.wins)", label: "胜")
                    miniStat(value: "\(stats.days)", label: "天")
                }
            }

            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
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
                        let isSelected = selectedDate == key
                        let isFuture = date > Date()

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDate = selectedDate == key ? nil : key
                            }
                        } label: {
                            ZStack {
                                // Background
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(cellBackground(count: count, isSelected: isSelected))
                                    .frame(height: 38)

                                VStack(spacing: 2) {
                                    Text("\(calendar.component(.day, from: date))")
                                        .font(.system(.caption, design: .rounded, weight: isToday ? .bold : .regular))
                                        .foregroundColor(isFuture ? .gray.opacity(0.3) : (isSelected ? .black : .white))

                                    // Match count dots
                                    if count > 0 {
                                        HStack(spacing: 2) {
                                            ForEach(0..<min(count, 3), id: \.self) { _ in
                                                Circle()
                                                    .fill(isSelected ? Color.black.opacity(0.6) : Color.orange)
                                                    .frame(width: 4, height: 4)
                                            }
                                            if count > 3 {
                                                Text("+")
                                                    .font(.system(size: 6))
                                                    .foregroundColor(isSelected ? .black.opacity(0.6) : .orange)
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
                        .disabled(isFuture)
                    } else {
                        // Empty cell
                        Color.clear.frame(height: 38)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func cellBackground(count: Int, isSelected: Bool) -> Color {
        if isSelected { return .orange }
        if count == 0 { return Color.white.opacity(0.04) }
        if count == 1 { return Color.orange.opacity(0.15) }
        if count == 2 { return Color.orange.opacity(0.3) }
        return Color.orange.opacity(0.45)
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
        }
    }

    private func goToNextMonth() {
        if let next = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
            if next <= Date() {
                displayedMonth = next
                selectedDate = nil
            }
        }
    }
}
