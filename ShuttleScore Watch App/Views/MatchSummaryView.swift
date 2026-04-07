import SwiftUI

struct MatchSummaryView: View {
    let match: MatchState
    @Environment(\.dismiss) private var dismiss
    @State private var catScale: CGFloat = 0.3
    @State private var milestoneText: String?
    @State private var saved = false

    private var winnerCatImage: String {
        match.matchWinner == true ? "cat_orange" : "cat_robe"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                // Winning cat with crown
                VStack(spacing: 2) {
                    Text("\u{1F451}")
                        .font(.system(size: 20))
                    Image(winnerCatImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                }
                .scaleEffect(catScale)

                // Milestone celebration
                if let milestone = milestoneText {
                    Text(milestone)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.yellow)
                        .multilineTextAlignment(.center)
                }

                Text(match.matchWinner == true ? "\(match.teamAName)赢了！" : "\(match.teamBName)赢了！")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(match.matchWinner == true ? .yellow : .white)

                Text("\(match.gamesWonByA) : \(match.gamesWonByB)")
                    .font(.system(.title2, design: .rounded))
                    .bold()

                Text("用时 \(match.elapsedMinutes) 分钟")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.gray)

                // Workout stats
                HStack(spacing: 12) {
                    if WorkoutManager.shared.heartRate > 0 {
                        VStack(spacing: 2) {
                            Text("\u{2764}\u{FE0F}").font(.system(size: 14))
                            Text("\(Int(WorkoutManager.shared.heartRate)) bpm")
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(.red.opacity(0.8))
                        }
                    }
                    if WorkoutManager.shared.activeCalories > 0 {
                        VStack(spacing: 2) {
                            Text("\u{1F525}").font(.system(size: 14))
                            Text("\(Int(WorkoutManager.shared.activeCalories)) kcal")
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(.orange.opacity(0.8))
                        }
                    }
                }

                Button(action: {
                    saveMatchIfNeeded()
                    MatchStore.shared.clear()
                    dismiss()
                }) {
                    Label {
                        Text(WorkoutManager.shared.isSessionActive ? "下一场" : "新建比赛")
                    } icon: {
                        Image("cat_robe")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)

                // 结束比赛：保存记录后回到首页
                Button(action: {
                    saveMatchIfNeeded()
                    MatchStore.shared.clear()
                    dismiss()
                }) {
                    Label("结束比赛", systemImage: "house")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }
            .padding()
        }
        // TOP-LEVEL .task — guaranteed to fire when view appears
        .task {
            // 1. Save immediately
            saveMatchIfNeeded()

            // 2. Animation
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                catScale = 1.0
            }

            // 3. Compute milestone (after save so history count is accurate)
            computeMilestone()

            // 4. Notify iPhone
            WatchSessionManager.shared.sendMatchEnded(match: match)
        }
    }

    private func saveMatchIfNeeded() {
        guard !saved else { return }
        saved = true

        match.endTime = match.endTime ?? Date()
        MatchStore.shared.saveToHistory(match)
        WatchSessionManager.shared.sendMatchHistory(match: match)
        OpponentStore.shared.add(match.teamAName)
        OpponentStore.shared.add(match.teamBName)
    }

    private func computeMilestone() {
        let history = MatchStore.shared.loadHistory()
        let totalMatches = history.count

        if match.matchWinner == true {
            var streak = 1
            for record in history {
                if record.gamesWonByA > record.gamesWonByB { streak += 1 } else { break }
            }
            if streak >= 10 { milestoneText = "\u{1F525} \(streak)连胜！无人能挡！"; return }
            if streak >= 5 { milestoneText = "\u{1F525} \(streak)连胜！势不可挡！"; return }
            if streak >= 3 { milestoneText = "\u{2728} \(streak)连胜！继续保持！"; return }
        }

        if totalMatches == 1 { milestoneText = "\u{1F389} 第一场比赛！旅程开始！"; return }
        if totalMatches == 10 { milestoneText = "\u{2B50} 第10场比赛！初露锋芒！"; return }
        if totalMatches == 50 { milestoneText = "\u{1F3C6} 第50场！羽毛球达人！"; return }
        if totalMatches == 100 { milestoneText = "\u{1F451} 第100场！传奇之路！"; return }
        if totalMatches % 50 == 0 { milestoneText = "\u{1F3AF} 第\(totalMatches)场！里程碑！"; return }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
