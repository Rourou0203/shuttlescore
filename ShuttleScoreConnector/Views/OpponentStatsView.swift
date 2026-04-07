import SwiftUI

// MARK: - Data Model

struct OpponentStat: Identifiable {
    var id: String { opponentName }
    var opponentName: String
    var totalMatches: Int
    var wins: Int
    var losses: Int
    var winRate: Double
    var recentResults: [Bool]  // last 5 results (true = win)
    var lastPlayedDate: Date
    var matchRecords: [MatchRecord]
}

// MARK: - Opponent Stats View

struct OpponentStatsView: View {
    @StateObject private var store = MatchHistoryStore.shared
    @StateObject private var opponentStore = PhoneOpponentStore.shared
    @State private var expandedOpponent: String?
    @State private var newOpponentName: String = ""

    private var opponentStats: [OpponentStat] {
        let grouped = Dictionary(grouping: store.records) { $0.teamBName }

        return grouped.map { name, records in
            let wins = records.filter { $0.teamAWon }.count
            let losses = records.count - wins
            let winRate = records.isEmpty ? 0 : Double(wins) / Double(records.count)

            // Sort by time descending for recent results
            let sorted = records.sorted { $0.startTime > $1.startTime }
            let recent = Array(sorted.prefix(5).map { $0.teamAWon })

            return OpponentStat(
                opponentName: name,
                totalMatches: records.count,
                wins: wins,
                losses: losses,
                winRate: winRate,
                recentResults: recent,
                lastPlayedDate: sorted.first?.startTime ?? Date(),
                matchRecords: sorted
            )
        }
        .sorted { $0.totalMatches > $1.totalMatches }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        Text("对手战绩")
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // MARK: - Add opponent
                        VStack(spacing: 10) {
                            HStack(spacing: 10) {
                                TextField("输入对手名称", text: $newOpponentName)
                                    .textFieldStyle(.plain)
                                    .font(.system(.body, design: .rounded))
                                    .padding(10)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .foregroundColor(.white)

                                Button(action: {
                                    opponentStore.add(newOpponentName)
                                    newOpponentName = ""
                                }) {
                                    Text("添加")
                                        .font(.system(.subheadline, design: .rounded))
                                        .fontWeight(.medium)
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(Color.orange)
                                        .clipShape(Capsule())
                                }
                                .disabled(newOpponentName.trimmingCharacters(in: .whitespaces).isEmpty)
                                .opacity(newOpponentName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                            }

                            // Saved opponents list (manageable)
                            if !opponentStore.opponents.isEmpty {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("已保存对手")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundColor(.gray)
                                        .padding(.bottom, 6)

                                    ForEach(Array(opponentStore.opponents.enumerated()), id: \.offset) { index, name in
                                        HStack {
                                            Image(systemName: "person.fill")
                                                .font(.caption)
                                                .foregroundColor(.cyan.opacity(0.7))
                                            Text(name)
                                                .font(.system(.subheadline, design: .rounded))
                                                .foregroundColor(.white)
                                            Spacer()
                                            Button(action: {
                                                withAnimation { opponentStore.remove(at: index) }
                                            }) {
                                                Image(systemName: "trash")
                                                    .font(.caption)
                                                    .foregroundColor(.red.opacity(0.7))
                                            }
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        if index < opponentStore.opponents.count - 1 {
                                            Divider().background(Color.gray.opacity(0.2))
                                        }
                                    }
                                }
                                .background(Color.white.opacity(0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .padding(.vertical, 4)

                        if opponentStats.isEmpty {
                            emptyState
                        } else {
                            // Summary
                            HStack(spacing: 12) {
                                StatCard(
                                    title: "对手数",
                                    value: "\(opponentStats.count)",
                                    icon: "person.2",
                                    color: .cyan
                                )
                                StatCard(
                                    title: "最常对战",
                                    value: opponentStats.first?.opponentName ?? "-",
                                    icon: "flame",
                                    color: .orange
                                )
                            }

                            // Opponent list
                            ForEach(opponentStats) { stat in
                                VStack(spacing: 0) {
                                    opponentRow(stat: stat)
                                        .onTapGesture {
                                            withAnimation(.easeInOut(duration: 0.25)) {
                                                if expandedOpponent == stat.opponentName {
                                                    expandedOpponent = nil
                                                } else {
                                                    expandedOpponent = stat.opponentName
                                                }
                                            }
                                        }

                                    if expandedOpponent == stat.opponentName {
                                        opponentDetail(stat: stat)
                                            .transition(.opacity.combined(with: .move(edge: .top)))
                                    }
                                }
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear { store.refresh() }
    }

    // MARK: - Opponent Row

    private func opponentRow(stat: OpponentStat) -> some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(stat.opponentName)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.white)

                    Text("\(stat.totalMatches)场")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray)
                }

                Spacer()

                // Win/Loss numbers
                HStack(spacing: 4) {
                    Text("\(stat.wins)")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundColor(.green)
                    Text(":")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.gray)
                    Text("\(stat.losses)")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundColor(.red)
                }

                Image(systemName: expandedOpponent == stat.opponentName ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.5))
                    .padding(.leading, 4)
            }

            // Win rate progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background (loss portion)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.red.opacity(0.3))
                        .frame(height: 6)

                    // Win portion
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green)
                        .frame(width: geo.size.width * stat.winRate, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding()
    }

