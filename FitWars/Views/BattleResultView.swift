import SwiftUI

struct BattleResultView: View {
    let result: BattleResult
    let onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Win/Loss banner
                Text(result.won ? "VICTORY" : "DEFEAT")
                    .font(.largeTitle.bold())
                    .foregroundStyle(result.won ? .green : .red)
                    .padding(.top)

                Text("vs \(result.opponent.username)")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                // Score
                HStack {
                    scoreColumn("You", score: result.playerScore)
                    Text("vs")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    scoreColumn(result.opponent.username, score: result.opponentScore)
                }

                // Stat comparison
                VStack(alignment: .leading, spacing: 12) {
                    Text("Stat Breakdown")
                        .font(.headline)
                    statRow("Strength", delta: result.insight.strengthDelta, icon: "flame.fill", color: .red)
                    statRow("Stamina", delta: result.insight.staminaDelta, icon: "heart.fill", color: .green)
                    statRow("Speed", delta: result.insight.speedDelta, icon: "bolt.fill", color: .blue)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

                // Workout suggestions
                VStack(alignment: .leading, spacing: 12) {
                    Label("Improve your \(result.insight.weakestStat)", systemImage: "lightbulb.fill")
                        .font(.headline)
                        .foregroundStyle(.orange)

                    ForEach(result.insight.suggestions, id: \.self) { suggestion in
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundStyle(.orange)
                            Text(suggestion)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))

                Button("Done", action: onDismiss)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.orange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding()
        }
    }

    private func scoreColumn(_ label: String, score: Double) -> some View {
        VStack(spacing: 4) {
            Text(String(format: "%.1f", score))
                .font(.title.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func statRow(_ label: String, delta: Int, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(label)
            Spacer()
            Text(delta >= 0 ? "+\(delta)" : "\(delta)")
                .bold()
                .foregroundStyle(delta >= 0 ? .green : .red)
            Image(systemName: delta >= 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(delta >= 0 ? .green : .red)
        }
    }
}

#Preview("Victory") {
    BattleResultView(
        result: BattleResult(
            opponent: Opponent(id: "1", username: "IronMike",
                             avatarConfig: AvatarConfig(name: "IronMike", skinTone: AvatarConfig.skinTones[3], faceShape: .square, eyeStyle: .fierce, hairStyle: .short, hairColor: AvatarConfig.hairColors[0], outfit: .tankTop),
                             stats: PlayerStats(strength: 45, stamina: 30, speed: 25, totalXP: 800)),
            playerScore: 42.3,
            opponentScore: 38.7,
            won: true,
            insight: BattleInsight(strengthDelta: -15, staminaDelta: 10, speedDelta: 5,
                                  weakestStat: "Strength", suggestions: ["Weight training", "Core workouts", "HIIT sessions"])
        ),
        onDismiss: {}
    )
}

#Preview("Defeat") {
    BattleResultView(
        result: BattleResult(
            opponent: Opponent(id: "2", username: "SwiftKat",
                             avatarConfig: AvatarConfig(name: "SwiftKat", skinTone: AvatarConfig.skinTones[1], faceShape: .oval, eyeStyle: .normal, hairStyle: .ponytail, hairColor: AvatarConfig.hairColors[4], outfit: .gi),
                             stats: PlayerStats(strength: 20, stamina: 35, speed: 50, totalXP: 900)),
            playerScore: 28.1,
            opponentScore: 35.9,
            won: false,
            insight: BattleInsight(strengthDelta: 10, staminaDelta: -10, speedDelta: -30,
                                  weakestStat: "Speed", suggestions: ["Running", "Walking (aim for 8,000+ steps)", "Sprint intervals"])
        ),
        onDismiss: {}
    )
}
