import SwiftUI
import SpriteKit

struct BattleSpriteView: View {
    let playerStats: PlayerStats
    let opponentStats: PlayerStats
    let onBattleEnd: (Bool) -> Void

    @State private var scene: BattleScene?

    var body: some View {
        GeometryReader { geo in
            if let scene {
                SpriteView(scene: scene)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
                    .onAppear {
                        let s = BattleScene(
                            playerStats: playerStats,
                            opponentStats: opponentStats,
                            size: geo.size
                        )
                        s.scaleMode = .resizeFill
                        s.battleDelegate = Coordinator.shared
                        Coordinator.shared.onEnd = onBattleEnd
                        scene = s
                    }
            }
        }
    }

    class Coordinator: NSObject, BattleSceneDelegate {
        static let shared = Coordinator()
        var onEnd: ((Bool) -> Void)?

        func battleDidEnd(playerWon: Bool, playerHP: Int, opponentHP: Int) {
            DispatchQueue.main.async { [weak self] in
                self?.onEnd?(playerWon)
            }
        }
    }
}
