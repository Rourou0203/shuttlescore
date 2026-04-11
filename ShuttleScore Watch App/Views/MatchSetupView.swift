import SwiftUI

struct MatchSetupView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var langMgr = WatchLanguageManager.shared
    @State private var matchType: MatchType = .singles
    @State private var totalGames: Int = 3
    @State private var teamAName: String = WatchLanguageManager.shared.defaultTeamA
    @State private var teamBName: String = WatchLanguageManager.shared.defaultTeamB
    private static var defaultOpponentName: String { WatchLanguageManager.shared.defaultTeamB }
    @State private var firstServeIsA: Bool = true
    @State private var sideChangeEnabled: Bool = false
    @State private var voiceAnnouncement: Bool = false
    @State private var winningScore: Int = 21
    @State private var customScore: Int = 21
    @State private var navigateToGame = false
    @State private var newMatch: MatchState?
    @State private var matchTag: MatchTag = .training
    @State private var opponentRecord: (wins: Int, losses: Int)? = nil

    private let gameOptions = [1, 3, 5]
    private let scoreOptions = [11, 15, 21, 0]  // 0 = custom

    var body: some View {
        NavigationStack {
            Form {
                Section(langMgr.setupMatchType) {
                    Picker(langMgr.setupMatchType, selection: $matchType) {
                        ForEach(MatchType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.wheel)
                }

                Section(langMgr.setupTeamNames) {
                    TextField(langMgr.setupTeamAPlaceholder, text: $teamAName)
                    TextField(langMgr.setupTeamBPlaceholder, text: $teamBName)
                        .onChange(of: teamBName) { _, newName in
                            let r = MatchStore.shared.recordsAgainst(opponent: newName)
                            opponentRecord = (r.wins + r.losses > 0) ? r : nil
                        }
                    if !teamBName.isEmpty && teamBName != Self.defaultOpponentName {
                        if let r = opponentRecord {
                            HStack(spacing: 4) {
                                Text(langMgr.setupOpponentRecord)
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundStyle(.gray)
                                Text(langMgr.formatWins(r.wins))
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.green)
                                Text(langMgr.formatLosses(r.losses))
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.red)
                            }
                        } else {
                            Text(langMgr.setupFirstMeeting)
                                .font(.system(size: 11, design: .rounded))
                                .foregroundStyle(.gray)
                        }
                    }
                    NavigationLink {
                        OpponentPickerView(selectedName: $teamBName)
                    } label: {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundStyle(.orange)
                            Text(langMgr.setupSelectOpponent)
                                .font(.system(.footnote, design: .rounded))
                            Spacer()
                            if teamBName != Self.defaultOpponentName {
                                Text(teamBName)
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                }

                Section(langMgr.setupGames) {
                    Picker(langMgr.setupGames, selection: $totalGames) {
                        ForEach(gameOptions, id: \.self) { n in
                            Text(langMgr.setupGameOption(n)).tag(n)
                        }
                    }
                    .pickerStyle(.wheel)
                }

                Section(langMgr.setupWinScore) {
                    Picker(langMgr.setupWinScore, selection: $winningScore) {
                        Text(langMgr.setupScoreOption(11)).tag(11)
                        Text(langMgr.setupScoreOption(15)).tag(15)
                        Text(langMgr.setupScoreOption(21)).tag(21)
                        Text(langMgr.setupCustom).tag(0)
                    }
                    .pickerStyle(.wheel)
                    if winningScore == 0 {
                        Stepper(langMgr.setupScoreOption(customScore), value: $customScore, in: 5...99)
                    }
                }

                Section(langMgr.setupFirstServe) {
                    Picker(langMgr.setupFirstServe, selection: $firstServeIsA) {
                        Text(teamAName).tag(true)
                        Text(teamBName).tag(false)
                    }
                    .pickerStyle(.wheel)
                }

                Section(langMgr.setupMatchTag) {
                    Picker(langMgr.setupMatchTag, selection: $matchTag) {
                        ForEach(MatchTag.allCases, id: \.self) { tag in
                            Text(tag.displayName(lang: langMgr.language)).tag(tag)
                        }
                    }
                    .pickerStyle(.wheel)
                }

                Section {
                    Toggle(langMgr.setupSideChange, isOn: $sideChangeEnabled)
                    Toggle(langMgr.setupVoiceAnnounce, isOn: $voiceAnnouncement)
                }

                Section {
                    Button(action: startMatch) {
                        Label {
                            Text(langMgr.setupStartMatch)
                                .bold()
                        } icon: {
                            Image("cat_scarf")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
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
            .navigationTitle(langMgr.setupTitle)
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
            voiceAnnouncement: voiceAnnouncement,
            winningScore: finalScore,
            matchTag: matchTag
        )
        MatchStore.shared.save(match)
        MatchStore.shared.saveLastSettings(MatchStore.MatchSettings(
            matchType: matchType, totalGames: totalGames,
            winningScore: finalScore, teamAName: teamAName, teamBName: teamBName,
            voiceAnnouncement: voiceAnnouncement
        ))
        newMatch = match
        navigateToGame = true
    }
}
