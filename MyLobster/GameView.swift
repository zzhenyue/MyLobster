//
//  GameView.swift
//  MyLobster
//

import SwiftUI
import SpriteKit

struct GameView: View {
    let mode: GameMode
    let language: AppLanguage
    let bestChainTime:    TimeInterval?
    let bestSurvivalFood: Int?
    let isTutorialDone:   Bool
    let onGameEnd:        (GameResult) -> Void
    let onQuitToTitle:    () -> Void
    let onTutorialDone:   () -> Void
    let onWillQuit:       (Int, GameMode) -> Void   // (foodEaten, mode) — called before quit

    var body: some View {
        GeometryReader { geo in
            SpriteKitGameView(size: geo.size,
                              mode: mode,
                              language: language,
                              bestChainTime: bestChainTime,
                              bestSurvivalFood: bestSurvivalFood,
                              isTutorialDone: isTutorialDone,
                              onGameEnd: onGameEnd,
                              onQuitToTitle: onQuitToTitle,
                              onTutorialDone: onTutorialDone,
                              onWillQuit: onWillQuit)
        }
        .ignoresSafeArea()
    }
}

// MARK: - UIViewRepresentable wrapper

struct SpriteKitGameView: UIViewRepresentable {
    let size: CGSize
    let mode: GameMode
    let language: AppLanguage
    let bestChainTime:    TimeInterval?
    let bestSurvivalFood: Int?
    let isTutorialDone:   Bool
    let onGameEnd:        (GameResult) -> Void
    let onQuitToTitle:    () -> Void
    let onTutorialDone:   () -> Void
    let onWillQuit:       (Int, GameMode) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onGameEnd: onGameEnd,
                    onQuitToTitle: onQuitToTitle,
                    onTutorialDone: onTutorialDone,
                    onWillQuit: onWillQuit)
    }

    func makeUIView(context: Context) -> SKView {
        let view = SKView(frame: CGRect(origin: .zero, size: size))
        view.ignoresSiblingOrder = true
        view.showsFPS       = false
        view.showsNodeCount = false
        view.backgroundColor = .clear

        let scene = GameScene(size: size)
        scene.gameMode          = mode
        scene.language          = language
        scene.bestChainTime     = bestChainTime
        scene.bestSurvivalFood  = bestSurvivalFood
        scene.skipTutorial      = isTutorialDone
        scene.scaleMode         = .aspectFill
        scene.gameDelegate      = context.coordinator
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
        let onGameEnd:      (GameResult) -> Void
        let onQuitToTitle:  () -> Void
        let onTutorialDone: () -> Void
        let onWillQuit:     (Int, GameMode) -> Void

        init(onGameEnd: @escaping (GameResult) -> Void,
             onQuitToTitle: @escaping () -> Void,
             onTutorialDone: @escaping () -> Void,
             onWillQuit: @escaping (Int, GameMode) -> Void) {
            self.onGameEnd      = onGameEnd
            self.onQuitToTitle  = onQuitToTitle
            self.onTutorialDone = onTutorialDone
            self.onWillQuit     = onWillQuit
        }

        func gameDidEnd(result: GameResult) {
            DispatchQueue.main.async { self.onGameEnd(result) }
        }

        func gameDidQuitToTitle() {
            DispatchQueue.main.async { self.onQuitToTitle() }
        }

        func gameWillQuit(foodEaten: Int, mode: GameMode) {
            DispatchQueue.main.async { self.onWillQuit(foodEaten, mode) }
        }

        func tutorialDidComplete() {
            DispatchQueue.main.async { self.onTutorialDone() }
        }
    }
}

#Preview {
    GameView(mode: .chain, language: .zh,
             bestChainTime: nil, bestSurvivalFood: nil,
             isTutorialDone: false,
             onGameEnd: { _ in }, onQuitToTitle: {}, onTutorialDone: {}, onWillQuit: { _, _ in })
}
