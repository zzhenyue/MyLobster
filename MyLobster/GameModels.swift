//
//  GameModels.swift
//  MyLobster
//

import Foundation

// MARK: - Game Mode

enum GameMode: String, CaseIterable {
    case chain    = "chain"    // Original: eat 30, break chain, progress bar
    case survival = "survival" // Endless: no chain, no limit, grow forever
}

// MARK: - Game State

enum AppScreen {
    case title
    case game(GameMode)
    case result(GameResult)
}

struct GameResult {
    let won:             Bool
    let completionTime:  TimeInterval
    let foodEaten:       Int
    let garbageMistakes: Int
    let mode:            GameMode
}

// MARK: - Object Types

enum ObjectType {
    case food
    case garbage
    case bomb
}

// MARK: - Constants

enum GameConstants {

    // ── Chain Mode ──────────────────────────────────────────────────────────

    /// Number of food items to eat before the chain breaks (win condition)
    static let chainBreakTarget = 30

    /// Food counts at which a chain link visually cracks and flies off
    static let chainCrackMilestones = [7, 14, 21, 28]

    // ── Survival Mode ───────────────────────────────────────────────────────

    /// Starting fall speed in survival mode (slightly faster than chain mode base)
    static let survivalBaseFallSpeed: CGFloat = 520   // pts/sec

    /// Same speed-increase-per-tier as chain mode, applied more aggressively
    static let survivalSpeedIncreaseStep: CGFloat = 40

    // ── Item Spawn Weights ──────────────────────────────────────────────────
    //
    //  HOW TO TUNE:
    //   • food, garbage, bomb are probabilities that must sum to 1.0
    //   • foodEaten brackets let you ramp difficulty over time
    //   • Add more `case` ranges to create additional difficulty phases
    //
    static func spawnWeights(foodEaten: Int,
                             mode: GameMode) -> (food: Double, garbage: Double, bomb: Double) {
        switch mode {
        case .chain:
            switch foodEaten {
            case 0..<15:  return (0.60, 0.25, 0.15)
            case 15..<25: return (0.57, 0.25, 0.18)
            default:      return (0.55, 0.25, 0.20)
            }
        case .survival:
            switch foodEaten {
            case 0..<10:  return (0.62, 0.25, 0.13)
            case 10..<25: return (0.58, 0.26, 0.16)
            case 25..<50: return (0.55, 0.26, 0.19)
            default:      return (0.52, 0.26, 0.22)
            }
        }
    }

    // ── Fall Speed ──────────────────────────────────────────────────────────
    //
    //  HOW TO TUNE:
    //   • baseFallSpeed: starting speed in chain mode (pts/sec)
    //   • speedIncreaseStep: pts/sec added per difficulty tier
    //   • speedTierInterval: food items eaten before moving up one tier (cap = 5 tiers)
    //
    static let baseFallSpeed:      CGFloat = 420   // chain mode starting speed
    static let speedIncreaseStep:  CGFloat = 35    // extra speed per tier
    static let speedTierInterval           = 5     // food items per tier

    static func fallSpeed(foodEaten: Int, mode: GameMode) -> CGFloat {
        let base = mode == .survival ? survivalBaseFallSpeed : baseFallSpeed
        let step = mode == .survival ? survivalSpeedIncreaseStep : speedIncreaseStep
        let tier = min(foodEaten / speedTierInterval, 8)   // survival allows more tiers
        return base + CGFloat(tier) * step
    }

    // ── Input ────────────────────────────────────────────────────────────────
    static let swipeThreshold:          CGFloat       = 55
    static let maxSwipeRecognitionTime: TimeInterval  = 0.35

    // ── Timing ──────────────────────────────────────────────────────────────
    static let vomitDuration:       TimeInterval = 0.6
    static let controlLockDuration: TimeInterval = 0.45
    static let bombDeflectDuration: TimeInterval = 0.2

    // ── Visual Growth ────────────────────────────────────────────────────────
    //
    //  HOW TO TUNE:
    //   • visualGrowthPerFood: fraction of base scale added per food item
    //     – Chain mode: reaches ~2.35× at 30 food (fills width)
    //     – Survival: same formula but unbounded — at 60 food ≈ 3.7×
    //   • lobsterBaseSize: drawing reference (affects chain arc length)
    //
    static let visualGrowthPerFood: CGFloat = 0.045
    static let lobsterBaseSize:     CGFloat = 80

    // ── Tutorial ─────────────────────────────────────────────────────────────
    //
    //  HOW TO TUNE:
    //   • tutorialSequence: the first N objects shown at game start, one per type
    //     to teach the player the swipe rules before random spawning begins.
    //     Reorder or shorten this array to adjust the tutorial.
    //
    static let tutorialSequence: [ObjectType] = [.food, .garbage, .bomb]
}
