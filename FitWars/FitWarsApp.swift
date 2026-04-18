import SwiftUI
import FirebaseCore

@main
struct FitWarsApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var authManager = AuthManager()
    @State private var firestoreService = FirestoreService()
    @State private var engine = StatsEngine()
    @State private var healthKit = HealthKitManager()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                switch authManager.authState {
                case .unknown:
                    ProgressView("Loading…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .signedOut:
                    SignInView()

                case .anonymous, .authenticated:
                    if hasCompletedOnboarding {
                        MainTabView(engine: engine, healthKit: healthKit)
                    } else {
                        AvatarCustomizerView()
                    }
                }
            }
            .environment(authManager)
            .environment(firestoreService)
            .task {
                // Auto-trigger anonymous auth on first launch
                if case .signedOut = authManager.authState {
                    try? await authManager.signInAnonymously()
                }
            }
            .onChange(of: authManager.authState) { _, newState in
                // Create Firestore profile after first-time auth
                if let userId = authManager.currentUserId {
                    firestoreService.currentUserId = userId
                    Task {
                        // Only create profile if it doesn't exist yet
                        do {
                            _ = try await firestoreService.fetchUserProfile(userId: userId)
                        } catch {
                            let avatar = AvatarConfig.load()
                            try? await firestoreService.createUserProfile(
                                userId: userId,
                                username: avatar.name.isEmpty ? "Fighter" : avatar.name,
                                avatarConfig: avatar
                            )
                        }
                    }
                }
            }
        }
    }
}

struct MainTabView: View {
    @Bindable var engine: StatsEngine
    @Bindable var healthKit: HealthKitManager
    @Environment(AuthManager.self) private var authManager
    @Environment(FirestoreService.self) private var firestoreService

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

            // Task 8.2: Fetch remote stats and reconcile with max(local, remote)
            if let userId = authManager.currentUserId {
                if let remoteStats = try? await firestoreService.fetchStats(userId: userId) {
                    engine.stats.strength = max(engine.stats.strength, remoteStats.strength)
                    engine.stats.stamina = max(engine.stats.stamina, remoteStats.stamina)
                    engine.stats.speed = max(engine.stats.speed, remoteStats.speed)
                    engine.stats.totalXP = max(engine.stats.totalXP, remoteStats.totalXP)
                }
            }

            // Task 8.1: Sync stats to Firestore after calculation
            if let userId = authManager.currentUserId {
                // Task 8.3: Fire-and-forget sync
                try? await firestoreService.syncStats(userId: userId, stats: engine.stats)
            }
        }
    }
}
