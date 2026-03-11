//
//  ContentView.swift
//  MyLobster
//

import SwiftUI

struct ContentView: View {
    @State private var screen: AppScreen = .title
    @AppStorage("bestChainTime")    private var bestChainTimeRaw:    Double = -1
    @AppStorage("bestSurvivalFood") private var bestSurvivalFoodRaw: Int    = -1

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
                    onGameEnd: handleGameEnd,
                    onQuitToTitle: goToTitle
                )
                .transition(.opacity)

            case .result(let result):
                ResultView(
                    result: result,
                    bestTime: bestChainTime,
                    bestSurvivalFood: bestSurvivalFood,
                    onRestart: { startGame(result.mode) }
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
        screen = .result(result)
    }
}

#Preview {
    ContentView()
}
