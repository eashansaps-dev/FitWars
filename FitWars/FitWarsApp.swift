import SwiftUI

@main
struct FitWarsApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var engine = StatsEngine()
    @State private var healthKit = HealthKitManager()

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView(engine: engine, healthKit: healthKit)
            } else {
                AvatarCustomizerView()
            }
        }
    }
}

struct MainTabView: View {
    @Bindable var engine: StatsEngine
    @Bindable var healthKit: HealthKitManager

    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "house.fill") {
                DashboardView()
            }
            Tab("Battle", systemImage: "figure.martial.arts") {
                BattleView(playerStats: engine.stats)
            }
            Tab("Profile", systemImage: "person.fill") {
                ProfileView(stats: engine.stats)
            }
        }
        .tint(.orange)
        .task {
            await healthKit.requestAuthorization()
            engine.calculate(from: healthKit.todayActivity)
        }
    }
}
