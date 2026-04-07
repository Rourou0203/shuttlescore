import SwiftUI

// MARK: - Share Card View (renders to image for sharing)

struct ShareCardView: View {
    let record: MatchRecord

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.12, blue: 0.14), Color(red: 0.08, green: 0.08, blue: 0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                // Brand header
                HStack {
                    Text("\u{1F3F8} ShuttleScore")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundColor(.orange)
                    Spacer()
                    Text(record.matchType.rawValue)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer().frame(height: 20)

                // Team names
                HStack(spacing: 8) {
                    Text(record.teamAName)
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundColor(.orange)
                    Text("vs")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray)
                    Text(record.teamBName)
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundColor(.cyan)
                }

                Spacer().frame(height: 16)

                // Big game score
                HStack(spacing: 12) {
                    Text("\(record.gamesWonByA)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(record.teamAWon ? .orange : .white)
                    Text(":")
                        .font(.system(size: 36, weight: .medium, design: .rounded))
                        .foregroundColor(.gray)
                    Text("\(record.gamesWonByB)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(record.teamAWon ? .white : .cyan)
                }

                // Per-game scores
                HStack(spacing: 12) {
                    ForEach(Array(record.gameScores.enumerated()), id: \.offset) { _, game in
                        Text("\(game.scoreA)-\(game.scoreB)")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.top, 4)

                Spacer().frame(height: 20)

                // Stats row
                HStack(spacing: 16) {
                    Label("\(record.elapsedMinutes)min", systemImage: "clock")
                    Label("\(record.winningScore)\u{5206}\u{5236}", systemImage: "target")
                }
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.white.opacity(0.6))

                // Date
                Text(record.startTime, format: .dateTime.year().month().day())
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.gray)
                    .padding(.top, 6)

                Spacer().frame(height: 12)

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                    .padding(.horizontal, 24)

                Spacer().frame(height: 10)

                // Cat signature
                HStack(spacing: 4) {
                    Text("\u{1F431}")
                        .font(.system(size: 12))
                    Text("\u{6A58}\u{732B}\u{966A}\u{4F60}\u{6253}\u{7403}")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.gray)
                }

                Spacer().frame(height: 16)
            }
        }
        .frame(width: 400, height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 20))
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
