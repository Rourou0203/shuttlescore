import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            LiveScoreView()
                .tabItem {
                    Image(systemName: "sportscourt")
                    Text("实时比分")
                }
                .tag(0)

            MatchHistoryView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("历史统计")
                }
                .tag(1)

            AchievementsView()
                .tabItem {
                    Image(systemName: "trophy")
                    Text("成就")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("我的")
                }
                .tag(3)
        }
        .tint(.orange)
        .preferredColorScheme(.dark)
        .onAppear {
            PhoneSessionManager.shared.activateSession()
        }
    }
}

#Preview {
    ContentView()
}
