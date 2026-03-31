import SwiftUI

struct MatchDetailView: View {
    let record: MatchRecord

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
            Section("赛制") {
                row("类型", value: record.matchType.rawValue)
                row("分制", value: "\(record.winningScore)分制")
                row("局数", value: "\(record.gamesWonByA + record.gamesWonByB)局")
            }

            // 每局比分
            Section("各局比分") {
                ForEach(record.gameScores.indices, id: \.self) { i in
                    let g = record.gameScores[i]
                    HStack {
                        Text("第\(i + 1)局")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(g.scoreA) : \(g.scoreB)")
                            .font(.system(.footnote, design: .rounded, weight: .bold))
                    }
                }
            }

            // 时间
            Section("时间") {
                row("开始", value: Self.timeFormatter.string(from: record.startTime))
                row("结束", value: Self.timeFormatter.string(from: record.endTime))
                row("用时", value: "\(record.elapsedMinutes)分钟")
            }
        }
        .navigationTitle("\(record.teamAName) vs \(record.teamBName)")
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
