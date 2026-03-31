import SwiftUI

struct MatchSummaryView: View {
    let match: MatchState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 10) {
            Text(match.matchWinner == true ? "🏆" : "🥈")
                .font(.system(size: 48))

            Text(match.matchWinner == true ? "\(match.teamAName)赢了！" : "\(match.teamBName)赢了！")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(match.matchWinner == true ? .yellow : .white)

            Text("\(match.gamesWonByA) : \(match.gamesWonByB)")
                .font(.system(.title2, design: .rounded))
                .bold()

            Text("用时 \(match.elapsedMinutes) 分钟")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.gray)

            Button(action: {
                MatchStore.shared.saveToHistory(match)
                MatchStore.shared.clear()
                dismiss()
            }) {
                Text("新建比赛")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .padding()
    }
}

// MARK: - Array Safe Subscript Helper
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
