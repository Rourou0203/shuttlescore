import SwiftUI

struct PhoneSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var opponentStore = PhoneOpponentStore.shared
    var onStart: (PhoneMatchState) -> Void

    @State private var matchType: MatchType = .singles
    @State private var teamAName: String = "我方"
    @State private var teamBName: String = "对手"
    @State private var totalGames: Int = 3
    @State private var winningScore: Int = 21
    @State private var firstServeIsA: Bool = true

    private let gameOptions = [1, 3, 5]
    private let scoreOptions = [11, 15, 21]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 8) {
                        Image("cat_orange")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.orange.opacity(0.5), lineWidth: 2))

                        Text("赛前设置")
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)

                    // Match type
                    settingSection(title: "比赛类型") {
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
                    settingSection(title: "队伍名称") {
                        HStack(spacing: 16) {
                            VStack(spacing: 6) {
                                Image("cat_orange")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                TextField("A队", text: $teamAName)
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
                                .foregroundColor(.gray)

                            VStack(spacing: 6) {
                                Image("cat_robe")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                TextField("B队", text: $teamBName)
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
                        settingSection(title: "快速选择对手") {
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
                    settingSection(title: "局数") {
                        HStack(spacing: 12) {
                            ForEach(gameOptions, id: \.self) { n in
                                Button(action: { totalGames = n }) {
                                    Text("\(n)局\(n > 1 ? "\(n/2+1)胜" : "")")
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
                    settingSection(title: "胜利分数") {
                        HStack(spacing: 12) {
                            ForEach(scoreOptions, id: \.self) { s in
                                Button(action: { winningScore = s }) {
                                    Text("\(s)分")
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
                    settingSection(title: "先发球方") {
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
                            Text("开始比赛")
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
                    Button("取消") { dismiss() }
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.gray)
                        .padding(.bottom, 20)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private func settingSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(.gray)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    PhoneSetupView { _ in }
        .preferredColorScheme(.dark)
}
