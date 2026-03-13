//
//  ContentView.swift
//  MyLobster
//

import SwiftUI
import UIKit

struct ContentView: View {
    @State private var screen: AppScreen = .title

    @AppStorage("language")         private var langRaw:             String = AppLanguage.zh.rawValue
    @AppStorage("bestChainTime")    private var bestChainTimeRaw:    Double = -1
    @AppStorage("bestSurvivalFood") private var bestSurvivalFoodRaw: Int    = -1
    @AppStorage("tutorialDone")     private var tutorialDone:        Bool   = false

    // AdManager is a plain NSObject — keep it alive for the lifetime of ContentView.
    @State private var adManager = AdManager()

    private var language: AppLanguage { AppLanguage(rawValue: langRaw) ?? .zh }

    private var bestChainTime: TimeInterval? {
        bestChainTimeRaw >= 0 ? bestChainTimeRaw : nil
    }
    private var bestSurvivalFood: Int? {
        bestSurvivalFoodRaw >= 0 ? bestSurvivalFoodRaw : nil
    }

    var body: some View {
        ZStack {
            switch screen {
            case .title:
                TitleView(onPlay: startGame)
                    .transition(.opacity)

            case .game(let mode):
                GameView(
                    mode: mode,
                    language: language,
                    bestChainTime: bestChainTime,
                    bestSurvivalFood: bestSurvivalFood,
                    isTutorialDone: tutorialDone,
                    onGameEnd: handleGameEnd,
                    onQuitToTitle: goToTitle,
                    onTutorialDone: { tutorialDone = true },
                    onWillQuit: handleWillQuit
                )
                .transition(.opacity)

            case .result(let result):
                ResultView(
                    result: result,
                    language: language,
                    bestTime: bestChainTime,
                    bestSurvivalFood: bestSurvivalFood,
                    onRestart: { startGame(result.mode) },
                    onBackToMenu: goToTitle
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.30), value: screenKey)
    }

    private var screenKey: String {
        switch screen {
        case .title:  return "title"
        case .game:   return "game"
        case .result: return "result"
        }
    }

    private func startGame(_ mode: GameMode) {
        screen = .game(mode)
    }

    private func goToTitle() {
        screen = .title
    }

    /// Called just before the player quits to title — updates survival best score if applicable.
    private func handleWillQuit(foodEaten: Int, mode: GameMode) {
        if mode == .survival && foodEaten > bestSurvivalFoodRaw {
            bestSurvivalFoodRaw = foodEaten
        }
    }

    private func handleGameEnd(result: GameResult) {
        // Persist personal bests
        switch result.mode {
        case .chain:
            if result.won {
                if bestChainTimeRaw < 0 || result.completionTime < bestChainTimeRaw {
                    bestChainTimeRaw = result.completionTime
                }
            }
        case .survival:
            if result.foodEaten > bestSurvivalFoodRaw {
                bestSurvivalFoodRaw = result.foodEaten
            }
        }

        // Show interstitial ad, then go to result screen
        showAdThen { screen = .result(result) }
    }

    // MARK: - Ad helper

    /// Notifies AdManager that a game finished; it decides whether to show an ad.
    /// Always calls `action` — either after the ad is dismissed, or immediately.
    private func showAdThen(_ action: @escaping () -> Void) {
        guard let rootVC = UIApplication.shared
            .connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?
            .windows
            .first(where: { $0.isKeyWindow })?
            .rootViewController else {
            action()
            return
        }
        adManager.onGameFinished(from: rootVC, completion: action)
    }
}

#Preview {
    ContentView()
}
