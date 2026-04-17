import SwiftUI

struct BattleView: View {
    let playerStats: PlayerStats
    @State private var opponent: Opponent?
    @State private var result: BattleResult?
    @State private var isFighting = false
    @State private var showRealBattle = false
    private let api: APIService = MockAPIService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let result {
                    BattleResultView(result: result) {
                        self.result = nil
                        self.opponent = nil
                    }
                } else if showRealBattle, let opp = opponent {
                    BattleSpriteView(
                        playerStats: playerStats,
                        opponentStats: opp.stats
                    ) { playerWon in
                        showRealBattle = false
                        result = BattleEngine.resolve(player: playerStats, opponent: opp)
                        // Override win/loss with actual fight result
                        result = BattleResult(
                            opponent: opp,
                            playerScore: playerWon ? 1 : 0,
                            opponentScore: playerWon ? 0 : 1,
                            won: playerWon,
                            insight: result!.insight
                        )
                    }
                    .ignoresSafeArea()
                } else if let opp = opponent {
                    opponentPreview(opp)
                } else {
                    findingOpponent
                }
            }
            .navigationTitle(showRealBattle ? "" : "Battle")
            .toolbarVisibility(showRealBattle ? .hidden : .automatic, for: .navigationBar)
            .task { await findOpponent() }
        }
    }

    private var findingOpponent: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.5)
            Text("Finding opponent...").foregroundStyle(.secondary)
        }
        .frame(maxHeight: .infinity)
    }

    private func opponentPreview(_ opp: Opponent) -> some View {
        VStack(spacing: 24) {
            Spacer()

            AvatarRenderer(config: opp.avatarConfig, size: 100)

            Text(opp.username).font(.title.bold())
            Text("Level \(opp.stats.level)").foregroundStyle(.secondary)

            HStack(spacing: 16) {
                miniStat("STR", value: opp.stats.strength, color: .red)
                miniStat("STA", value: opp.stats.stamina, color: .green)
                miniStat("SPD", value: opp.stats.speed, color: .blue)
            }

            Spacer()

            // Real-time fight button
            Button {
                showRealBattle = true
            } label: {
                Text("⚔️ FIGHT")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.orange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)

            // Quick resolve option
            Button {
                quickFight(opp)
            } label: {
                Text("Quick Resolve")
                    .foregroundStyle(.secondary)
            }

            Button("Find New Opponent") {
                opponent = nil
                Task { await findOpponent() }
            }
            .foregroundStyle(.secondary)
            .padding(.bottom, 8)
        }
        .padding()
    }

    private func miniStat(_ label: String, value: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)").font(.title3.bold())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(width: 70)
        .padding(.vertical, 8)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }

    private func findOpponent() async {
        opponent = await api.fetchRandomOpponent()
    }

    private func quickFight(_ opp: Opponent) {
        isFighting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            result = BattleEngine.resolve(player: playerStats, opponent: opp)
            isFighting = false
        }
    }
}

#Preview {
    BattleView(playerStats: PlayerStats(strength: 30, stamina: 25, speed: 20, totalXP: 500))
}
