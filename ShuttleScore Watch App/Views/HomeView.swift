import SwiftUI

struct HomeView: View {
    @ObservedObject private var matchStore = MatchStore.shared
    @ObservedObject private var workoutManager = WorkoutManager.shared
    @State private var showSetup = false
    @State private var activeMatch: MatchState?
    @State private var showActiveMatch = false
    @State private var quickStartMatch: MatchState?
    @State private var showQuickStart = false

    private let teal = Color(red: 0, green: 0.74, blue: 0.83)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    Image("CatIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                    // 快速开始（橙色大按钮）
                    if let last = matchStore.loadLastSettings() {
                        Button(action: { quickStart(with: last) }) {
                            Label {
                                Text("快速开始")
                                    .font(.system(.body, design: .rounded))
                                    .bold()
                            } icon: {
                                Image("cat_orange")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 22, height: 22)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    }

                    // 新建比赛（蓝绿色大按钮）
                    Button(action: { showSetup = true }) {
                        Label {
                            Text("新建比赛")
                                .font(.system(.body, design: .rounded))
                                .bold()
                        } icon: {
                            Image("cat_robe")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(teal)

                    // 继续上场（橙色描边中按钮）
                    if let match = matchStore.currentMatch, !match.isMatchOver {
                        Button(action: {
                            activeMatch = match
                            showActiveMatch = true
                        }) {
                            Label {
                                Text("继续上场")
                                    .font(.system(.footnote, design: .rounded))
                            } icon: {
                                Image("cat_scarf")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                    }

                    // 历史记录（灰色描边小按钮）
                    NavigationLink(destination: CalendarView()) {
                        Label("历史记录", systemImage: "calendar")
                            .font(.system(.caption, design: .rounded))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.gray)

                    // Session 状态
                    if workoutManager.isSessionActive {
                        VStack(spacing: 6) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(workoutManager.isPaused ? .yellow : .green)
                                    .frame(width: 8, height: 8)
                                Text(workoutManager.isPaused ? "练球暂停中" : "练球进行中")
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(.gray)
                                Text("\u{00B7} \(workoutManager.sessionMatchCount)场")
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(.orange)
                            }

                            Button(action: {
                                workoutManager.endSession()
                            }) {
                                Label("结束今日练球", systemImage: "stop.circle")
                                    .font(.system(.caption, design: .rounded))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    }
                }
                .padding()
            }
            .onAppear {
                matchStore.load()
            }
            .navigationTitle("")
            .containerBackground(.black, for: .navigation)
            .sheet(isPresented: $showSetup) {
                MatchSetupView()
            }
            .navigationDestination(isPresented: $showActiveMatch) {
                if let match = activeMatch {
                    ScoreboardView(match: match)
                }
            }
            .navigationDestination(isPresented: $showQuickStart) {
                if let match = quickStartMatch {
                    ScoreboardView(match: match)
                }
            }
        }
    }

    private func quickStart(with settings: MatchStore.MatchSettings) {
        let match = MatchState(
            matchType: settings.matchType,
            teamAName: settings.teamAName,
            teamBName: settings.teamBName,
            totalGames: settings.totalGames,
            firstServeIsA: true,
            winningScore: settings.winningScore
        )
        matchStore.save(match)
        quickStartMatch = match
        showQuickStart = true
    }
}
