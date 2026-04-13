import SwiftUI

// MARK: - Brand Colors
extension Color {
    /// Brand-tinted dark background (not pure black)
    static let brandBackground = Color(red: 0.06, green: 0.05, blue: 0.08)
    /// Slightly elevated surface
    static let brandSurface = Color(white: 0.12)
    /// Secondary text that meets WCAG AA on dark bg
    static let brandSecondary = Color(white: 0.56)
}

@main
struct ShuttleScoreConnectorApp: App {
    init() {
        // Force dark tab bar appearance globally
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(red: 0.08, green: 0.07, blue: 0.1, alpha: 1)
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        UITabBar.appearance().unselectedItemTintColor = UIColor(white: 0.56, alpha: 1)
    }

    @ObservedObject private var profile = ProfileStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environment(\.locale, profile.locale)
        }
    }
}
