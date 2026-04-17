import SwiftUI

struct DashboardView: View {
    @State private var healthKit = HealthKitManager()
    @State private var engine = StatsEngine()
    @AppStorage("selectedCharacter") private var selectedCharacter = CharacterModel.maleDefault.rawValue

    var character: CharacterModel {
        CharacterModel(rawValue: selectedCharacter) ?? .maleDefault
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    characterCard
                    statsGrid
                    todayProgress
                }
                .padding()
            }
            .navigationTitle(AppConfig.appName)
            .task {
                await healthKit.requestAuthorization()
                engine.calculate(from: healthKit.todayActivity)
            }
            .refreshable {
                await healthKit.fetchTodayActivity()
                engine.calculate(from: healthKit.todayActivity)
            }
        }
    }

    // MARK: - Character Card

    private var characterCard: some View {
        VStack(spacing: 12) {
            Image(systemName: character == .maleDefault ? "figure.martial.arts" : "figure.kickboxing")
                .font(.system(size: 80))
                .foregroundStyle(.orange)

            Text("Level \(engine.stats.level)")
                .font(.title2.bold())

            Text("\(engine.stats.xpToNextLevel) XP to next level")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        HStack(spacing: 12) {
            statBox("Strength", value: engine.stats.strength, icon: "flame.fill", color: .red)
            statBox("Stamina", value: engine.stats.stamina, icon: "heart.fill", color: .green)
            statBox("Speed", value: engine.stats.speed, icon: "bolt.fill", color: .blue)
        }
    }

    private func statBox(_ label: String, value: Int, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text("\(value)")
                .font(.title.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Today's Progress

    private var todayProgress: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Activity")
                .font(.headline)

            progressRow("Steps", value: "\(healthKit.todayActivity.steps)", icon: "figure.walk")
            progressRow("Active Cal", value: "\(Int(healthKit.todayActivity.activeCalories)) kcal", icon: "flame")
            progressRow("Exercise", value: "\(Int(healthKit.todayActivity.exerciseMinutes)) min", icon: "timer")
            progressRow("Workouts", value: "\(healthKit.todayActivity.workouts.count)", icon: "dumbbell")

            Divider()

            Text("Today's XP")
                .font(.headline)

            HStack {
                xpBadge("STR", xp: engine.todayXP.strength, color: .red)
                xpBadge("STA", xp: engine.todayXP.stamina, color: .green)
                xpBadge("SPD", xp: engine.todayXP.speed, color: .blue)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func progressRow(_ label: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(.secondary)
            Text(label)
            Spacer()
            Text(value)
                .bold()
        }
    }

    private func xpBadge(_ label: String, xp: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("+\(xp)")
                .font(.title3.bold())
            Text(label)
                .font(.caption2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
        .foregroundStyle(color)
    }
}
