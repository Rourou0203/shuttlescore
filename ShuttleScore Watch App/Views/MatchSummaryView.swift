import SwiftUI

struct MatchSummaryView: View {
    let match: MatchState
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var langMgr = WatchLanguageManager.shared
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

                Text(match.matchWinner == true
                     ? langMgr.matchWinText(match.teamAName)
                     : langMgr.matchWinText(match.teamBName))
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(match.matchWinner == true ? .yellow : .white)

                Text("\(match.gamesWonByA) : \(match.gamesWonByB)")
                    .font(.system(.title2, design: .rounded))
                    .bold()

                Text(langMgr.matchElapsedTime(match.elapsedMinutes))
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
                        Text(WorkoutManager.shared.isSessionActive ? langMgr.matchNextMatch : langMgr.matchNewMatch)
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

                Button(action: {
                    saveMatchIfNeeded()
                    MatchStore.shared.clear()
                    dismiss()
                }) {
                    Label(langMgr.matchEndMatch, systemImage: "house")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }
            .padding()
        }
        .task {
            saveMatchIfNeeded()

            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                catScale = 1.0
            }

            computeMilestone()

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
            if let text = langMgr.milestoneStreak(streak) {
                milestoneText = text
                return
            }
        }

        if let text = langMgr.milestoneMatch(totalMatches) {
            milestoneText = text
            return
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
