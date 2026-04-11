import SwiftUI

struct HistoryView: View {
    @ObservedObject private var langMgr = WatchLanguageManager.shared
    @State private var records: [MatchRecord] = []

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private var totalMinutes: Int {
        records.reduce(0) { $0 + $1.elapsedMinutes }
    }

    var body: some View {
        List {
            if records.isEmpty {
                Text(langMgr.historyNoRecords)
                    .foregroundStyle(.gray)
            } else {
                Section {
                    Text(langMgr.historySummary(count: records.count, minutes: totalMinutes))
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                ForEach(records) { record in
                    HStack(spacing: 6) {
                        // Winner's cat avatar
                        Image(record.gamesWonByA >= record.gamesWonByB ? "cat_orange" : "cat_robe")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("\(Self.timeFormatter.string(from: record.startTime))-\(Self.timeFormatter.string(from: record.endTime))")
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(langMgr.detailMinutes(record.elapsedMinutes))
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            HStack {
                                Text("\(record.teamAName) \(record.gamesWonByA):\(record.gamesWonByB) \(record.teamBName)")
                                    .font(.system(.footnote, design: .rounded))
                                    .bold()
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle(langMgr.historyTitle)
        .onAppear {
            records = MatchStore.shared.todayRecords()
        }
    }
}
