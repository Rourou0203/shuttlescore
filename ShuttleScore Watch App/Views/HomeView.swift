import SwiftUI

struct HomeView: View {
    @State private var showSetup = false
    @State private var activeMatch: MatchState?
    @State private var showActiveMatch = false
    @State private var quickStartMatch: MatchState?
    @State private var showQuickStart = false

    private let teal = Color(red: 0, green: 0.74, blue: 0.83)

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                    Image("CatIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                    // 快速开始（橙色大按钮，有上次设置时显示）
                    if let last = MatchStore.shared.loadLastSettings() {
                        Button(action: { quickStart(with: last) }) {
                            Label("快速开始", systemImage: "bolt.fill")
                                .font(.system(.body, design: .rounded))
                                .bold()
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    }

                    // 新建比赛（蓝绿色大按钮）
                    Button(action: { showSetup = true }) {
                        Label("新建比赛", systemImage: "plus.circle.fill")
                            .font(.system(.body, design: .rounded))
                            .bold()
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(teal)

                    // 继续上场（橙色描边中按钮，有进行中比赛时显示）
                    if let match = MatchStore.shared.load(), !match.isMatchOver {
                        Button(action: {
                            activeMatch = match
                            showActiveMatch = true
                        }) {
                            Label("继续上场", systemImage: "arrow.clockwise")
                                .font(.system(.footnote, design: .rounded))
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
            }
            .padding()
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
        MatchStore.shared.save(match)
        quickStartMatch = match
        showQuickStart = true
    }
}
