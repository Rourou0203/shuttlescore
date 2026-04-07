import SwiftUI

struct PhoneScoreboardView: View {
    @ObservedObject var match: PhoneMatchState
    @Environment(\.dismiss) private var dismiss

    @State private var showGameEndSheet = false
    @State private var showMatchEnd = false
    @State private var showExitAlert = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geo in
                let avatarSize = geo.size.width * 0.16
                let scoreFontSize = min(geo.size.width * 0.25, 120.0)

                VStack(spacing: 0) {
                    // MARK: - Top bar
                    topBar

                    Spacer()

                    // MARK: - Score area (two tappable halves)
                    HStack(spacing: 0) {
                        // Team A side
                        teamScoringArea(
                            isTeamA: true,
                            name: match.teamAName,
                            score: match.currentGame.scoreA,
                            accentColor: .orange,
                            avatarSize: avatarSize,
                            scoreFontSize: scoreFontSize
                        )

                        // Divider
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 1)
                            .padding(.vertical, 40)

                        // Team B side
                        teamScoringArea(
                            isTeamA: false,
                            name: match.teamBName,
                            score: match.currentGame.scoreB,
                            accentColor: .cyan,
                            avatarSize: avatarSize,
                            scoreFontSize: scoreFontSize
                        )
                    }

                    Spacer()

                    // MARK: - Bottom bar
                    bottomBar
                }
            }
        }
        .onChange(of: match.currentGame.isOver) { _, isOver in
            if isOver {
                if match.isMatchOver {
                    // 延迟一下让分数动画播放完
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        showMatchEnd = true
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        showGameEndSheet = true
                    }
                }
            }
        }
        .sheet(isPresented: $showGameEndSheet) {
            gameEndSheet
        }
        .fullScreenCover(isPresented: $showMatchEnd) {
            matchEndView
        }
        .alert("退出比赛", isPresented: $showExitAlert) {
            Button("继续比赛", role: .cancel) {}
            Button("保存并退出") {
                saveAndDismiss()
            }
            Button("放弃本场", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("当前比分 \(match.currentGame.scoreA):\(match.currentGame.scoreB)，局分 \(match.gamesWonByA):\(match.gamesWonByB)")
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Close button
            Button(action: { showExitAlert = true }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.gray)
            }

            Spacer()

            // Match info
            VStack(spacing: 2) {
                Text("\(match.matchType.rawValue) \u{00B7} 第\(match.currentGameIndex + 1)局")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.gray)
                Text("局分 \(match.gamesWonByA) : \(match.gamesWonByB)")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            Spacer()

            // Timer
            Text("\(match.elapsedMinutes)分钟")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: - Team Scoring Area

    private func teamScoringArea(
        isTeamA: Bool,
        name: String,
        score: Int,
        accentColor: Color,
        avatarSize: CGFloat,
        scoreFontSize: CGFloat
    ) -> some View {
        let isServing = match.currentGame.servingTeamIsA == isTeamA
        let isGameOver = match.currentGame.isOver

        return VStack(spacing: 16) {
            // Serving indicator
            if isServing && !isGameOver {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 6, height: 6)
                    Text("发球")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.yellow)
                }
                .transition(.opacity)
            } else {
                Color.clear.frame(height: 14)
            }

            // Avatar
            TeamAvatarView(isTeamA: isTeamA, size: avatarSize)
                .overlay(
                    Circle().stroke(
                        isServing ? Color.yellow.opacity(0.6) : Color.clear,
                        lineWidth: 2
                    )
                )

            // Name
            Text(name)
                .font(.system(.headline, design: .rounded))
                .foregroundColor(accentColor)

            // Score
            Text("\(score)")
                .font(.system(size: scoreFontSize, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .contentTransition(.numericText())
                .opacity(isServing || isGameOver ? 1.0 : 0.6)

            // Gesture hint
            if !isGameOver {
                Text("↑加分  ↓撤销")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isGameOver else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                match.addPoint(teamA: isTeamA)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 30, coordinateSpace: .local)
                .onEnded { value in
                    guard !isGameOver else { return }
                    let dy = value.translation.height
                    if dy < -30 {
                        // Swipe up = add point
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            match.addPoint(teamA: isTeamA)
                        }
                    } else if dy > 30 {
                        // Swipe down = undo last point for this team
                        withAnimation(.spring(response: 0.3)) {
                            match.undoForTeam(teamA: isTeamA)
                        }
                    }
                }
        )
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            // Service court
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 8, height: 8)
                Text("\(match.currentGame.servingTeamIsA ? match.teamAName : match.teamBName)发球")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.yellow)
                Text("\u{00B7}")
                    .foregroundColor(.gray)
                Text(match.currentGame.serviceCourt.label)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.yellow.opacity(0.8))
            }

            Spacer()

            // Undo button
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    match.undo()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.uturn.backward")
                    Text("撤销")
                }
                .font(.system(.body, design: .rounded))
                .foregroundColor(.orange)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.15))
                .clipShape(Capsule())
            }
            .disabled(match.currentGame.history.isEmpty)
            .opacity(match.currentGame.history.isEmpty ? 0.3 : 1)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    // MARK: - Game End Sheet

    private var gameEndSheet: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("第\(match.currentGameIndex + 1)局结束")
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                let game = match.currentGame
                HStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Text(match.teamAName)
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.orange)
                        Text("\(game.scoreA)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(game.winner == true ? .orange : .gray)
                    }

                    Text(":")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.gray)

                    VStack(spacing: 8) {
                        Text(match.teamBName)
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.cyan)
                        Text("\(game.scoreB)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(game.winner == false ? .cyan : .gray)
                    }
                }

                Text("局分 \(match.gamesWonByA) : \(match.gamesWonByB)")
                    .font(.system(.title3, design: .rounded))
                    .foregroundColor(.gray)

                Button(action: {
                    match.startNextGame()
                    showGameEndSheet = false
                }) {
                    HStack {
                        Image(systemName: "forward.fill")
                        Text("下一局")
                    }
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Match End View

    private var matchEndView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                // Winner announcement
                let winnerIsA = match.matchWinner == true
                let winnerName = winnerIsA ? match.teamAName : match.teamBName
                let winnerColor: Color = winnerIsA ? .orange : .cyan

                TeamAvatarView(isTeamA: winnerIsA, size: 100)
                    .overlay(Circle().stroke(winnerColor, lineWidth: 3))

                Text("\(winnerName) 获胜!")
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(winnerColor)

                // Game scores
                VStack(spacing: 8) {
                    Text("局分 \(match.gamesWonByA) : \(match.gamesWonByB)")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    ForEach(0..<match.games.count, id: \.self) { i in
                        let g = match.games[i]
                        Text("第\(i + 1)局  \(g.scoreA) : \(g.scoreB)")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.gray)
                    }
                }

                Text("用时 \(match.elapsedMinutes) 分钟")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.gray)

                Spacer()

                // Save button
                Button(action: {
                    saveAndDismiss()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("保存并返回")
                    }
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Save & Dismiss

    private func saveAndDismiss() {
        let record = match.toMatchRecord()
        MatchHistoryStore.shared.addRecord(record)
        PhoneSessionManager.shared.sendMatchHistoryToWatch(record)
        // Auto-save opponent name for future quick selection
        PhoneOpponentStore.shared.add(record.teamBName)
        showMatchEnd = false
        dismiss()
    }
}

#Preview {
    PhoneScoreboardView(match: PhoneMatchState(
        matchType: .singles,
        teamAName: "小明",
        teamBName: "小红",
        totalGames: 3,
        firstServeIsA: true,
        winningScore: 21
    ))
}
