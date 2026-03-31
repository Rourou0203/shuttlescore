import SwiftUI

struct GameSummaryView: View {
    let match: MatchState
    let onContinue: () -> Void

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
                Text("\(winnerName)赢得第\(match.currentGameIndex + 1)局")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("\(game.scoreA) : \(game.scoreB)")
                    .font(.system(.title3, design: .rounded))
                    .bold()
                    .foregroundStyle(.white)
            }

            Text("\u{1F43E}")
                .font(.system(size: 20))

            Text("⇄ 请换边！")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.orange)

            Button(action: onContinue) {
                Text("开始第\(match.currentGameIndex + 2)局")
                    .font(.system(.footnote, design: .rounded))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding()
    }
}
