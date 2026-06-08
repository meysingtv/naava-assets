import SwiftUI

@main
struct NaavaApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var toastManager = ToastManager()

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
            .environmentObject(toastManager)
            .preferredColorScheme(.light)
            .animation(.easeInOut(duration: 0.4), value: appState.isOnboarded)
            .overlay(alignment: .top) {
                ToastBanner()
                    .environmentObject(toastManager)
                    .padding(.top, 8)
            }
        }
    }
}
