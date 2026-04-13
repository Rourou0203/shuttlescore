import SwiftUI
import Charts

// MARK: - Share Card View (Single Match)

struct ShareCardView: View {
    let record: MatchRecord
    private let languageManager = LanguageManager.shared
    private let eloManager = ELOManager.shared

    private var highlights: [(icon: String, text: String)] {
        var items: [(String, String)] = []
        let isZh = languageManager.language == "zh"

        // Duration
        items.append(("clock", "\(record.elapsedMinutes)" + (isZh ? "分钟" : "min")))

        // Deuces
        if record.totalDeuces > 0 {
            items.append(("arrow.left.arrow.right", "Deuce×\(record.totalDeuces)"))
        }

        // Comeback
        if record.comebackGames > 0 {
            items.append(("arrow.uturn.up", isZh ? "逆转\(record.comebackGames)局" : "\(record.comebackGames) Comeback"))
        }

        // Best run
        let bestRun = max(record.longestRunA, record.longestRunB)
        if bestRun >= 4 {
            items.append(("flame.fill", isZh ? "最佳\(bestRun)连得" : "\(bestRun) Run"))
        }

        // Flash win
        if record.elapsedMinutes <= 10 && record.teamAWon {
            items.append(("bolt.fill", isZh ? "闪电战" : "Blitz"))
        }

        return items
    }

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

                // Score section
                scoreSection

                Spacer().frame(height: 16)

                // Mini score chart
                if let firstGame = record.gameScores.first, !firstGame.history.isEmpty {
                    miniChartSection
                    Spacer().frame(height: 16)
                }

                // Highlights
                highlightsSection

                Spacer().frame(height: 16)

                // Footer
                footerSection
                    .padding(.bottom, 20)
            }
        }
        .frame(width: 400, height: record.gameScores.first?.history.isEmpty == false ? 400 : 320)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "figure.badminton")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
                Text("ShuttleScore")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundColor(.orange)
            }

            Spacer()

            HStack(spacing: 8) {
                Text(record.matchType.displayName)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())

                if let tag = record.matchTag {
                    Text(tag.displayName)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(tag.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(tag.color.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Score

    private var scoreSection: some View {
        VStack(spacing: 8) {
            // Team names
            HStack {
                Text(record.teamAName)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundColor(.orange)
                Spacer()
                Text(record.teamBName)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundColor(.cyan)
            }
            .padding(.horizontal, 48)

            // Big score
            HStack(spacing: 16) {
                Text("\(record.gamesWonByA)")
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundColor(record.teamAWon ? .orange : .white.opacity(0.5))
                Text(":")
                    .font(.system(size: 32, weight: .medium, design: .rounded))
                    .foregroundColor(.brandSecondary)
                Text("\(record.gamesWonByB)")
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundColor(record.teamAWon ? .white.opacity(0.5) : .cyan)
            }

            // Per-game scores
            HStack(spacing: 16) {
                ForEach(Array(record.gameScores.enumerated()), id: \.offset) { _, game in
                    Text("\(game.scoreA)–\(game.scoreB)")
                        .font(.system(.caption, design: .monospaced, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
    }

    // MARK: - Mini Chart

    private var miniChartSection: some View {
        let game = record.gameScores[0]
        var points: [ScoreChartPoint] = []
        for (i, snap) in game.history.enumerated() {
            points.append(ScoreChartPoint(rally: i, score: snap.scoreA, team: record.teamAName))
            points.append(ScoreChartPoint(rally: i, score: snap.scoreB, team: record.teamBName))
        }
        points.append(ScoreChartPoint(rally: game.history.count, score: game.scoreA, team: record.teamAName))
        points.append(ScoreChartPoint(rally: game.history.count, score: game.scoreB, team: record.teamBName))

        return Chart(points) { point in
            LineMark(
                x: .value("Rally", point.rally),
                y: .value("Score", point.score)
            )
            .foregroundStyle(by: .value("Team", point.team))
            .interpolationMethod(.stepEnd)
            .lineStyle(StrokeStyle(lineWidth: 1.5))
        }
        .chartForegroundStyleScale([
            record.teamAName: Color.orange.opacity(0.8),
            record.teamBName: Color.cyan.opacity(0.8)
        ])
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .frame(height: 50)
        .padding(.horizontal, 24)
    }

    // MARK: - Highlights

    private var highlightsSection: some View {
        HStack(spacing: 0) {
            ForEach(Array(highlights.prefix(4).enumerated()), id: \.offset) { _, item in
                HStack(spacing: 4) {
                    Image(systemName: item.icon)
                        .font(.system(size: 10))
                        .foregroundColor(.orange.opacity(0.7))
                    Text(item.text)
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 8) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
                .padding(.horizontal, 24)

            HStack {
                // Date
                Text(record.startTime, format: .dateTime.year().month().day())
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.brandSecondary.opacity(0.6))

                Spacer()

                // ELO badge
                let rating = eloManager.myRating
                HStack(spacing: 4) {
                    Image(systemName: eloManager.tierIcon(for: rating))
                        .font(.system(size: 10))
                        .foregroundColor(eloManager.tierColor(for: rating))
                    Text("\(rating)")
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                        .foregroundColor(eloManager.tierColor(for: rating))
                }

                Spacer()

                // Brand
                HStack(spacing: 4) {
                    Image(systemName: "cat.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.brandSecondary.opacity(0.6))
                    Text("ShuttleScore")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.brandSecondary.opacity(0.6))
                }
            }
            .padding(.horizontal, 24)
        }
    }

    func renderImage() -> UIImage? {
        let renderer = ImageRenderer(content: self)
        renderer.scale = 3
        return renderer.uiImage
    }
}

// MARK: - Share Sheet (UIActivityViewController wrapper)

struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
