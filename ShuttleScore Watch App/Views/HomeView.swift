import SwiftUI

struct HomeView: View {
    @ObservedObject private var matchStore = MatchStore.shared
    @ObservedObject private var workoutManager = WorkoutManager.shared
    @ObservedObject private var langMgr = WatchLanguageManager.shared
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

                    // Quick start
                    if let last = matchStore.loadLastSettings() {
                        Button(action: { quickStart(with: last) }) {
                            Label {
                                Text(langMgr.homeQuickStart)
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

                    // New match
                    Button(action: { showSetup = true }) {
                        Label {
                            Text(langMgr.homeNewMatch)
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

                    // Continue match
                    if let match = matchStore.currentMatch, !match.isMatchOver {
                        Button(action: {
                            activeMatch = match
                            showActiveMatch = true
                        }) {
                            Label {
                                Text(langMgr.homeContinue)
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

                    // History
                    NavigationLink(destination: CalendarView()) {
                        Label(langMgr.homeHistory, systemImage: "calendar")
                            .font(.system(.caption, design: .rounded))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.gray)

                    // Session status
                    if workoutManager.isSessionActive {
                        VStack(spacing: 6) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(workoutManager.isPaused ? .yellow : .green)
                                    .frame(width: 8, height: 8)
                                Text(workoutManager.isPaused ? langMgr.homePracticePaused : langMgr.homePracticeActive)
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(.gray)
                                Text("\u{00B7} \(langMgr.homeMatchCount(workoutManager.sessionMatchCount))")
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(.orange)
                            }

                            Button(action: {
                                workoutManager.endSession()
                            }) {
                                Label(langMgr.homeEndSession, systemImage: "stop.circle")
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
            .onOpenURL { url in
                guard url.scheme == "shuttlescore", url.host == "start" else { return }
                if let last = matchStore.loadLastSettings() {
                    quickStart(with: last)
                } else {
                    showSetup = true
                }
            }
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
            voiceAnnouncement: settings.voiceAnnouncement,
            winningScore: settings.winningScore
        )
        matchStore.save(match)
        quickStartMatch = match
        showQuickStart = true
    }
}
