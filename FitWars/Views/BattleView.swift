import SwiftUI

struct BattleView: View {
    let playerStats: PlayerStats
    @Environment(FirestoreService.self) private var firestoreService
    @State private var opponent: Opponent?
    @State private var result: BattleResult?
    @State private var isFighting = false
    @State private var showRealBattle = false
    @State private var selectedDifficulty: DifficultyLevel = .medium

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
                        opponentStats: opp.stats,
                        difficulty: selectedDifficulty,
                        playerAtlas: "fighter_default",
                        opponentAtlas: "fighter_default",
                        stageID: "arena_01"
                    ) { playerWon in
                        showRealBattle = false
                        result = BattleEngine.resolve(player: playerStats, opponent: opp)
                        result = BattleResult(
                            opponent: opp,
                            playerScore: playerWon ? 1 : 0,
                            opponentScore: playerWon ? 0 : 1,
                            won: playerWon,
                            insight: result!.insight
                        )
                        if let result {
                            Task { await firestoreService.submitBattleResult(result) }
                        }
                    }
                    .ignoresSafeArea()
                } else if let opp = opponent {
                    opponentPreview(opp)
                } else {
                    findingOpponent
                }
            }
            .aeroBackground()
            .navigationTitle(showRealBattle ? "" : "Battle")
            .toolbarVisibility(showRealBattle ? .hidden : .automatic, for: .navigationBar)
            .toolbar(showRealBattle ? .hidden : .visible, for: .tabBar)
            .task { await findOpponent() }
        }
    }

    private var findingOpponent: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.5)
            Text("Finding opponent...")
                .foregroundStyle(AeroColors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func opponentPreview(_ opp: Opponent) -> some View {
        VStack(spacing: 24) {
            Spacer()

            FighterSpriteView(variant: opp.avatarConfig.selectedVariant, size: 120)

            Text(opp.username)
                .font(.title.bold())
                .foregroundStyle(AeroColors.primaryText)
            Text("Level \(opp.stats.level)")
                .foregroundStyle(AeroColors.secondaryText)

            HStack(spacing: 16) {
                miniStat("STR", value: opp.stats.strength, color: AeroColors.strengthRed)
                miniStat("STA", value: opp.stats.stamina, color: AeroColors.staminaGreen)
                miniStat("SPD", value: opp.stats.speed, color: AeroColors.speedBlue)
            }

            // Difficulty picker
            VStack(spacing: 8) {
                Text("Difficulty")
                    .font(.subheadline)
                    .foregroundStyle(AeroColors.secondaryText)
                Picker("Difficulty", selection: $selectedDifficulty) {
                    ForEach(DifficultyLevel.allCases, id: \.self) { level in
                        Text(level.rawValue.capitalized).tag(level)
                    }
                }
                .pickerStyle(.segmented)
                .tint(AeroColors.primaryAccent)
                .padding(.horizontal, 32)
            }

            Spacer()

            // Real-time fight button
            Button {
                showRealBattle = true
            } label: {
                Text("⚔️ FIGHT")
                    .font(.title2.bold())
            }
            .buttonStyle(AeroButtonStyle())
            .padding(.horizontal)

            // Quick resolve option
            Button {
                quickFight(opp)
            } label: {
                Text("Quick Resolve")
                    .foregroundStyle(AeroColors.secondaryText)
            }

            Button("Find New Opponent") {
                opponent = nil
                Task { await findOpponent() }
            }
            .foregroundStyle(AeroColors.secondaryText)
            .padding(.bottom, 8)
        }
        .padding()
    }

    private func miniStat(_ label: String, value: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title3.bold())
                .foregroundStyle(AeroColors.primaryText)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AeroColors.secondaryText)
        }
        .frame(width: 70)
        .padding(.vertical, 8)
        .aeroCard(cornerRadius: 12)
    }

    private func findOpponent() async {
        opponent = await firestoreService.fetchRandomOpponent()
    }

    private func quickFight(_ opp: Opponent) {
        isFighting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            result = BattleEngine.resolve(player: playerStats, opponent: opp)
            isFighting = false
            if let result {
                Task { await firestoreService.submitBattleResult(result) }
            }
        }
    }
}
