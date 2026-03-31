import SwiftUI
import WatchKit

struct ScoreboardView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var match: MatchState
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

                // Score row - tap left/right to score, long-press to transfer
                GeometryReader { _ in
                    HStack(spacing: 0) {
                        // Team A score (tap to score, long-press to transfer)
                        Button(action: { scorePoint(teamA: true) }) {
                            Text("\(match.currentGame.scoreA)")
                                .font(.system(size: 52, weight: .black, design: .rounded))
                                .foregroundStyle(match.currentGame.servingTeamIsA ? .yellow : .white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .buttonStyle(.plain)
                        .onLongPressGesture(minimumDuration: 0.5) {
                            transferPoint(toTeamA: true)
                        }

                        // Divider
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 1)

                        // Team B score (tap to score, long-press to transfer)
                        Button(action: { scorePoint(teamA: false) }) {
                            Text("\(match.currentGame.scoreB)")
                                .font(.system(size: 52, weight: .black, design: .rounded))
                                .foregroundStyle(!match.currentGame.servingTeamIsA ? .yellow : .white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .buttonStyle(.plain)
                        .onLongPressGesture(minimumDuration: 0.5) {
                            transferPoint(toTeamA: false)
                        }
                    }
                }
                .frame(height: 70)

                // Footer: game info + serve court
                HStack {
                    Text("第\(match.currentGameIndex + 1)局")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.gray)

                    Spacer()

                    Text("\(match.gamesWonByA)-\(match.gamesWonByB)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.gray)

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
            if newVal < lastCrownValue - 3 {
                ScoringEngine.undo(match: match)
                MatchStore.shared.save(match)
                lastCrownValue = newVal
            } else {
                lastCrownValue = newVal
            }
        }
        .onChange(of: match.currentGame.isOver) { _, isOver in
            if isOver {
                if match.isMatchOver {
                    showMatchOver = true
                } else {
                    showGameOver = true
                }
                MatchStore.shared.save(match)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { showExitAlert = true }) {
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
            })
        }
        .fullScreenCover(isPresented: $showMatchOver) {
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
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.85))
                    )
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: transferMessage)
        .confirmationDialog("退出比赛", isPresented: $showExitAlert) {
            Button("继续比赛", role: .cancel) { }
            Button("保存并退出") {
                savePartialMatchAndExit()
            }
            Button("放弃本场", role: .destructive) {
                MatchStore.shared.clear()
                dismiss()
            }
        }
    }

    private func scorePoint(teamA: Bool) {
        ScoringEngine.addPoint(to: match, teamAScores: teamA)
        MatchStore.shared.save(match)
    }

    private func savePartialMatchAndExit() {
        match.endTime = Date()
        MatchStore.shared.saveToHistory(match)
        MatchStore.shared.clear()
        dismiss()
    }

    private func transferPoint(toTeamA: Bool) {
        guard !match.currentGame.history.isEmpty else { return }
        ScoringEngine.transferLastPoint(to: match, toTeamA: toTeamA)
        MatchStore.shared.save(match)

        // Haptic notification
        WKInterfaceDevice.current().play(.notification)

        // Show confirmation message
        let teamName = toTeamA ? match.teamAName : match.teamBName
        transferMessage = "已将分数转给\(teamName)"

        // Auto-dismiss after 1.5s
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            transferMessage = nil
        }
    }
}