    // MARK: - Opponent Detail (expanded)

    private func opponentDetail(stat: OpponentStat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider().background(Color.gray.opacity(0.3))

            // Fun comment
            Text(funComment(for: stat))
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.yellow)
                .padding(.horizontal, 16)

            // Recent 5 results
            HStack(spacing: 6) {
                Text("近期")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.gray)

                ForEach(Array(stat.recentResults.enumerated()), id: \.offset) { _, won in
                    Circle()
                        .fill(won ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                }

                Spacer()

                Text("胜率 \(Int(stat.winRate * 100))%")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundColor(stat.winRate >= 0.5 ? .green : .red)
            }
            .padding(.horizontal, 16)

            // Recent match records (last 5)
            ForEach(Array(stat.matchRecords.prefix(5))) { record in
                NavigationLink(destination: MatchDetailView(record: record)) {
                    HStack {
                        Circle()
                            .fill(record.teamAWon ? Color.green : Color.red)
                            .frame(width: 6, height: 6)

                        Text(record.startTime, format: .dateTime.month().day())
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.gray)

                        Spacer()

                        Text("\(record.gamesWonByA) : \(record.gamesWonByB)")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundColor(.white)

                        Text(record.teamAWon ? "胜" : "负")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundColor(record.teamAWon ? .green : .red)

                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundColor(.gray.opacity(0.4))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                }
            }

            if stat.matchRecords.count > 5 {
                Text("共 \(stat.matchRecords.count) 场比赛")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.gray.opacity(0.6))
                    .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 12)
    }

    // MARK: - Fun Comment

    private func funComment(for stat: OpponentStat) -> String {
        let name = stat.opponentName
        let rate = stat.winRate

        if rate >= 0.8 {
            return "你是\(name)的克星！\u{1F3F8}"
        } else if rate >= 0.6 {
            return "对\(name)保持优势 \u{1F4AA}"
        } else if rate == 0.5 {
            return "势均力敌的对手 \u{2694}\u{FE0F}"
        } else if rate >= 0.3 {
            return "\(name)实力不俗 \u{1F525}"
        } else {
            return "总有一天会赢ta！加油 \u{1F431}"
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.4))

            Text("还没有对手记录")
                .font(.system(.body, design: .rounded))
                .foregroundColor(.gray)

            Text("完成比赛后这里会显示对手战绩")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview {
    OpponentStatsView()
        .preferredColorScheme(.dark)
}
