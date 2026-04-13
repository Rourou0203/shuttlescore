import SwiftUI

struct PhoneSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var opponentStore = PhoneOpponentStore.shared
    @StateObject private var store = MatchHistoryStore.shared
    @ObservedObject private var languageManager = LanguageManager.shared
    var onStart: (PhoneMatchState) -> Void

    @State private var matchType: MatchType = .singles
    @State private var teamAName: String = ""
    @State private var teamBName: String = ""
    @State private var totalGames: Int = 3
    @State private var winningScore: Int = 21
    @State private var firstServeIsA: Bool = true

    private let gameOptions = [1, 3, 5]
    private let scoreOptions = [11, 15, 21]

    init(onStart: @escaping (PhoneMatchState) -> Void) {
        self.onStart = onStart
        // Default names set in onAppear based on language
    }

    var body: some View {
        ZStack {
            Color.brandBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 8) {
                        TeamAvatarView(isTeamA: true, size: 80)
                            .overlay(Circle().stroke(Color.orange.opacity(0.5), lineWidth: 2))

                        Text(languageManager.setupTitle)
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)

                    // Match type
                    settingSection(title: languageManager.setupMatchType) {
                        HStack(spacing: 10) {
                            ForEach(MatchType.allCases, id: \.self) { type in
                                Button(action: { matchType = type }) {
                                    Text(type.rawValue)
                                        .font(.system(.subheadline, design: .rounded))
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(matchType == type ? Color.orange : Color.white.opacity(0.1))
                                        .foregroundColor(matchType == type ? .black : .white)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // Team names
                    settingSection(title: languageManager.setupTeamNames) {
                        HStack(spacing: 16) {
                            VStack(spacing: 6) {
                                TeamAvatarView(isTeamA: true, size: 40)
                                TextField("A", text: $teamAName)
                                    .textFieldStyle(.plain)
                                    .font(.system(.body, design: .rounded))
                                    .multilineTextAlignment(.center)
                                    .padding(8)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .foregroundColor(.orange)
                            }
                            .frame(maxWidth: .infinity)

                            Text("VS")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.brandSecondary)

                            VStack(spacing: 6) {
                                HStack(spacing: 4) {
                                    TeamAvatarView(isTeamA: false, size: 40)
                                    Button(action: generateRandomBuddy) {
                                        Image(systemName: "dice.fill")
                                            .font(.system(.caption))
                                            .foregroundColor(.black)
                                            .padding(6)
                                            .background(Color.orange)
                                            .clipShape(Circle())
                                    }
                                }
                                TextField("B", text: $teamBName)
                                    .textFieldStyle(.plain)
                                    .font(.system(.body, design: .rounded))
                                    .multilineTextAlignment(.center)
                                    .padding(8)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .foregroundColor(.cyan)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }

                    // Quick opponent select
                    if !opponentStore.opponents.isEmpty {
                        settingSection(title: languageManager.setupQuickSelect) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(opponentStore.opponents, id: \.self) { name in
                                        Button(action: { teamBName = name }) {
                                            Text(name)
                                                .font(.system(.subheadline, design: .rounded))
                                                .fontWeight(.medium)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(teamBName == name ? Color.cyan : Color.white.opacity(0.1))
                                                .foregroundColor(teamBName == name ? .black : .white)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Total games
                    settingSection(title: languageManager.setupGames) {
                        HStack(spacing: 12) {
                            ForEach(gameOptions, id: \.self) { n in
                                Button(action: { totalGames = n }) {
                                    Text(languageManager.formatGameOption(n))
                                        .font(.system(.subheadline, design: .rounded))
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(totalGames == n ? Color.orange : Color.white.opacity(0.1))
                                        .foregroundColor(totalGames == n ? .black : .white)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // Winning score
                    settingSection(title: languageManager.setupWinScore) {
                        HStack(spacing: 12) {
                            ForEach(scoreOptions, id: \.self) { s in
                                Button(action: { winningScore = s }) {
                                    Text(languageManager.formatScoreOption(s))
                                        .font(.system(.subheadline, design: .rounded))
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(winningScore == s ? Color.orange : Color.white.opacity(0.1))
                                        .foregroundColor(winningScore == s ? .black : .white)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // First serve
                    settingSection(title: languageManager.setupFirstServe) {
                        HStack(spacing: 12) {
                            Button(action: { firstServeIsA = true }) {
                                Text(teamAName)
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(firstServeIsA ? Color.orange : Color.white.opacity(0.1))
                                    .foregroundColor(firstServeIsA ? .black : .white)
                                    .clipShape(Capsule())
                            }
                            Button(action: { firstServeIsA = false }) {
                                Text(teamBName)
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(!firstServeIsA ? Color.cyan : Color.white.opacity(0.1))
                                    .foregroundColor(!firstServeIsA ? .black : .white)
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    // Start button
                    Button(action: {
                        let state = PhoneMatchState(
                            matchType: matchType,
                            teamAName: teamAName,
                            teamBName: teamBName,
                            totalGames: totalGames,
                            firstServeIsA: firstServeIsA,
                            winningScore: winningScore
                        )
                        onStart(state)
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text(languageManager.setupStartMatch)
                        }
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 4)

                    // Cancel
                    Button(languageManager.setupCancel) { dismiss() }
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.brandSecondary)
                        .padding(.bottom, 20)
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear {
            // Set default names based on language
            if teamAName.isEmpty {
                teamAName = languageManager.language == "zh" ? "我方" : "My Team"
            }
            if teamBName.isEmpty {
                teamBName = languageManager.language == "zh" ? "对手" : "Opponent"
            }
        }
    }

    private func generateRandomBuddy() {
        let prefix = languageManager.randomBuddy
        let hashPrefix = "\(prefix) #"

        let todayRecords = store.records.filter { Calendar.current.isDateInToday($0.startTime) }
        let todayBuddyCount = todayRecords.filter { $0.teamBName.hasPrefix(hashPrefix) }.count
        let savedBuddyCount = opponentStore.opponents.filter { $0.hasPrefix(hashPrefix) }.count

        let nextNumber = max(todayBuddyCount, savedBuddyCount) + 1
        teamBName = "\(hashPrefix)\(nextNumber)"
    }

    private func settingSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(.brandSecondary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    PhoneSetupView { _ in }
        .preferredColorScheme(.dark)
}
