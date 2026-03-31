import SwiftUI

struct MatchSummaryView: View {
    let match: MatchState
    @Environment(\.dismiss) private var dismiss
    @State private var catScale: CGFloat = 0.3

    /// Winning team's cat image name
    private var winnerCatImage: String {
        match.matchWinner == true ? "cat_orange" : "cat_robe"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                // Winning cat with crown animation
                ZStack {
                    VStack(spacing: 2) {
                        Text("👑")
                            .font(.system(size: 20))
                        Image(winnerCatImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                    }
                }
                .scaleEffect(catScale)
                .onAppear {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0)) {
                        catScale = 1.0
                    }
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

                Button(action: {
                    MatchStore.shared.saveToHistory(match)
                    MatchStore.shared.clear()
                    dismiss()
                }) {
                    Label {
                        Text("新建比赛")
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
            }
            .padding()
        }
    }
}

// MARK: - Array Safe Subscript Helper
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
