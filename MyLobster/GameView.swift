//
//  GameView.swift
//  MyLobster
//

import SwiftUI
import SpriteKit

struct GameView: View {
    let mode: GameMode
    let onGameEnd: (GameResult) -> Void
    let onQuitToTitle: () -> Void

    var body: some View {
        GeometryReader { geo in
            SpriteKitGameView(size: geo.size, mode: mode,
                              onGameEnd: onGameEnd, onQuitToTitle: onQuitToTitle)
        }
        .ignoresSafeArea()
    }
}

// MARK: - UIViewRepresentable wrapper

struct SpriteKitGameView: UIViewRepresentable {
    let size: CGSize
    let mode: GameMode
    let onGameEnd: (GameResult) -> Void
    let onQuitToTitle: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onGameEnd: onGameEnd, onQuitToTitle: onQuitToTitle)
    }

    func makeUIView(context: Context) -> SKView {
        let view = SKView(frame: CGRect(origin: .zero, size: size))
        view.ignoresSiblingOrder = true
        view.showsFPS       = false
        view.showsNodeCount = false
        view.backgroundColor = .clear

        let scene = GameScene(size: size)
        scene.gameMode     = mode
        scene.scaleMode    = .aspectFill
        scene.gameDelegate = context.coordinator
        view.presentScene(scene)

        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        if let scene = uiView.scene, scene.size != size {
            scene.size = size
        }
    }

    // MARK: Coordinator
    class Coordinator: NSObject, GameSceneDelegate {
        let onGameEnd:    (GameResult) -> Void
        let onQuitToTitle: () -> Void

        init(onGameEnd: @escaping (GameResult) -> Void,
             onQuitToTitle: @escaping () -> Void) {
            self.onGameEnd     = onGameEnd
            self.onQuitToTitle = onQuitToTitle
        }

        func gameDidEnd(result: GameResult) {
            DispatchQueue.main.async { self.onGameEnd(result) }
        }

        func gameDidQuitToTitle() {
            DispatchQueue.main.async { self.onQuitToTitle() }
        }
    }
}

#Preview {
    GameView(mode: .chain, onGameEnd: { _ in }, onQuitToTitle: {})
}
