import SwiftUI

struct GameSummaryView: View {
    let match: MatchState
    let onContinue: () -> Void
    @ObservedObject private var langMgr = WatchLanguageManager.shared

    private var justFinishedGame: GameState? {
        match.games[safe: match.currentGameIndex]
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.green)

            if let game = justFinishedGame {
                let winnerName = game.winner == true ? match.teamAName : match.teamBName
                Text(langMgr.gameSummaryWinner(winnerName, match.currentGameIndex + 1))
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("\(game.scoreA) : \(game.scoreB)")
                    .font(.system(.title3, design: .rounded))
                    .bold()
                    .foregroundStyle(.white)
            }

            Image(systemName: "pawprint.fill")
                .font(.system(size: 20))
                .foregroundStyle(.orange)

            Text(langMgr.gameSummaryChangeSide)
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.orange)

            Button(action: onContinue) {
                Label {
                    Text(langMgr.gameSummaryNextGame(match.currentGameIndex + 2))
                        .font(.system(.footnote, design: .rounded))
                } icon: {
                    Image("cat_orange")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding()
    }
}
