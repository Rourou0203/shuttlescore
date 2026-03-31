import SwiftUI

struct CalendarView: View {
    @State private var selectedMonth: Date = Calendar.current.startOfMonth(for: Date())
    @State private var allRecords: [MatchRecord] = []

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private static let calendar = Calendar.current

    // 当前月的记录，按日期分组降序
    private var groupedRecords: [(date: Date, records: [MatchRecord])] {
        let monthRecords = allRecords.filter {
            Self.calendar.isDate($0.startTime, equalTo: selectedMonth, toGranularity: .month)
        }
        let grouped = Dictionary(grouping: monthRecords) {
            Self.calendar.startOfDay(for: $0.startTime)
        }
        return grouped.sorted { $0.key > $1.key }.map { (date: $0.key, records: $0.value) }
    }

    private var monthLabel: String {
        let cal = Self.calendar
        let year = cal.component(.year, from: selectedMonth)
        let month = cal.component(.month, from: selectedMonth)
        let currentYear = cal.component(.year, from: Date())
        return year == currentYear ? "\(month)月" : "\(year)年\(month)月"
    }

    private var canGoForward: Bool {
        selectedMonth < Calendar.current.startOfMonth(for: Date())
    }

    private func changeMonth(by offset: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: offset, to: selectedMonth) {
            selectedMonth = newMonth
        }
    }

    var body: some View {
        List {
            // 月份导航
            Section {
                HStack {
                    Button(action: { changeMonth(by: -1) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(.footnote, weight: .bold))
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text(monthLabel)
                        .font(.system(.body, design: .rounded, weight: .semibold))

                    Spacer()

                    Button(action: { changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right")
                            .font(.system(.footnote, weight: .bold))
                            .foregroundStyle(canGoForward ? .blue : .gray)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canGoForward)
                }
                .padding(.vertical, 2)
            }

            // 记录列表
            if groupedRecords.isEmpty {
                VStack(spacing: 6) {
                    Text("本月暂无记录")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .listRowBackground(Color.clear)
            } else {
                ForEach(groupedRecords, id: \.date) { group in
                    Section(header: sectionHeader(date: group.date, count: group.records.count)) {
                        ForEach(group.records) { record in
                            NavigationLink(destination: MatchDetailView(record: record)) {
                                recordRow(record)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("历史记录")
        .onAppear {
            allRecords = MatchStore.shared.loadHistory()
        }
    }

    // MARK: - Section Header

    private func sectionHeader(date: Date, count: Int) -> some View {
        Text("\(dateLabel(date)) · \(count)场")
            .font(.system(.caption2, design: .rounded))
            .foregroundStyle(.secondary)
    }

    private func dateLabel(_ date: Date) -> String {
        let cal = Self.calendar
        let day = cal.component(.day, from: date)
        let weekday = cal.component(.weekday, from: date)
        let weekdayNames = ["", "周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        return "\(day)日 \(weekdayNames[weekday])"
    }

    // MARK: - Record Row

    private func recordRow(_ record: MatchRecord) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("\(Self.timeFormatter.string(from: record.startTime))-\(Self.timeFormatter.string(from: record.endTime))")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(record.elapsedMinutes)分钟")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("\(record.teamAName) \(record.gamesWonByA):\(record.gamesWonByB) \(record.teamBName)")
                    .font(.system(.footnote, design: .rounded))
                    .bold()
                Spacer()
                Text(record.winnerName)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Calendar extension

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}
