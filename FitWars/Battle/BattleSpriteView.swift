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
    @State private var hasRequestedLandscape = false

    var body: some View {
        GeometryReader { geo in
            if let scene {
                SpriteView(scene: scene)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
                    .onChange(of: geo.size) { _, newSize in
                        // Wait until we get landscape dimensions (width > height)
                        // or just create after a short delay
                        if scene == nil && hasRequestedLandscape && newSize.width > 100 {
                            createScene(size: newSize)
                        }
                    }
                    .onAppear {
                        // Request landscape
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
                        }
                        hasRequestedLandscape = true
                        
                        // Fallback: create scene after delay if onChange doesn't fire
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if scene == nil {
                                createScene(size: geo.size)
                            }
                        }
                    }
            }
        }
        .onDisappear {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            }
        }
    }

    private func createScene(size: CGSize) {
        // Ensure we use landscape-oriented dimensions
        let sceneSize: CGSize
        if size.width > size.height {
            sceneSize = size
        } else {
            // Still in portrait — swap dimensions
            sceneSize = CGSize(width: size.height, height: size.width)
        }
        
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
