import SwiftUI

struct MatchHistoryView: View {
    @StateObject private var store = MatchHistoryStore.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        statsCards
                        matchList
                    }
                    .padding()
                }
            }
            .navigationTitle("历史统计")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear { store.refresh() }
        }
    }

    // MARK: - Stats Cards

    private var statsCards: some View {
        HStack(spacing: 12) {
            StatCard(title: "总场次", value: "\(store.totalMatches)", icon: "sportscourt", color: .orange)
            StatCard(
                title: "胜率",
                value: store.totalMatches > 0 ? "\(Int(store.winRate * 100))%" : "-",
                icon: "trophy",
                color: .yellow
            )
            StatCard(
                title: "总时长",
                value: formatMinutes(store.totalMinutes),
                icon: "clock",
                color: .cyan
            )
        }
    }

    // MARK: - Match List

    private var matchList: some View {
        VStack(alignment: .leading, spacing: 12) {
            if store.records.isEmpty {
                emptyState
            } else {
                Text("比赛记录")
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.white)

                ForEach(store.records) { record in
                    NavigationLink(destination: MatchDetailView(record: record)) {
                        MatchRowView(record: record)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image("cat_orange")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .opacity(0.5)

            Text("还没有比赛记录")
                .font(.system(.body, design: .rounded))
                .foregroundColor(.gray)

            Text("在 Apple Watch 上开始你的第一场比赛吧")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)分"
        }
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours)时\(mins)分"
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
                .font(.system(.title3, design: .rounded))
                .foregroundColor(color)

            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundColor(.white)

            Text(title)
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Match Row

struct MatchRowView: View {
    let record: MatchRecord

    var body: some View {
        HStack(spacing: 12) {
            // Winner cat avatar
            Image(record.teamAWon ? "cat_orange" : "cat_robe")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(record.teamAName)
                        .foregroundColor(record.teamAWon ? .orange : .white)
                    Text("vs")
                        .foregroundColor(.gray)
                    Text(record.teamBName)
                        .foregroundColor(record.teamAWon ? .white : .cyan)
                }
                .font(.system(.subheadline, design: .rounded, weight: .medium))

                HStack(spacing: 8) {
                    Text(record.startTime, style: .date)
                    Text("\(record.elapsedMinutes)分钟")
                }
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.gray)
            }

            Spacer()

            // Score
            VStack(spacing: 2) {
                Text("\(record.gamesWonByA) : \(record.gamesWonByB)")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                Text("局")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.gray)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Match Detail

struct MatchDetailView: View {
    let record: MatchRecord

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Winner banner
                    VStack(spacing: 8) {
                        Image(record.teamAWon ? "cat_orange" : "cat_robe")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.yellow, lineWidth: 3)
                            )

                        Text(record.winnerName + " 胜")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundColor(.yellow)

                        Text("\(record.gamesWonByA) : \(record.gamesWonByB)")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 10)

                    // Match info
                    HStack(spacing: 20) {
                        infoChip(icon: "clock", text: "\(record.elapsedMinutes) 分钟")
                        infoChip(icon: "sportscourt", text: record.matchType.rawValue)
                        infoChip(icon: "target", text: "\(record.winningScore) 分制")
                    }

                    // Game-by-game scores
                    VStack(alignment: .leading, spacing: 12) {
                        Text("每局比分")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.white)

                        ForEach(Array(record.gameScores.enumerated()), id: \.offset) { index, game in
                            HStack {
                                Text("第 \(index + 1) 局")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.gray)

                                Spacer()

                                Text("\(game.scoreA)")
                                    .font(.system(.title3, design: .rounded, weight: .bold))
                                    .foregroundColor(game.scoreA > game.scoreB ? .orange : .white)

                                Text(":")
                                    .font(.system(.title3, design: .rounded))
                                    .foregroundColor(.gray)

                                Text("\(game.scoreB)")
                                    .font(.system(.title3, design: .rounded, weight: .bold))
                                    .foregroundColor(game.scoreB > game.scoreA ? .cyan : .white)
                            }
                            .padding()
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    // Date
                    VStack(spacing: 4) {
                        Text("比赛时间")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.gray)
                        Text(record.startTime, format: .dateTime.year().month().day().hour().minute())
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 10)
                }
                .padding()
            }
        }
        .navigationTitle("比赛详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

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
}

#Preview {
    MatchHistoryView()
        .preferredColorScheme(.dark)
}
