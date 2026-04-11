import SwiftUI

// MARK: - Period Share Card View

struct PeriodShareCardView: View {
    let title: String
    let stats: PeriodStats
    private let languageManager = LanguageManager.shared
    private let eloManager = ELOManager.shared

    private var isZh: Bool { languageManager.language == "zh" }

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.10, green: 0.10, blue: 0.13), Color(red: 0.06, green: 0.06, blue: 0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )

            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.top, 24)

                Spacer().frame(height: 20)

                // Win/Loss + Progress bar
                winLossSection

                Spacer().frame(height: 20)

                // Stats chips
                statsSection

                Spacer().frame(height: 16)

                // Top opponents
                if !stats.topOpponents.isEmpty {
                    opponentsSection
                    Spacer().frame(height: 16)
                }

                // Footer
                footerSection
                    .padding(.bottom, 20)
            }
        }
        .frame(width: 400, height: stats.topOpponents.isEmpty ? 360 : 420)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            HStack(spacing: 6) {
                Text("🏸")
                    .font(.system(size: 14))
                Text("ShuttleScore")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundColor(.orange)
            }

            Spacer()

            Text(isZh ? "战绩报告" : "Match Report")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Win/Loss

    private var winLossSection: some View {
        VStack(spacing: 12) {
            // Period title
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundColor(.white)

            // Big W/L numbers
            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("\(stats.wins)")
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundColor(.green)
                    Text(isZh ? "胜" : "W")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundColor(.green.opacity(0.7))
                }

                VStack(spacing: 2) {
                    Text("\(stats.losses)")
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundColor(.red.opacity(0.8))
                    Text(isZh ? "负" : "L")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundColor(.red.opacity(0.6))
                }
            }

            // Win rate progress bar
            VStack(spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.red.opacity(0.25))
                            .frame(height: 8)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * stats.winRate, height: 8)
                    }
                }
                .frame(height: 8)
                .padding(.horizontal, 60)

                Text("\(Int(stats.winRate * 100))%")
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 0) {
            statChip(
                icon: "clock",
                value: formatMinutes(stats.totalMinutes),
                label: isZh ? "用时" : "Time",
                color: .cyan
            )
            statChip(
                icon: "flame.fill",
                value: "\(stats.longestWinStreak)",
                label: isZh ? "最佳连胜" : "Best Streak",
                color: .red
            )
            statChip(
                icon: "arrow.left.arrow.right",
                value: "\(stats.totalDeuces)",
                label: "Deuce",
                color: .yellow
            )
            statChip(
                icon: "arrow.uturn.up",
                value: "\(stats.comebackGames)",
                label: isZh ? "逆转" : "Comeback",
                color: .green
            )
        }
        .padding(.horizontal, 16)
    }

    private func statChip(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color.opacity(0.8))
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundColor(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(.gray)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Opponents

    private var opponentsSection: some View {
        VStack(spacing: 8) {
            Text(isZh ? "主要对手" : "Top Rivals")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundColor(.gray)

            HStack(spacing: 20) {
                ForEach(stats.topOpponents) { opp in
                    VStack(spacing: 3) {
                        Text(opp.name)
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        HStack(spacing: 4) {
                            Text("\(opp.wins)")
                                .foregroundColor(.green)
                            Text("-")
                                .foregroundColor(.gray)
                            Text("\(opp.losses)")
                                .foregroundColor(.red)
                        }
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                    }
                }
            }
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 8) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
                .padding(.horizontal, 24)

            HStack {
                // ELO badge
                let rating = eloManager.myRating
                HStack(spacing: 4) {
                    Image(systemName: eloManager.tierIcon(for: rating))
                        .font(.system(size: 10))
                        .foregroundColor(eloManager.tierColor(for: rating))
                    Text(eloManager.ratingTier(for: rating))
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                        .foregroundColor(eloManager.tierColor(for: rating))
                    Text("·")
                        .foregroundColor(.gray.opacity(0.4))
                    Text("\(rating)")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.gray.opacity(0.6))
                }

                Spacer()

                Text("🐱 ShuttleScore")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.gray.opacity(0.6))
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Helpers

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes)" + (isZh ? "分" : "m") }
        let hours = minutes / 60
        let mins = minutes % 60
        if mins == 0 { return "\(hours)" + (isZh ? "时" : "h") }
        return "\(hours)" + (isZh ? "时" : "h") + "\(mins)" + (isZh ? "分" : "m")
    }

    func renderImage() -> UIImage? {
        let renderer = ImageRenderer(content: self)
        renderer.scale = 3
        return renderer.uiImage
    }
}

#Preview {
    PeriodShareCardView(
        title: "2026年4月7日 战绩报告",
        stats: PeriodStats(
            totalMatches: 5,
            wins: 3,
            losses: 2,
            winRate: 0.6,
            totalMinutes: 120,
            longestWinStreak: 2,
            totalDeuces: 4,
            comebackGames: 1,
            bestScoringRun: 7,
            topOpponents: [
                OpponentRecord(name: "老王", wins: 2, losses: 1),
                OpponentRecord(name: "小李", wins: 1, losses: 1)
            ]
        )
    )
    .preferredColorScheme(.dark)
}
