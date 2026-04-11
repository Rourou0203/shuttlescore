import SwiftUI

struct MatchDetailView: View {
    let record: MatchRecord
    @ObservedObject private var langMgr = WatchLanguageManager.shared

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        List {
            // 胜者
            Section {
                HStack {
                    Text("🏆")
                    Text(record.winnerName)
                        .font(.system(.body, design: .rounded))
                        .bold()
                        .foregroundStyle(.yellow)
                }
            }

            // 比赛信息
            Section(langMgr.detailFormat) {
                row(langMgr.detailType, value: record.matchType.displayName)
                row(langMgr.setupWinScore, value: langMgr.detailScoreFormat(record.winningScore))
                row(langMgr.setupGames, value: langMgr.detailGameCount(record.gamesWonByA + record.gamesWonByB))
            }

            // 每局比分
            Section(langMgr.detailGameScores) {
                ForEach(record.gameScores.indices, id: \.self) { i in
                    let g = record.gameScores[i]
                    HStack {
                        Text(langMgr.detailGameN(i + 1))
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(g.scoreA) : \(g.scoreB)")
                            .font(.system(.footnote, design: .rounded, weight: .bold))
                    }
                }
            }

            // 时间
            Section(langMgr.detailTime) {
                row(langMgr.detailStart, value: Self.timeFormatter.string(from: record.startTime))
                row(langMgr.detailEnd, value: Self.timeFormatter.string(from: record.endTime))
                row(langMgr.detailDuration, value: langMgr.detailMinutes(record.elapsedMinutes))
            }
        }
        .navigationTitle("\(record.teamAName) \(langMgr.vsText) \(record.teamBName)")
    }

    private func row(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.footnote, design: .rounded))
        }
    }
}
