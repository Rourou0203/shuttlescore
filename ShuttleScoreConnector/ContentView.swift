import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @ObservedObject private var languageManager = LanguageManager.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            LiveScoreView()
                .tabItem {
                    Image(systemName: "sportscourt")
                    Text(languageManager.tabLiveScore)
                }
                .tag(0)

            MatchHistoryView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text(languageManager.tabHistory)
                }
                .tag(1)

            AchievementsView()
                .tabItem {
                    Image(systemName: "trophy")
                    Text(languageManager.tabAchievements)
                }
                .tag(2)

            OpponentStatsView()
                .tabItem {
                    Image(systemName: "person.2")
                    Text(languageManager.tabOpponents)
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text(languageManager.tabProfile)
                }
                .tag(4)
        }
        .tint(.orange)
        .onAppear {
            PhoneSessionManager.shared.activateSession()
        }
    }
}

#Preview {
    ContentView()
}
