import SwiftUI

@main
struct ShuttleScoreApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
                .onAppear {
                    WatchSessionManager.shared.activateSession()
                    WorkoutManager.shared.requestAuthorization()
                    WorkoutManager.shared.checkAndRecoverSession()
                }
        }
    }
}
