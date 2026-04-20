import SwiftUI
import SpriteKit

struct BattleSpriteView: View {
    let playerStats: PlayerStats
    let opponentStats: PlayerStats
    var difficulty: DifficultyLevel = .medium
    var playerAtlas: String = "fighter_default"
    var opponentAtlas: String = "fighter_default"
    var stageID: String = "arena_01"
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
                        // Use the current geometry size (works for both portrait and landscape)
                        let sceneSize = geo.size
                        let s = BattleScene(
                            playerStats: playerStats,
                            opponentStats: opponentStats,
                            size: sceneSize,
                            difficulty: difficulty,
                            playerAtlas: playerAtlas,
                            opponentAtlas: opponentAtlas,
                            stageID: stageID
                        )
                        s.scaleMode = .resizeFill
                        s.battleDelegate = Coordinator.shared
                        Coordinator.shared.onEnd = onBattleEnd
                        scene = s
                    }
            }
        }
        .onAppear {
            // Request landscape for battle
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
                // Also tell the system to auto-rotate
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
        .onDisappear {
            // Restore portrait when leaving battle
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
                UIViewController.attemptRotationToDeviceOrientation()
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
