import SwiftUI

@main
struct FitWarsApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                DashboardView()
            } else {
                CharacterSelectionView()
            }
        }
    }
}
