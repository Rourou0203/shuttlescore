import SwiftUI

@main
struct ShuttleScoreConnectorApp: App {
    init() {
        // Force dark tab bar appearance globally
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(white: 0.1, alpha: 1)
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        UITabBar.appearance().unselectedItemTintColor = .gray
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
