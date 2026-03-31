import SwiftUI

@main
struct ShuttleScoreApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
                .onAppear {
                    WatchSessionManager.shared.activateSession()
                }
        }
    }
}
