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
                    .foregroundStyle(result.won ? AeroColors.successGreen : AeroColors.strengthRed)
                    .padding(.top)

                Text("vs \(result.opponent.username)")
                    .font(.title3)
                    .foregroundStyle(AeroColors.secondaryText)

                // Score
                HStack {
                    scoreColumn("You", score: result.playerScore)
                    Text("vs")
                        .font(.caption)
                        .foregroundStyle(AeroColors.secondaryText)
                    scoreColumn(result.opponent.username, score: result.opponentScore)
                }

                // Stat comparison
                VStack(alignment: .leading, spacing: 12) {
                    Text("Stat Breakdown")
                        .font(.headline)
                        .foregroundStyle(AeroColors.primaryText)
                    statRow("Strength", delta: result.insight.strengthDelta, icon: "flame.fill", color: AeroColors.strengthRed)
                    statRow("Stamina", delta: result.insight.staminaDelta, icon: "heart.fill", color: AeroColors.staminaGreen)
                    statRow("Speed", delta: result.insight.speedDelta, icon: "bolt.fill", color: AeroColors.speedBlue)
                }
                .aeroCard()

                // Workout suggestions
                VStack(alignment: .leading, spacing: 12) {
                    Label("Improve your \(result.insight.weakestStat)", systemImage: "lightbulb.fill")
                        .font(.headline)
                        .foregroundStyle(AeroColors.primaryAccent)

                    ForEach(result.insight.suggestions, id: \.self) { suggestion in
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundStyle(AeroColors.primaryAccent)
                            Text(suggestion)
                                .foregroundStyle(AeroColors.primaryText)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .aeroCard()

                Button("Done", action: onDismiss)
                    .buttonStyle(AeroButtonStyle())
                    .padding(.horizontal)
            }
            .padding()
        }
        .aeroBackground()
    }

    private func scoreColumn(_ label: String, score: Double) -> some View {
        VStack(spacing: 4) {
            Text(String(format: "%.1f", score))
                .font(.title.bold())
                .foregroundStyle(AeroColors.primaryText)
            Text(label)
                .font(.caption)
                .foregroundStyle(AeroColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private func statRow(_ label: String, delta: Int, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(label)
                .foregroundStyle(AeroColors.primaryText)
            Spacer()
            Text(delta >= 0 ? "+\(delta)" : "\(delta)")
                .bold()
                .foregroundStyle(delta >= 0 ? AeroColors.staminaGreen : AeroColors.strengthRed)
            Image(systemName: delta >= 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(delta >= 0 ? AeroColors.staminaGreen : AeroColors.strengthRed)
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
