import SwiftUI
import WatchKit
import HealthKit

struct ScoreboardView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var match: MatchState
    @ObservedObject var workoutManager = WorkoutManager.shared
    @State private var showExitAlert = false
    @State private var showGameOver = false
    @State private var showMatchOver = false
    @State private var showSideChangeAlert = false
    @State private var sideChangeAlerted = false
    @State private var crownValue: Double = 0
    @State private var lastCrownValue: Double = 0
    @State private var transferMessage: String?

    var body: some View {
        ZStack {
            // Split background: left warm, right cool
            HStack(spacing: 0) {
                Color(red: 0.12, green: 0.10, blue: 0.08).opacity(0.6)
                Color(red: 0.08, green: 0.10, blue: 0.14).opacity(0.6)
            }
            .ignoresSafeArea()

            VStack(spacing: 4) {
                // Header: team names + serve indicator
                HStack {
                    HStack(spacing: 4) {
                        if match.currentGame.servingTeamIsA {
                            Circle()
                                .fill(Color.yellow)
                                .frame(width: 8, height: 8)
                                .shadow(color: .yellow, radius: 3)
                        }
                        Text(match.teamAName)
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(match.currentGame.servingTeamIsA ? .yellow : .gray)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text(match.teamBName)
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(!match.currentGame.servingTeamIsA ? .yellow : .gray)

                        if !match.currentGame.servingTeamIsA {
                            Circle()
                                .fill(Color.yellow)
                                .frame(width: 8, height: 8)
                                .shadow(color: .yellow, radius: 3)
                        }
                    }
                }
                .padding(.horizontal, 8)

                // Score row
                GeometryReader { _ in
                    HStack(spacing: 0) {
                        // Team A: tap = add, swipe up = add, swipe down = undo A
                        scoreHalf(
                            score: match.currentGame.scoreA,
                            isServing: match.currentGame.servingTeamIsA,
                            teamA: true
                        )

                        // Divider
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 1)

                        // Team B: tap = add, swipe up = add, swipe down = undo B
                        scoreHalf(
                            score: match.currentGame.scoreB,
                            isServing: !match.currentGame.servingTeamIsA,
                            teamA: false
                        )
                    }
                }
                .frame(height: 70)

                // Footer: game info + serve court + workout stats
                HStack {
                    Text("\(match.matchType.rawValue) · 第\(match.currentGameIndex + 1)局")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.gray)

                    Spacer()

                    // Heart rate & calories
                    if workoutManager.isWorkoutActive {
                        HStack(spacing: 3) {
                            if workoutManager.heartRate > 0 {
                                Text("\u{2764}\u{FE0F}\(Int(workoutManager.heartRate))")
                                    .font(.system(size: 9, design: .rounded))
                                    .foregroundStyle(.red.opacity(0.8))
                            }
                            if workoutManager.activeCalories > 0 {
                                Text("\u{1F525}\(Int(workoutManager.activeCalories))")
                                    .font(.system(size: 9, design: .rounded))
                                    .foregroundStyle(.orange.opacity(0.8))
                            }
                        }
                    } else {
                        Text("\(match.gamesWonByA)-\(match.gamesWonByB)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.gray)
                    }

                    Spacer()

                    Text(match.currentGame.serviceCourt.label)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.orange.opacity(0.8))
                }
                .padding(.horizontal, 8)
            }
            .padding(.vertical, 4)
        }
        // Digital Crown = undo
        .focusable()
        .digitalCrownRotation($crownValue, from: -100, through: 100, sensitivity: .medium)
        .onChange(of: crownValue) { _, newVal in
            if newVal < lastCrownValue - 3 && !match.isMatchOver {
                ScoringEngine.undo(match: match)
                MatchStore.shared.save(match)
                WatchSessionManager.shared.sendMatchState(match: match)
                lastCrownValue = newVal
            } else {
                lastCrownValue = newVal
            }
        }
        .onChange(of: match.currentGame.isOver) { _, isOver in
            if isOver {
                MatchStore.shared.save(match)

                if match.isMatchOver {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        workoutManager.pauseSession()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showMatchOver = true
                    }
                } else {
                    showGameOver = true
                }
            }
        }
        .onAppear { workoutManager.startOrResumeSession() }
        .onDisappear {
            // Always save to history if match is over, no matter how user exits
            if match.isMatchOver {
                match.endTime = match.endTime ?? Date()
                MatchStore.shared.saveToHistory(match)
                WatchSessionManager.shared.sendMatchHistory(match: match)
            }
            workoutManager.pauseSession()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    showExitAlert = true
                }) {
                    Image(systemName: "xmark")
                        .foregroundStyle(.gray)
                        .font(.footnote)
                }
            }
        }
        .sheet(isPresented: $showGameOver) {
            GameSummaryView(match: match, onContinue: {
                showGameOver = false
                ScoringEngine.startNextGame(match: match)
                MatchStore.shared.save(match)
                WatchSessionManager.shared.sendMatchState(match: match)
            })
        }
        .fullScreenCover(isPresented: $showMatchOver, onDismiss: {
            // 用户按数码表冠关闭了 MatchSummaryView，确保记录已保存
            if match.isMatchOver {
                match.endTime = match.endTime ?? Date()
                MatchStore.shared.saveToHistory(match)
                WatchSessionManager.shared.sendMatchHistory(match: match)
                OpponentStore.shared.add(match.teamAName)
                OpponentStore.shared.add(match.teamBName)
            }
        }) {
            MatchSummaryView(match: match)
        }
        .onChange(of: showMatchOver) { _, isShowing in
            if !isShowing && MatchStore.shared.load() == nil {
                dismiss()
            }
        }
        .sheet(isPresented: $showSideChangeAlert) {
            VStack(spacing: 12) {
                Text("⇄")
                    .font(.system(size: 40))
                Text("请换边！继续加油")
                    .font(.system(.body, design: .rounded))
                    .multilineTextAlignment(.center)
                Button("确认") {
                    showSideChangeAlert = false
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding()
        }
        .onChange(of: match.currentGame.shouldAlertSideChange) { _, shouldAlert in
            let isDecidingGame = match.currentGameIndex == match.totalGames - 1
            if shouldAlert && isDecidingGame && !sideChangeAlerted && match.sideChangeEnabled {
                sideChangeAlerted = true
                showSideChangeAlert = true
            }
        }
        .overlay {
            if let message = transferMessage {
                Text(message)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.green.opacity(0.85)))
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: transferMessage)
        .confirmationDialog("退出比赛", isPresented: $showExitAlert) {
            Button("继续比赛", role: .cancel) { }
            Button("保存并退出") {
                // Save to history (even if match not fully over)
                let hasScores = match.games.contains { $0.scoreA > 0 || $0.scoreB > 0 }
                if hasScores {
                    match.endTime = match.endTime ?? Date()
                    MatchStore.shared.saveToHistory(match)
                    WatchSessionManager.shared.sendMatchHistory(match: match)
                    OpponentStore.shared.add(match.teamAName)
                    OpponentStore.shared.add(match.teamBName)
                }
                workoutManager.pauseSession()
                MatchStore.shared.clear()
                dismiss()
            }
            Button("放弃本场", role: .destructive) {
                workoutManager.pauseSession()
                WatchSessionManager.shared.sendMatchTerminated(match: match)
                MatchStore.shared.clear()
                dismiss()
            }
        }
    }

    // MARK: - Score Half View

    @ViewBuilder
    private func scoreHalf(score: Int, isServing: Bool, teamA: Bool) -> some View {
        ZStack {
            VStack(spacing: 2) {
                // Cat mascot above score
                Image(teamA ? "cat_orange" : "cat_robe")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .clipShape(Circle())
                    .opacity(isServing ? 1.0 : 0.5)

                Text("\(score)")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(isServing ? .yellow : .white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            scorePoint(teamA: teamA)
        }
        .gesture(
            DragGesture(minimumDistance: 25, coordinateSpace: .local)
                .onEnded { value in
                    let dy = value.translation.height
                    if dy < -25 {
                        // Swipe up = add point
                        scorePoint(teamA: teamA)
                    } else if dy > 25 {
                        // Swipe down = undo this team's last point
                        undoPointForTeam(teamA: teamA)
                    }
                }
        )
    }

    // MARK: - Actions

    private func scorePoint(teamA: Bool) {
        guard !match.currentGame.isOver else { return }
        ScoringEngine.addPoint(to: match, teamAScores: teamA)

        // Throttle saves: only persist every 5 points or when game/match is over
        let totalScore = match.currentGame.scoreA + match.currentGame.scoreB
        if totalScore % 5 == 0 || match.currentGame.isOver {
            MatchStore.shared.save(match)
        }

        // Send live score to iPhone
        WatchSessionManager.shared.sendMatchState(match: match)
    }

    private func savePartialMatchAndExit() {
        // 暂停比赛，保留到 current_match 供"继续上场"，不写入历史
        MatchStore.shared.save(match)
        workoutManager.pauseSession()
        WatchSessionManager.shared.sendMatchTerminated(match: match)
        dismiss()
    }

    private func undoPointForTeam(teamA: Bool) {
        guard !match.currentGame.isOver else { return }
        let game = match.currentGame
        guard !game.history.isEmpty else {
            WKInterfaceDevice.current().play(.failure)
            return
        }
        let prev = game.history[game.history.count - 1]
        let teamAScored = game.scoreA > prev.scoreA
        let teamBScored = game.scoreB > prev.scoreB

        if (teamA && teamAScored) || (!teamA && teamBScored) {
            ScoringEngine.undo(match: match)
            MatchStore.shared.save(match)
            WatchSessionManager.shared.sendMatchState(match: match)
            WKInterfaceDevice.current().play(.notification)
            showMessage("撤销 \(teamA ? match.teamAName : match.teamBName) 得分")
        } else {
            WKInterfaceDevice.current().play(.failure)
            showMessage("最后一分不是\(teamA ? match.teamAName : match.teamBName)得的")
        }
    }

    private func showMessage(_ text: String) {
        transferMessage = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            transferMessage = nil
        }
    }

}
