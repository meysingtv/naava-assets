import SwiftUI

@main
struct NaavaApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.isOnboarded {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(appState)
            .preferredColorScheme(.light)
            .animation(.easeInOut(duration: 0.4), value: appState.isOnboarded)
        }
    }
}
