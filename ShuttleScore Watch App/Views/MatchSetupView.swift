import SwiftUI

struct MatchSetupView: View {
    @Environment(\.dismiss) var dismiss
    @State private var matchType: MatchType = .singles
    @State private var totalGames: Int = 3
    @State private var teamAName: String = "我方"
    @State private var teamBName: String = "对手"
    @State private var firstServeIsA: Bool = true
    @State private var sideChangeEnabled: Bool = false
    @State private var winningScore: Int = 21
    @State private var customScore: Int = 21
    @State private var navigateToGame = false
    @State private var newMatch: MatchState?

    private let gameOptions = [1, 3, 5]
    private let scoreOptions = [11, 15, 21, 0]  // 0 = 自定义

    var body: some View {
        NavigationStack {
            Form {
                Section("类型") {
                    Picker("类型", selection: $matchType) {
                        ForEach(MatchType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.wheel)
                }

                Section("队伍名称") {
                    TextField("A队名称", text: $teamAName)
                    TextField("B队名称", text: $teamBName)
                }

                Section("局数") {
                    Picker("局数", selection: $totalGames) {
                        ForEach(gameOptions, id: \.self) { n in
                            Text(n == 1 ? "一局定胜负" : n == 3 ? "三局两胜" : "五局三胜").tag(n)
                        }
                    }
                    .pickerStyle(.wheel)
                }

                Section("胜利分数") {
                    Picker("分数", selection: $winningScore) {
                        Text("11分").tag(11)
                        Text("15分").tag(15)
                        Text("21分").tag(21)
                        Text("自定义").tag(0)
                    }
                    .pickerStyle(.wheel)
                    if winningScore == 0 {
                        Stepper("\(customScore)分", value: $customScore, in: 5...99)
                    }
                }

                Section("先发球方") {
                    Picker("先发球", selection: $firstServeIsA) {
                        Text(teamAName).tag(true)
                        Text(teamBName).tag(false)
                    }
                    .pickerStyle(.wheel)
                }

                Section {
                    Toggle("决胜局换边提醒", isOn: $sideChangeEnabled)
                }

                Section {
                    Button(action: startMatch) {
                        HStack {
                            Image(systemName: "flag.checkered")
                            Text("开始比赛")
                                .bold()
                        }
                        .font(.system(.body, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0, green: 0.75, blue: 0.8))
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("赛前设置")
            .navigationDestination(isPresented: $navigateToGame) {
                if let match = newMatch {
                    ScoreboardView(match: match)
                }
            }
        }
    }

    private func startMatch() {
        let finalScore = winningScore == 0 ? customScore : winningScore
        let match = MatchState(
            matchType: matchType,
            teamAName: teamAName,
            teamBName: teamBName,
            totalGames: totalGames,
            firstServeIsA: firstServeIsA,
            sideChangeEnabled: sideChangeEnabled,
            winningScore: finalScore
        )
        MatchStore.shared.save(match)
        MatchStore.shared.saveLastSettings(MatchStore.MatchSettings(
            matchType: matchType, totalGames: totalGames,
            winningScore: finalScore, teamAName: teamAName, teamBName: teamBName
        ))
        newMatch = match
        navigateToGame = true
    }
}
