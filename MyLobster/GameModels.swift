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
    static let survivalBaseFallSpeed: CGFloat = 640   // pts/sec

    /// Same speed-increase-per-tier as chain mode, applied more aggressively
    static let survivalSpeedIncreaseStep: CGFloat = 55

    // ── Item Spawn Weights ──────────────────────────────────────────────────
    //
    //  Equal 1/3 probability for food, garbage, and bomb in both modes.
    //  The `foodEaten` and `mode` parameters are kept for future tuning.
    //
    static func spawnWeights(foodEaten: Int,
                             mode: GameMode) -> (food: Double, garbage: Double, bomb: Double) {
        return (1.0/2.0, 1.0/4.0, 1.0/4.0)
    }

    // ── Fall Speed ──────────────────────────────────────────────────────────
    //
    //  HOW TO TUNE:
    //   • baseFallSpeed: starting speed in chain mode (pts/sec)
    //   • speedIncreaseStep: pts/sec added per difficulty tier
    //   • speedTierInterval: food items eaten before moving up one tier (cap = 5 tiers)
    //
    static let baseFallSpeed:      CGFloat = 620   // chain mode starting speed
    static let speedIncreaseStep:  CGFloat = 55    // extra speed per tier
    static let speedTierInterval           = 5     // food items per tier

    static func fallSpeed(foodEaten: Int, mode: GameMode) -> CGFloat {
        let base = mode == .survival ? survivalBaseFallSpeed : baseFallSpeed
        let step = mode == .survival ? survivalSpeedIncreaseStep : speedIncreaseStep
        let tier = min(foodEaten / speedTierInterval, 8)   // survival allows more tiers
        return base + CGFloat(tier) * step
    }

    // ── Spawn Interval ──────────────────────────────────────────────────────
    //
    //  Two-mechanism spawning:
    //   1. A repeating TIMER fires every spawnInterval() seconds (background pace),
    //      so multiple objects can be on screen simultaneously.
    //   2. A TRIGGER-SPAWN fires immediately whenever an object is handled AND
    //      the screen is now empty — guaranteeing the player never sees a blank screen.
    //
    //  The timer interval shrinks as food is eaten (same tier system as fall speed).
    //
    static let spawnIntervalBase:          TimeInterval = 1.2   // timer period at tier 0
    static let spawnIntervalFloor:         TimeInterval = 0.5   // timer period floor
    static let spawnIntervalDecayPerTier:  TimeInterval = 0.09  // timer shrinks per tier

    /// Background timer interval (how often the clock independently fires a spawn).
    static func spawnInterval(foodEaten: Int) -> TimeInterval {
        let tier = min(foodEaten / speedTierInterval, 8)
        return max(spawnIntervalBase - Double(tier) * spawnIntervalDecayPerTier,
                   spawnIntervalFloor)
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
