import SwiftUI

struct ProfileView: View {
    let stats: PlayerStats
    @State private var avatar = AvatarConfig.load()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            AvatarRenderer(config: avatar, size: 100)
                            if !avatar.name.isEmpty {
                                Text(avatar.name)
                                    .font(.headline)
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section("Stats") {
                    statRow("Strength", value: stats.strength, icon: "flame.fill", color: .red)
                    statRow("Stamina", value: stats.stamina, icon: "heart.fill", color: .green)
                    statRow("Speed", value: stats.speed, icon: "bolt.fill", color: .blue)
                }

                Section("Progress") {
                    HStack { Text("Level"); Spacer(); Text("\(stats.level)").bold() }
                    HStack { Text("Total XP"); Spacer(); Text("\(stats.totalXP)").bold() }
                    HStack { Text("XP to next level"); Spacer(); Text("\(stats.xpToNextLevel)").bold() }
                }

                Section("About") {
                    HStack { Text("App"); Spacer(); Text(AppConfig.appName).foregroundStyle(.secondary) }
                    HStack { Text("Version"); Spacer(); Text("1.0.0").foregroundStyle(.secondary) }
                }
            }
            .navigationTitle("Profile")
        }
    }

    private func statRow(_ label: String, value: Int, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(color)
            Text(label)
            Spacer()
            Text("\(value)").bold()
        }
    }
}
