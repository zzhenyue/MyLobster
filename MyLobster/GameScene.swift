//
//  GameScene.swift
//  MyLobster
//  Pixel-art style – square corners, pixel palette, blocky animations.
//
//  SWIPE RULES:
//    FOOD    → swipe DOWN = eat (good). Any other = miss, flies away.
//    GARBAGE → swipe RIGHT = net catches it (good). Any other = vomit penalty.
//    BOMB    → swipe LEFT = hand takes it (safe). Any other = EXPLODE.
//
//  GAME MODES:
//    .chain    – eat chainBreakTarget food to win; progress bar + chain shown.
//    .survival – endless; no chain; lobster grows forever; game ends only on bomb.

import SpriteKit
import UIKit
import AVFoundation

// MARK: - Delegate

protocol GameSceneDelegate: AnyObject {
    func gameDidEnd(result: GameResult)
    func gameDidQuitToTitle()                              // quit goes back to title, not result
    func gameWillQuit(foodEaten: Int, mode: GameMode)     // called before quit so caller can update best score
    func tutorialDidComplete()                             // persist tutorial-done flag in AppStorage
}

// MARK: - Pixel palette

private enum Px {
    static let navy      = SKColor(red: 0.04, green: 0.07, blue: 0.16, alpha: 1)
    static let ocean1    = SKColor(red: 0.06, green: 0.12, blue: 0.24, alpha: 1)
    static let ocean2    = SKColor(red: 0.08, green: 0.18, blue: 0.32, alpha: 1)
    static let ocean3    = SKColor(red: 0.10, green: 0.24, blue: 0.40, alpha: 1)
    static let sand      = SKColor(red: 0.55, green: 0.44, blue: 0.26, alpha: 1)
    static let white     = SKColor(red: 0.92, green: 0.92, blue: 0.86, alpha: 1)
    static let dimWhite  = SKColor(red: 0.92, green: 0.92, blue: 0.86, alpha: 0.45)
    static let green     = SKColor(red: 0.10, green: 0.72, blue: 0.22, alpha: 1)
    static let darkGreen = SKColor(red: 0.06, green: 0.38, blue: 0.10, alpha: 1)
    static let amber     = SKColor(red: 0.95, green: 0.72, blue: 0.06, alpha: 1)
    static let red       = SKColor(red: 0.90, green: 0.14, blue: 0.10, alpha: 1)
    static let orange    = SKColor(red: 0.95, green: 0.46, blue: 0.06, alpha: 1)
    static let steel     = SKColor(red: 0.52, green: 0.56, blue: 0.64, alpha: 1)
    static let darkSteel = SKColor(red: 0.22, green: 0.24, blue: 0.30, alpha: 1)
    static let lobRed    = SKColor(red: 0.88, green: 0.26, blue: 0.06, alpha: 1)
    static let lobDark   = SKColor(red: 0.58, green: 0.10, blue: 0.02, alpha: 1)
    static let lobShell  = SKColor(red: 0.72, green: 0.18, blue: 0.04, alpha: 1)
    static let mud       = SKColor(red: 0.18, green: 0.14, blue: 0.10, alpha: 1)
    static let nearBlack = SKColor(red: 0.08, green: 0.06, blue: 0.06, alpha: 1)
    static let survivalGold = SKColor(red: 0.96, green: 0.82, blue: 0.10, alpha: 1)
}

// MARK: - Pixel helper

/// Returns a rect SKShapeNode (cornerRadius 0 = pixel style)
private func px(_ w: CGFloat, _ h: CGFloat,
                fill: SKColor, stroke: SKColor = .clear, sw: CGFloat = 0) -> SKShapeNode {
    let n = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: 0)
    n.fillColor   = fill
    n.strokeColor = stroke
    n.lineWidth   = sw
    return n
}

// MARK: - Falling Object Node

class FallingObjectNode: SKNode {
    let objectType: ObjectType
    var isResolved = false

    init(type: ObjectType) {
        self.objectType = type
        super.init()

        let (bgColor, rimColor, iconName, iconTint) = Self.style(for: type)

        // Square pixel tile background
        let tile = px(60, 60, fill: bgColor, stroke: rimColor, sw: 3)
        tile.zPosition = 0
        addChild(tile)

        // 2-pixel highlight at top edge
        let hiLine = px(60, 2, fill: rimColor.withAlphaComponent(0.5))
        hiLine.position = CGPoint(x: 0, y: 29)
        hiLine.zPosition = 1
        addChild(hiLine)

        // SF Symbol icon
        let icon = symbolSprite(named: iconName, size: 38, tint: iconTint)
        icon.zPosition = 2
        addChild(icon)

        // Bomb: square wiggle
        if type == .bomb {
            let wiggle = SKAction.repeat(SKAction.sequence([
                SKAction.rotate(byAngle:  0.10, duration: 0.07),
                SKAction.rotate(byAngle: -0.20, duration: 0.14),
                SKAction.rotate(byAngle:  0.10, duration: 0.07),
                SKAction.wait(forDuration: 0.55)
            ]), count: 200)
            run(wiggle)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    private static func style(for type: ObjectType) -> (SKColor, SKColor, String, UIColor) {
        switch type {
        case .food:
            let items: [(String, UIColor)] = [
                ("fork.knife",    UIColor(red: 0.95, green: 0.88, blue: 0.20, alpha: 1)),
                ("birthday.cake", UIColor(red: 1.00, green: 0.70, blue: 0.30, alpha: 1)),
                ("fish",          UIColor(red: 0.40, green: 0.80, blue: 1.00, alpha: 1)),
                ("carrot",        UIColor(red: 1.00, green: 0.60, blue: 0.15, alpha: 1)),
                ("leaf.fill",     UIColor(red: 0.30, green: 0.95, blue: 0.35, alpha: 1)),
                ("flame.fill",    UIColor(red: 1.00, green: 0.70, blue: 0.20, alpha: 1)),
                ("popcorn.fill",  UIColor(red: 1.00, green: 0.92, blue: 0.40, alpha: 1)),
            ]
            let (sym, tint) = items.randomElement()!
            return (Px.darkGreen, Px.green, sym, tint)

        case .garbage:
            let items: [(String, UIColor)] = [
                ("trash.fill",       UIColor(red: 0.60, green: 0.60, blue: 0.60, alpha: 1)),
                ("bag.fill",         UIColor(red: 0.52, green: 0.46, blue: 0.42, alpha: 1)),
                ("shoe.fill",        UIColor(red: 0.50, green: 0.40, blue: 0.32, alpha: 1)),
                ("tshirt.fill",      UIColor(red: 0.46, green: 0.46, blue: 0.52, alpha: 1)),
                ("battery.0percent", UIColor(red: 0.54, green: 0.54, blue: 0.54, alpha: 1)),
            ]
            let (sym, tint) = items.randomElement()!
            return (Px.mud, SKColor(red: 0.38, green: 0.32, blue: 0.28, alpha: 1), sym, tint)

        case .bomb:
            return (Px.nearBlack, Px.red,
                    "bolt.fill", UIColor(red: 1.0, green: 0.22, blue: 0.12, alpha: 1))
        }
    }
}

// MARK: - Game Scene

class GameScene: SKScene {

    // MARK: Configuration
    var gameMode: GameMode    = .chain
    var language: AppLanguage = .zh   // passed from ContentView; controls all in-game text
    var skipTutorial: Bool    = false // set true after first-play tutorial completes

    // Personal bests (passed in from ContentView so the record box can show them)
    var bestChainTime:    TimeInterval? = nil
    var bestSurvivalFood: Int?          = nil

    // MARK: Delegate
    weak var gameDelegate: GameSceneDelegate?

    // MARK: Tutorial state machine
    // Steps: 0=food, 1=garbage, 2=bomb, 3=tapToPause, 4=done (normal play)
    private enum TutStep { case food, garbage, bomb, tapToPause, done }
    private var tutStep: TutStep = .food
    // When true the current object is frozen in place waiting for the correct gesture
    private var isTutorialFrozen = false
    // Overlay node shown during each tutorial step
    private var tutOverlay: SKNode?

    // MARK: State
    private var foodEaten       = 0
    private var garbageMistakes = 0
    private var isControlLocked = false
    private var isPaused_game   = false
    private var isGameOver      = false   // set true on bomb/win; blocks all further outcomes
    private var spawnLaneIndex  = 0       // cycles through lanes independently of activeObjects.count

    // Timer — we track elapsed manually so pause truly freezes it
    private var pauseStartTime: Date?
    private var totalPausedSeconds: TimeInterval = 0
    private var gameStartTime  = Date()
    private var elapsedTime:   TimeInterval = 0

    // MARK: Nodes
    private var pauseOverlay:       SKNode?
    private var lobsterContainer:   SKNode!
    private var lobsterBody:        SKShapeNode!
    private var lobsterMouth:       SKShapeNode!
    private var lobsterMouthInner:  SKShapeNode!
    private var lobsterLeftEye:     SKShapeNode!
    private var lobsterRightEye:    SKShapeNode!
    private var lobsterLeftPupil:   SKShapeNode!
    private var lobsterRightPupil:  SKShapeNode!
    private var mouthClosedPath:    CGPath!
    private var mouthOpenPath:      CGPath!
    private var chainLinks:         [SKNode] = []
    private var progressBarFill:    SKShapeNode?
    private var feedbackLabel:      SKLabelNode!
    private var hintLabel:          SKLabelNode!
    private var currentScoreLabel:  SKLabelNode!   // left seaweed box – live score
    private var recordLabel:        SKLabelNode!   // right seaweed box – best score
    private var pauseIndicator:     SKNode!        // "||" icon drawn on the lobster body
    // Tutorial uses a single object; normal play allows multiple concurrent objects.
    private var activeObjects:      [FallingObjectNode] = []
    // Convenience: during tutorial the one tutorial object is always activeObjects.first
    private var currentObject: FallingObjectNode? { activeObjects.first }

    // Convenience localisation accessor
    private var loc: L { L(lang: language) }

    // MARK: Audio
    private var bgMusicPlayer: AVAudioPlayer?
    // Pre-loaded SFX players — keyed by filename (no extension).
    // Using AVAudioPlayer instead of SKAction.playSoundFileNamed eliminates
    // the first-play decode stutter because players are prepared at scene load.
    private var sfxPlayers: [String: AVAudioPlayer] = [:]

    // MARK: Swipe tracking
    private var swipeStart     = CGPoint.zero
    private var swipeTime      = Date()
    private var swipeActive    = false
    private var lastSwipeDelta = CGPoint.zero

    // MARK: Layout  (anchorPoint 0.5,0.5 → origin at screen centre)
    private var W: CGFloat { size.width  }
    private var H: CGFloat { size.height }

    // Both modes: lobster sits near the sand floor.
    private var lobsterY: CGFloat { -H * 0.42 + bodyH / 2 }
    private var spawnY:   CGFloat { H * 0.48 }
    private var barY:     CGFloat { H * 0.36 }
    private var hintY:    CGFloat { -H * 0.455 }
    // Chain: floor anchor plate sits on the sand, chain links connect floor → lobster tail
    private var chainFloorY: CGFloat { -H / 2 + 22 }   // just above the sand floor

    private let bodyW: CGFloat = 56
    private let bodyH: CGFloat = 60

    // MARK: - Scene Entry

    override func didMove(to view: SKView) {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        buildBackground()
        if gameMode == .chain {
            buildProgressBar()
            buildChain()
        }
        buildLobster()
        buildHUD()        // also calls buildSidePanels() internally
        buildHintLabel()
        gameStartTime = Date()
        totalPausedSeconds = 0
        if skipTutorial { tutStep = .done }
        preloadAllSFX()   // warm up audio decoder to prevent first-play freeze
        startBackgroundMusic()
        spawnNextObject()
        run(SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: 0.05),
            SKAction.run { [weak self] in self?.tickTimer() }
        ])), withKey: "timer")
    }

    /// Loads all SFX files into AVAudioPlayer instances and calls prepareToPlay()
    /// so the audio hardware and codec are initialised at scene load, not at
    /// first gameplay use.  Subsequent calls to playSFX() reuse these players,
    /// completely eliminating the first-play decode freeze.
    private func preloadAllSFX() {
        let sfxFiles = [
            "sfx_chomp.m4a", "sfx_net.m4a", "sfx_catch.m4a",
            "sfx_bletch.m4a", "sfx_boom.m4a", "sfx_win.m4a",
            "sfx_whoosh.m4a", "sfx_pause.m4a"
        ]
        for filename in sfxFiles {
            let parts = filename.components(separatedBy: ".")
            guard parts.count == 2 else { continue }
            let base = parts[0]
            let ext  = parts[1]
            let url  = Bundle.main.url(forResource: base, withExtension: ext,
                                       subdirectory: "Sounds")
                    ?? Bundle.main.url(forResource: base, withExtension: ext)
            guard let url else { continue }
            if let player = try? AVAudioPlayer(contentsOf: url) {
                player.volume = 0.85
                player.prepareToPlay()   // pre-buffers — no audible sound yet
                sfxPlayers[base] = player
            }
        }
    }

    // MARK: - Background (pixel ocean bands + dithered bubbles)

    private func buildBackground() {
        backgroundColor = Px.navy

        let bands: [SKColor] = [Px.navy, Px.ocean1, Px.ocean2, Px.ocean3, Px.ocean3]
        let bH = H / CGFloat(bands.count)
        for (i, col) in bands.enumerated() {
            let b = SKSpriteNode(color: col, size: CGSize(width: W, height: bH))
            b.position  = CGPoint(x: 0, y: -H/2 + bH/2 + CGFloat(i) * bH)
            b.zPosition = -10
            addChild(b)
        }

        spawnPixelBubbles(count: 8)
        run(SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: 1.8),
            SKAction.run { [weak self] in self?.spawnPixelBubbles(count: 1) }
        ])))

        // Pixel sandy floor
        let floor = px(W, 16, fill: Px.sand)
        floor.position  = CGPoint(x: 0, y: -H/2 + 8)
        floor.zPosition = 2
        addChild(floor)

        let floor2 = px(W, 6, fill: SKColor(red: 0.44, green: 0.34, blue: 0.18, alpha: 1))
        floor2.position  = CGPoint(x: 0, y: -H/2 + 20)
        floor2.zPosition = 2
        addChild(floor2)

        // Tall pixel seaweed columns — left side holds the pause button, right holds the record box.
        // The boxes themselves are built in buildSidePanels(); here we just draw the stalks.
        buildSeaweedStalk(xPos: -W * 0.38, segments: 14)
        buildSeaweedStalk(xPos:  W * 0.38, segments: 14)
    }

    private func spawnPixelBubbles(count: Int = 6) {
        for _ in 0..<count {
            let size = CGFloat(Int.random(in: 2...5)) * 2
            let bub  = px(size, size,
                          fill:   Px.white.withAlphaComponent(CGFloat.random(in: 0.04...0.10)),
                          stroke: Px.white.withAlphaComponent(0.18), sw: 1)
            bub.position  = CGPoint(x: CGFloat.random(in: -W/2...W/2), y: -H/2)
            bub.zPosition = -3
            addChild(bub)
            let rise = SKAction.moveBy(x: 0, y: H + 20,
                                       duration: Double.random(in: 5...11))
            bub.run(SKAction.sequence([rise, SKAction.removeFromParent()]))
        }
    }

    // MARK: - Progress Bar (chain mode only)

    private func buildProgressBar() {
        let bw = W * 0.68, bh: CGFloat = 14

        let border = px(bw + 4, bh + 4, fill: Px.darkSteel)
        border.position  = CGPoint(x: 0, y: barY)
        border.zPosition = 5
        addChild(border)

        let bg = px(bw, bh, fill: Px.navy)
        bg.position  = CGPoint(x: 0, y: barY)
        bg.zPosition = 6
        addChild(bg)

        progressBarFill = makeFill(bw: bw, bh: bh, ratio: 0)
        addChild(progressBarFill!)

        let cap = pixelLabel("\(loc.chainLabel): 0/\(GameConstants.chainBreakTarget)", size: 10,
                              color: Px.dimWhite)
        cap.name     = "barCaption"
        cap.position = CGPoint(x: 0, y: barY + bh/2 + 7)
        cap.zPosition = 8
        addChild(cap)
    }

    private func makeFill(bw: CGFloat, bh: CGFloat, ratio: CGFloat) -> SKShapeNode {
        let fw  = max(bw * ratio, 2)
        let fill: SKColor = ratio < 0.7 ? Px.green : Px.amber
        let f   = px(fw, bh - 2, fill: fill)
        f.position  = CGPoint(x: -bw/2 + fw/2, y: barY)
        f.zPosition = 7
        return f
    }

    // MARK: - Pixel Lobster

    private func buildLobster() {
        lobsterContainer          = SKNode()
        lobsterContainer.position = CGPoint(x: 0, y: lobsterY)
        lobsterContainer.zPosition = 10
        addChild(lobsterContainer)

        // ── Tail ──
        let tailOffsets: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (-16, -bodyH/2 - 14, 10, 14),
            (  0, -bodyH/2 - 18, 14, 18),
            ( 16, -bodyH/2 - 14, 10, 14),
        ]
        for (x, y, w, h) in tailOffsets {
            let t = px(w, h, fill: Px.lobDark, stroke: Px.lobShell, sw: 1)
            t.position  = CGPoint(x: x, y: y + h/2)
            t.zPosition = 8
            lobsterContainer.addChild(t)
            let rib = px(w - 4, 2, fill: Px.lobShell.withAlphaComponent(0.6))
            rib.position  = CGPoint(x: x, y: y + h/2 + 2)
            rib.zPosition = 9
            lobsterContainer.addChild(rib)
        }

        // ── Arms ──
        for side: CGFloat in [-1, 1] {
            let arm = px(8, 24, fill: Px.lobDark, stroke: Px.lobShell, sw: 1)
            arm.position  = CGPoint(x: side * (bodyW/2 + 4), y: 2)
            arm.zPosition = 9
            lobsterContainer.addChild(arm)
        }

        // ── Claws ──
        for side: CGFloat in [-1, 1] {
            let claw = px(22, 16, fill: Px.lobRed, stroke: Px.lobDark, sw: 1.5)
            claw.position  = CGPoint(x: side * (bodyW/2 + 16), y: -2)
            claw.zPosition = 9
            lobsterContainer.addChild(claw)
            let pincer = px(10, 8, fill: Px.lobDark)
            pincer.position  = CGPoint(x: side * (bodyW/2 + 28), y: 2)
            pincer.zPosition = 9
            lobsterContainer.addChild(pincer)
            let hl = px(4, 4, fill: Px.white.withAlphaComponent(0.28))
            hl.position  = CGPoint(x: side * (bodyW/2 + 12), y: 0)
            hl.zPosition = 10
            lobsterContainer.addChild(hl)
        }

        // ── Body ──
        lobsterBody           = px(bodyW, bodyH, fill: Px.lobRed, stroke: Px.lobDark, sw: 2)
        lobsterBody.zPosition = 10
        lobsterContainer.addChild(lobsterBody)

        let sheen = px(14, 6, fill: Px.white.withAlphaComponent(0.20))
        sheen.position  = CGPoint(x: -bodyW/2 + 10, y: bodyH/2 - 8)
        sheen.zPosition = 11
        lobsterContainer.addChild(sheen)

        for i in 0..<4 {
            let seg = px(bodyW - 8, 2, fill: Px.lobShell)
            seg.position  = CGPoint(x: 0, y: -bodyH/2 + 12 + CGFloat(i) * 10)
            seg.zPosition = 11
            lobsterContainer.addChild(seg)
        }

        // ── Antennae ──
        for side: CGFloat in [-1, 1] {
            for j in 0..<5 {
                let seg = px(4, 4, fill: Px.lobDark)
                seg.position  = CGPoint(x: side * (CGFloat(j) * 5 + 8),
                                        y: bodyH/2 + CGFloat(j) * 6)
                seg.zPosition = 11
                lobsterContainer.addChild(seg)
            }
        }

        // ── Eyes ──
        for side: CGFloat in [-1, 1] {
            let stalk = px(4, 8, fill: Px.lobDark)
            stalk.position  = CGPoint(x: side * 10, y: bodyH/2 + 4)
            stalk.zPosition = 11
            lobsterContainer.addChild(stalk)

            let white = px(8, 8, fill: Px.white, stroke: Px.lobDark, sw: 1)
            white.position  = CGPoint(x: side * 12, y: bodyH/2 + 11)
            white.zPosition = 12
            lobsterContainer.addChild(white)

            let pupil = px(4, 4, fill: Px.navy)
            pupil.position  = CGPoint(x: side * 12, y: bodyH/2 + 12)
            pupil.zPosition = 13
            lobsterContainer.addChild(pupil)
            if side < 0 { lobsterLeftEye = white;  lobsterLeftPupil  = pupil }
            else         { lobsterRightEye = white; lobsterRightPupil = pupil }
        }

        // ── Mouth ──
        buildMouthPaths()
        lobsterMouthInner             = SKShapeNode()
        lobsterMouthInner.fillColor   = SKColor(red: 0.10, green: 0.0, blue: 0.0, alpha: 1)
        lobsterMouthInner.strokeColor = .clear
        lobsterMouthInner.zPosition   = 12
        lobsterMouthInner.isHidden    = true
        lobsterContainer.addChild(lobsterMouthInner)

        lobsterMouth             = SKShapeNode()
        lobsterMouth.path        = mouthClosedPath
        lobsterMouth.strokeColor = Px.lobDark
        lobsterMouth.fillColor   = .clear
        lobsterMouth.lineWidth   = 2
        lobsterMouth.zPosition   = 13
        lobsterContainer.addChild(lobsterMouth)

        // Bob
        let up = SKAction.moveBy(x: 0, y: 6, duration: 0.9)
        up.timingMode = .linear
        lobsterContainer.run(
            SKAction.repeatForever(SKAction.sequence([up, up.reversed()])),
            withKey: "bob"
        )
    }

    private func buildMouthPaths() {
        let my = -bodyH/2 + 14
        let closed = CGMutablePath()
        closed.move(to:    CGPoint(x: -10, y: my))
        closed.addLine(to: CGPoint(x:  10, y: my))
        mouthClosedPath = closed

        let open = CGMutablePath()
        open.move(to:    CGPoint(x: -12, y: my + 2))
        open.addLine(to: CGPoint(x:  12, y: my + 2))
        open.addLine(to: CGPoint(x:  12, y: my - 10))
        open.addLine(to: CGPoint(x: -12, y: my - 10))
        open.closeSubpath()
        mouthOpenPath = open
    }

    private func setMouthOpen(_ open: Bool) {
        lobsterMouth.path          = open ? mouthOpenPath : mouthClosedPath
        lobsterMouthInner.path     = open ? mouthOpenPath : nil
        lobsterMouthInner.isHidden = !open
    }

    private func showXEyes(_ show: Bool) {
        lobsterLeftPupil.isHidden  = show
        lobsterRightPupil.isHidden = show
        let sickGreen = SKColor(red: 0.20, green: 0.70, blue: 0.12, alpha: 1)
        lobsterLeftEye.fillColor  = show ? sickGreen : Px.white
        lobsterRightEye.fillColor = show ? sickGreen : Px.white
    }

    // MARK: - Chain (chain mode only)
    // The chain anchors to the sandy floor and connects upward to the lobster's tail.

    private func buildChain() {
        // Floor anchor plate — bolted into the sand
        let plate = px(36, 14, fill: Px.darkSteel, stroke: Px.steel, sw: 1.5)
        plate.position  = CGPoint(x: 0, y: chainFloorY)
        plate.zPosition = 8
        addChild(plate)
        for xOff: CGFloat in [-9, 0, 9] {
            let bolt = px(4, 4, fill: Px.steel)
            bolt.position = CGPoint(x: xOff, y: 0)
            plate.addChild(bolt)
        }

        // Chain links — rise from floor plate to lobster tail
        let bottomY = chainFloorY + 10
        let topY    = lobsterY - bodyH / 2 - 4
        let count   = 8
        let spacing = (topY - bottomY) / CGFloat(count)

        for i in 0..<count {
            let container = SKNode()
            container.position = CGPoint(x: 0, y: bottomY + CGFloat(i) * spacing)
            container.zPosition = 8
            addChild(container)
            chainLinks.append(container)

            let isEven = (i % 2 == 0)
            let ow: CGFloat = isEven ? 20 : 12
            let oh: CGFloat = isEven ? 12 : 22

            let outer = px(ow, oh, fill: Px.steel, stroke: Px.darkSteel, sw: 2)
            container.addChild(outer)
            let inner = px(ow * 0.42, oh * 0.42, fill: Px.ocean1)
            inner.zPosition = 1
            container.addChild(inner)
            let hl = px(ow * 0.38, 2, fill: Px.white.withAlphaComponent(0.22))
            hl.position  = CGPoint(x: -ow * 0.08, y: oh * 0.20)
            hl.zPosition = 2
            container.addChild(hl)
        }
    }

    private func strainChain() {
        guard gameMode == .chain else { return }
        let ratio = CGFloat(max(foodEaten, 0)) / CGFloat(GameConstants.chainBreakTarget)
        let r = min(0.52 + ratio * 0.48, 1.0)
        let g = max(0.56 - ratio * 0.54, 0.0)
        let b = max(0.64 - ratio * 0.62, 0.0)
        let hot = SKColor(red: r, green: g, blue: b, alpha: 1)

        for container in chainLinks {
            if let outer = container.children.first as? SKShapeNode {
                outer.fillColor = hot
            }
        }

        if let idx = GameConstants.chainCrackMilestones.firstIndex(of: foodEaten),
           idx < chainLinks.count {
            let snap = chainLinks[chainLinks.count - 1 - idx]   // crack from top downward
            spawnPixelSparks(at: snap.position, color: Px.amber, count: 10)
            snap.run(SKAction.sequence([
                SKAction.group([
                    SKAction.rotate(byAngle: CGFloat.random(in: -.pi ... .pi), duration: 0.18),
                    SKAction.scale(to: 2.0, duration: 0.12),
                    SKAction.fadeOut(withDuration: 0.14)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - Seaweed helper

    /// Draws a single zigzag seaweed stalk rooted at the sand floor, growing upward.
    /// `segments` controls height (~8px per segment).
    @discardableResult
    private func buildSeaweedStalk(xPos: CGFloat, segments: Int) -> CGFloat {
        let col = SKColor(red: 0.10, green: 0.50, blue: 0.18, alpha: 0.85)
        let segH: CGFloat = 8
        let baseY = -H/2 + 28
        for j in 0..<segments {
            let seg = px(6, segH, fill: col)
            seg.position  = CGPoint(x: xPos + (j % 2 == 0 ? 4 : -4),
                                    y: baseY + CGFloat(j) * segH)
            seg.zPosition = 3
            addChild(seg)
        }
        // Return the y-top of this stalk
        return baseY + CGFloat(segments) * segH
    }

    // MARK: - HUD (side panels only — top timer/food box removed)

    private func buildHUD() {
        // Feedback flash label above the lobster — bigger for visibility
        feedbackLabel          = pixelLabel("", size: 28, color: Px.white)
        feedbackLabel.position  = CGPoint(x: 0, y: lobsterY + bodyH + 42)
        feedbackLabel.zPosition = 22
        addChild(feedbackLabel)

        // Build the seaweed-tied side panels (current score left, best record right)
        buildSidePanels()
    }

    private func buildHintLabel() {
        hintLabel          = pixelLabel("", size: 13, color: Px.dimWhite)
        hintLabel.position  = CGPoint(x: 0, y: hintY)
        hintLabel.zPosition = 20
        addChild(hintLabel)
    }

    // MARK: - Side panels tied to seaweed

    /// Left panel  = current score (time in chain mode, food count in survival).
    /// Right panel = personal best (best time in chain, best food count in survival).
    /// Both are pixel boxes "tied" to the top of their seaweed stalk by a thin rope.
    /// Pause is now triggered by tapping the lobster — no standalone pause box.
    private func buildSidePanels() {
        let seaweedSegments = 14
        let segH: CGFloat   = 8
        let baseY           = -H/2 + 28
        let stalkTopY       = baseY + CGFloat(seaweedSegments) * segH   // top of stalk
        let panelW: CGFloat = 84
        let panelH: CGFloat = 64
        let ropeLen: CGFloat = 10   // pixels of rope between stalk top and box bottom

        let leftX  = -W * 0.36
        let rightX =  W * 0.36

        // ── Rope from stalk top to box ──
        for side: CGFloat in [-1, 1] {
            let xPos = side < 0 ? leftX : rightX
            for r in 0..<Int(ropeLen / 4) {
                let bead = px(2, 4, fill: Px.darkSteel)
                bead.position  = CGPoint(x: xPos, y: stalkTopY + CGFloat(r) * 4 + 2)
                bead.zPosition = 4
                addChild(bead)
            }
        }

        let boxY = stalkTopY + ropeLen + panelH / 2

        // ── LEFT: Current score box (amber border) ──
        let currentBox         = SKNode()
        currentBox.position     = CGPoint(x: leftX, y: boxY)
        currentBox.zPosition    = 19
        addChild(currentBox)

        let curBg = px(panelW, panelH, fill: Px.navy, stroke: Px.amber, sw: 2)
        currentBox.addChild(curBg)

        let curTitle = pixelLabel(loc.nowLabel, size: 11, color: Px.amber)
        curTitle.position  = CGPoint(x: 0, y: 16)
        currentBox.addChild(curTitle)

        currentScoreLabel           = pixelLabel(currentScoreText, size: 15, color: Px.white)
        currentScoreLabel.position   = CGPoint(x: 0, y: -4)
        currentScoreLabel.zPosition  = 20
        currentBox.addChild(currentScoreLabel)

        // ── RIGHT: Best record box (gold border) ──
        let recordBox          = SKNode()
        recordBox.position      = CGPoint(x: rightX, y: boxY)
        recordBox.zPosition     = 19
        addChild(recordBox)

        let recBg = px(panelW, panelH, fill: Px.navy, stroke: Px.survivalGold, sw: 2)
        recordBox.addChild(recBg)

        let recTitle = pixelLabel(loc.bestLabel, size: 11, color: Px.survivalGold)
        recTitle.position  = CGPoint(x: 0, y: 16)
        recordBox.addChild(recTitle)

        recordLabel           = pixelLabel(bestText, size: 15, color: Px.white)
        recordLabel.position   = CGPoint(x: 0, y: -4)
        recordLabel.zPosition  = 20
        recordBox.addChild(recordLabel)

        // ── Pause indicator drawn on the lobster body (small ‖ bars) ──
        // Visible at all times; tapping the lobster toggles pause.
        buildPauseIndicator()
    }

    /// Draws the pause "‖" icon as two small pixel bars centred on the lobster body.
    /// These are children of lobsterContainer so they move/scale with it.
    private func buildPauseIndicator() {
        pauseIndicator           = SKNode()
        pauseIndicator.position   = CGPoint(x: 0, y: bodyH/2 - 10)
        pauseIndicator.zPosition  = 20
        lobsterContainer.addChild(pauseIndicator)

        for xOff: CGFloat in [-5, 5] {
            let bar = px(4, 10, fill: Px.white.withAlphaComponent(0.55))
            bar.position = CGPoint(x: xOff, y: 0)
            pauseIndicator.addChild(bar)
        }
    }

    /// Live score text shown in the LEFT seaweed box.
    private var currentScoreText: String {
        switch gameMode {
        case .chain:    return String(format: "%.1fs", elapsedTime)
        case .survival: return "\(foodEaten)"
        }
    }

    /// Current best to display in the RIGHT record box (mode-sensitive).
    private var bestText: String {
        switch gameMode {
        case .chain:
            if let t = bestChainTime { return String(format: "%.1fs", t) }
            return loc.noBest
        case .survival:
            if let f = bestSurvivalFood { return "\(f)" }
            return loc.noBest
        }
    }

    // MARK: - Pause indicator (drawn on the lobster; tap lobster to toggle)

    // MARK: - Pause / Resume

    private func pauseElapsedTime() {
        // Record when pause started so we can exclude that time
        pauseStartTime = Date()
    }

    private func resumeElapsedTime() {
        if let ps = pauseStartTime {
            totalPausedSeconds += Date().timeIntervalSince(ps)
            pauseStartTime = nil
        }
    }

    private func currentElapsed() -> TimeInterval {
        let rawElapsed = Date().timeIntervalSince(gameStartTime)
        return rawElapsed - totalPausedSeconds
    }

    private func togglePause() {
        isPaused_game.toggle()
        if isPaused_game {
            pauseElapsedTime()
            bgMusicPlayer?.pause()
            playSFX("sfx_pause.m4a")
            removeAction(forKey: "spawnTimer")   // stop spawning while paused
            showPauseOverlay()
        } else {
            resumeElapsedTime()
            bgMusicPlayer?.play()
            hidePauseOverlay()
            restartSpawnTimer()                  // resume spawning
        }
        self.speed = isPaused_game ? 0 : 1
    }

    private func showPauseOverlay() {
        let overlay = SKNode()
        overlay.zPosition = 50
        overlay.name      = "pauseOverlay"

        let dim = SKSpriteNode(color: SKColor(red: 0, green: 0, blue: 0, alpha: 0.70),
                               size: CGSize(width: W, height: H))
        dim.position  = .zero
        dim.zPosition = 0
        overlay.addChild(dim)

        let panel = px(260, 210, fill: Px.navy, stroke: Px.steel, sw: 3)
        panel.position  = .zero
        panel.zPosition = 1
        overlay.addChild(panel)

        let title = pixelLabel(loc.pausedTitle, size: 28, color: Px.white)
        title.position  = CGPoint(x: 0, y: 66)
        title.zPosition = 2
        overlay.addChild(title)

        let resumeBtn = makePixelButton(text: loc.resumeLabel, width: 180, height: 46, y: 12,
                                        fill: SKColor(red: 0.12, green: 0.38, blue: 0.68, alpha: 1))
        resumeBtn.name = "resumeBtn"
        overlay.addChild(resumeBtn)

        let quitBtn = makePixelButton(text: loc.quitLabel, width: 180, height: 46, y: -46,
                                       fill: SKColor(red: 0.52, green: 0.10, blue: 0.08, alpha: 1))
        quitBtn.name = "quitBtn"
        overlay.addChild(quitBtn)

        addChild(overlay)
        pauseOverlay = overlay

        // On the lobster: swap ‖ bars → ▶ play-triangle indicator
        pauseIndicator?.children.filter { $0.name == "pauseBar2" }.forEach { $0.isHidden = true }
        pauseIndicator?.children.forEach { $0.isHidden = true }
        for (j, w): (Int, CGFloat) in [(0, 12), (1, 8), (2, 4), (3, 2)] {
            let tri = px(w, 4, fill: Px.white.withAlphaComponent(0.75))
            tri.position = CGPoint(x: CGFloat(j) * 2 - 4, y: -CGFloat(j) * 3 + 4)
            tri.name     = "playTriangle"
            pauseIndicator?.addChild(tri)
        }
    }

    private func hidePauseOverlay() {
        pauseOverlay?.removeFromParent()
        pauseOverlay = nil
        // Restore ‖ bars on the lobster
        pauseIndicator?.children.filter { $0.name == "playTriangle" }.forEach { $0.removeFromParent() }
        pauseIndicator?.children.forEach { $0.isHidden = false }
    }

    private func makePixelButton(text: String, width: CGFloat, height: CGFloat, y: CGFloat,
                                  fill: SKColor) -> SKNode {
        let btn = SKNode()
        btn.position  = CGPoint(x: 0, y: y)
        btn.zPosition = 2

        let bg = px(width, height, fill: fill, stroke: Px.white.withAlphaComponent(0.35), sw: 2)
        btn.addChild(bg)

        let lbl = pixelLabel(text, size: 18, color: Px.white)
        lbl.position = CGPoint(x: 0, y: -6)
        btn.addChild(lbl)
        return btn
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let pos = t.location(in: self)

        // Tap the lobster body to toggle pause (use a generous hit area around lobsterContainer)
        let lobsterPos  = lobsterContainer.position
        let hitRadius: CGFloat = bodyW * 0.9
        let dx = pos.x - lobsterPos.x
        let dy = pos.y - lobsterPos.y
        let tappedLobster = abs(dx) <= hitRadius && abs(dy) <= hitRadius

        // ── Tutorial: tapToPause step — waiting for lobster tap ─────────────────
        if tutStep == .tapToPause && !isPaused_game {
            if tappedLobster {
                // Correct! Pause the game and show the "now tap to resume" message
                isPaused_game = true
                self.speed    = 0
                pauseElapsedTime()
                bgMusicPlayer?.pause()
                playSFX("sfx_pause.m4a")   // play pause sound just like normal pause
                handleTutorialPauseDone()   // shows dim + resume prompt (no regular overlay)
            }
            // Any tap that isn't the lobster is ignored in this step
            return
        }

        // ── Tutorial: paused step — tap ANYWHERE to resume and finish tutorial ──
        if tutStep == .tapToPause && isPaused_game {
            isPaused_game = false
            self.speed    = 1
            resumeElapsedTime()
            bgMusicPlayer?.play()
            completeTutorial()
            return
        }

        // ── Normal gameplay lobster tap (pause toggle) ───────────────────────────
        if tappedLobster && tutStep == .done && !isGameOver {
            togglePause()
            return
        }

        if isPaused_game {
            if let overlay = pauseOverlay {
                let lp = t.location(in: overlay)
                if let resume = overlay.childNode(withName: "resumeBtn"),
                   resume.contains(lp) {
                    togglePause()
                } else if let quit = overlay.childNode(withName: "quitBtn"),
                          quit.contains(lp) {
                    // Notify caller of current score BEFORE quitting (best-score update)
                    gameDelegate?.gameWillQuit(foodEaten: foodEaten, mode: gameMode)
                    resumeElapsedTime()
                    isPaused_game = false
                    self.speed    = 1
                    hidePauseOverlay()
                    removeAction(forKey: "timer")
                    removeAction(forKey: "spawnTimer")
                    stopBackgroundMusic()
                    after(0.05) { [weak self] in
                        self?.gameDelegate?.gameDidQuitToTitle()
                    }
                }
            }
            return
        }

        guard !isControlLocked, !isGameOver else { return }
        // Don't start swipe tracking during tapToPause step
        guard tutStep != .tapToPause else { return }
        swipeStart  = pos
        swipeTime   = Date()
        swipeActive = true
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first, swipeActive, !isPaused_game else { return }
        swipeActive = false
        // Block swipe during the tapToPause tutorial step (no object on screen)
        guard tutStep != .tapToPause else { return }
        guard Date().timeIntervalSince(swipeTime) <= GameConstants.maxSwipeRecognitionTime else { return }

        let end = t.location(in: self)
        let dx  = end.x - swipeStart.x
        let dy  = end.y - swipeStart.y
        guard sqrt(dx*dx + dy*dy) >= GameConstants.swipeThreshold else { return }

        let mag = sqrt(dx*dx + dy*dy)
        lastSwipeDelta = CGPoint(x: dx / mag, y: dy / mag)

        let dir: Dir
        if abs(dy) > abs(dx) { dir = dy > 0 ? .up : .down }
        else                  { dir = dx > 0 ? .right : .left }
        handleSwipe(dir)
    }

    private enum Dir { case up, down, left, right }

    // MARK: - Swipe Rules
    //   FOOD:    ↓ = eat.         ↑←→ = miss (fly away).
    //   GARBAGE: → = net catches. ↑←↓ = vomit penalty.
    //   BOMB:    ← = hand takes.  ↑→↓ = EXPLODE.

    private func handleSwipe(_ dir: Dir) {
        guard !isGameOver else { return }
        // During tutorial use the single tutorial object; in normal play target the
        // lowest unresolved object (closest to lobster = most urgent to handle).
        let obj: FallingObjectNode
        if tutStep != .done {
            guard let tut = currentObject, !tut.isResolved else { return }
            obj = tut
        } else {
            guard let closest = activeObjects
                .filter({ !$0.isResolved })
                .min(by: { $0.position.y < $1.position.y }) else { return }
            obj = closest
        }
        guard !isControlLocked else { return }
        let swipeVec = lastSwipeDelta

        // ── Tutorial mode: only the CORRECT swipe is accepted; wrong swipes are ignored ──
        if isTutorialFrozen {
            let isCorrect: Bool
            switch tutStep {
            case .food:    isCorrect = (dir == .down)
            case .garbage: isCorrect = (dir == .right)
            case .bomb:    isCorrect = (dir == .left)
            default:       isCorrect = false
            }
            guard isCorrect else { return }   // silently reject wrong-direction swipes

            // Correct swipe — handle the object normally, then advance tutorial
            obj.isResolved = true
            obj.removeAllActions()
            isTutorialFrozen = false

            switch tutStep {
            case .food:
                obj.run(SKAction.sequence([
                    SKAction.moveTo(y: lobsterY, duration: 0.07),
                    SKAction.run { [weak self] in
                        self?.autoEatFood(obj)
                        self?.advanceTutorial()
                    }
                ]))
            case .garbage:
                flashText(loc.caughtText, color: Px.green)
                playSFX("sfx_net.m4a")
                netCatchAnimation(obj)
                advanceTutorial()
            case .bomb:
                flashText(loc.savedText, color: Px.green)
                playSFX("sfx_catch.m4a")
                handCatchAnimation(obj)
                advanceTutorial()
            default:
                break
            }
            return
        }

        // ── Normal gameplay swipe handling ────────────────────────────────────────
        switch (obj.objectType, dir) {

        case (.food, .down):
            obj.isResolved = true
            obj.removeAllActions()
            obj.run(SKAction.sequence([
                SKAction.moveTo(y: lobsterY, duration: 0.07),
                SKAction.run { [weak self] in self?.autoEatFood(obj) }
            ]))

        case (.food, _):
            obj.isResolved = true
            obj.removeAllActions()
            flashText(loc.missText, color: Px.amber)
            playSFX("sfx_whoosh.m4a")
            flyAway(obj, dirVector: swipeVec, spin: true)
            triggerSpawn()

        case (.garbage, .right):
            obj.isResolved = true
            obj.removeAllActions()
            flashText(loc.caughtText, color: Px.green)
            playSFX("sfx_net.m4a")
            netCatchAnimation(obj)
            triggerSpawn()

        case (.garbage, _):
            obj.isResolved = true
            obj.removeAllActions()
            obj.run(SKAction.sequence([
                SKAction.moveTo(y: lobsterY, duration: 0.07),
                SKAction.run { [weak self] in self?.autoEatGarbage(obj) }
            ]))

        case (.bomb, .left):
            obj.isResolved = true
            obj.removeAllActions()
            flashText(loc.savedText, color: Px.green)
            playSFX("sfx_catch.m4a")
            handCatchAnimation(obj)
            triggerSpawn()

        case (.bomb, _):
            obj.isResolved = true
            obj.removeAllActions()
            obj.run(SKAction.sequence([
                SKAction.moveTo(y: lobsterY, duration: 0.07),
                SKAction.run { [weak self] in self?.autoEatBomb(obj) }
            ]))
        }
    }

    // MARK: - Auto-resolve (object fell to lobster level without swipe)

    private func autoResolve(obj: FallingObjectNode) {
        guard !obj.isResolved, !isTutorialFrozen, !isGameOver else {
            // Game already ended — silently discard any objects still in flight
            finishObject(obj)
            return
        }
        obj.isResolved = true
        switch obj.objectType {
        case .food:    autoEatFood(obj)
        case .garbage: autoEatGarbage(obj)
        case .bomb:    autoEatBomb(obj)
        }
    }

    /// Called by animation callbacks once an object's visual effect is complete.
    /// Removes it from the scene and the active list.
    private func finishObject(_ obj: FallingObjectNode) {
        activeObjects.removeAll { $0 === obj }
        obj.removeFromParent()
    }

    // MARK: - Spawn

    /// Spawns one falling object immediately, adds it to `activeObjects`,
    /// and (in normal play) starts/restarts the repeating spawn timer so the
    /// next object drops after a fixed interval that shrinks as food is eaten.
    private func spawnNextObject() {
        guard !isPaused_game else { return }

        // Tutorial steps 0-2 each spawn a fixed object type then freeze.
        // Step 3 (tapToPause) spawns nothing. Normal play spawns random types.
        let type: ObjectType
        switch tutStep {
        case .food:    type = .food
        case .garbage: type = .garbage
        case .bomb:    type = .bomb
        case .tapToPause: return   // no object during the pause tutorial step
        case .done:    type = randomType()
        }

        let obj = FallingObjectNode(type: type)
        // Spread objects across 3 fixed lanes so concurrent objects don't overlap.
        // A dedicated counter (not activeObjects.count) ensures all lanes are visited.
        // Tutorial objects always spawn dead-centre.
        let xOffset: CGFloat
        if tutStep == .done {
            // Lanes: left, centre, right — evenly spaced inside the play area
            let lanes: [CGFloat] = [-W * 0.22, 0, W * 0.22]
            xOffset = lanes[spawnLaneIndex % lanes.count]
            spawnLaneIndex += 1
        } else {
            xOffset = 0
        }
        obj.position  = CGPoint(x: xOffset, y: spawnY)
        obj.zPosition = 15
        addChild(obj)
        activeObjects.append(obj)

        let speed    = GameConstants.fallSpeed(foodEaten: foodEaten, mode: gameMode)
        let distance = spawnY - lobsterY
        let duration = TimeInterval(distance / speed)

        // Tutorial: fall to mid-screen then freeze for gesture prompt.
        if tutStep != .done {
            let tutFallDuration = duration * 0.55
            obj.run(SKAction.sequence([
                SKAction.moveTo(y: lobsterY + (spawnY - lobsterY) * 0.45,
                                duration: tutFallDuration),
                SKAction.run { [weak self] in self?.beginTutorialStep() }
            ]))
            // Don't start the repeating timer during tutorial
            return
        }

        // Normal play: fall all the way to the lobster, then auto-resolve.
        obj.run(SKAction.sequence([
            SKAction.moveTo(y: lobsterY, duration: duration),
            SKAction.run { [weak self] in self?.autoResolve(obj: obj) }
        ]))

        // Start (or restart) the repeating background timer.
        restartSpawnTimer()
    }

    /// Restarts the repeating spawn timer using the current food-tier interval.
    /// Call this after the first spawn and whenever the food tier changes.
    private func restartSpawnTimer() {
        removeAction(forKey: "spawnTimer")
        guard tutStep == .done, !isPaused_game, !isGameOver else { return }

        let interval = GameConstants.spawnInterval(foodEaten: foodEaten)
        let action = SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: interval),
            SKAction.run { [weak self] in
                guard let self, !self.isPaused_game,
                      self.tutStep == .done, !self.isGameOver else { return }
                self.spawnNextObject()
            }
        ]))
        run(action, withKey: "spawnTimer")
    }

    /// Called after an object is handled. Spawns a replacement immediately
    /// only if the screen is now empty (no other object still falling).
    /// If something is already on screen the background timer covers the next one.
    private func triggerSpawn() {
        guard tutStep == .done, !isGameOver, !isPaused_game else { return }
        let unresolved = activeObjects.filter { !$0.isResolved }
        if unresolved.isEmpty { spawnNextObject() }
    }

    /// Removes a resolved/finished object from the active list.
    private func removeActiveObject(_ obj: FallingObjectNode) {
        activeObjects.removeAll { $0 === obj }
        obj.removeFromParent()
    }

    private func randomType() -> ObjectType {
        let w = GameConstants.spawnWeights(foodEaten: foodEaten, mode: gameMode)
        let r = Double.random(in: 0..<1)
        if r < w.food             { return .food }
        if r < w.food + w.garbage { return .garbage }
        return .bomb
    }

    // MARK: - Outcomes

    private func autoEatFood(_ obj: FallingObjectNode) {
        foodEaten += 1
        flashText(loc.nomText, color: Px.green)
        playSFX("sfx_chomp.m4a")
        chompAnimation(obj)     // animation calls finishObject(obj) at end
        foodGlowPop()

        if gameMode == .chain {
            strainChain()
            refreshBar()
            restartSpawnTimer()   // re-arm timer at new (possibly faster) tier
            let inTutorialSwipeStep = (tutStep == .food || tutStep == .garbage || tutStep == .bomb)
            if !inTutorialSwipeStep { checkChainBreak() }
        } else {
            currentScoreLabel?.text = currentScoreText
            restartSpawnTimer()   // re-arm timer at new tier for survival too
        }
        triggerSpawn()
    }

    private func autoEatGarbage(_ obj: FallingObjectNode) {
        garbageMistakes += 1
        if foodEaten > 0 {
            foodEaten -= 1
            if gameMode == .chain {
                refreshBar()
                strainChain()
            } else {
                currentScoreLabel?.text = currentScoreText
            }
        }
        isControlLocked = true
        flashText(loc.bletchText, color: Px.orange)
        playSFX("sfx_bletch.m4a")
        garbageDisgustAnimation(obj)   // animation calls finishObject(obj) at end
        after(GameConstants.vomitDuration) { [weak self] in
            self?.isControlLocked = false
            self?.triggerSpawn()   // replace after disgust animation clears
        }
    }

    private func autoEatBomb(_ obj: FallingObjectNode) {
        isGameOver      = true
        isControlLocked = true
        removeAction(forKey: "timer")
        removeAction(forKey: "spawnTimer")
        // Immediately stop and remove all other in-flight objects
        activeObjects.filter { $0 !== obj }.forEach { $0.removeAllActions(); $0.removeFromParent() }
        activeObjects = activeObjects.filter { $0 === obj }
        elapsedTime = currentElapsed()
        playSFX("sfx_boom.m4a")
        stopBackgroundMusic()
        bombExplosionAnimation(obj)
        after(1.2) { [weak self] in
            guard let s = self else { return }
            s.gameDelegate?.gameDidEnd(result: GameResult(
                won: false, completionTime: s.elapsedTime,
                foodEaten: s.foodEaten, garbageMistakes: s.garbageMistakes,
                mode: s.gameMode))
        }
    }

    // MARK: - Win (chain mode only)

    private func checkChainBreak() {
        guard gameMode == .chain,
              foodEaten >= GameConstants.chainBreakTarget else { return }
        isGameOver      = true
        isControlLocked = true
        removeAction(forKey: "timer")
        removeAction(forKey: "spawnTimer")
        // Clear all remaining in-flight objects
        activeObjects.forEach { $0.removeAllActions(); $0.removeFromParent() }
        activeObjects.removeAll()
        elapsedTime = currentElapsed()
        currentObject?.removeFromParent()

        for (i, link) in chainLinks.enumerated() {
            link.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(i) * 0.032),
                SKAction.group([
                    SKAction.rotate(byAngle: CGFloat.random(in: -.pi ... .pi), duration: 0.16),
                    SKAction.scale(to: 2.0, duration: 0.12),
                    SKAction.fadeOut(withDuration: 0.12)
                ]),
                SKAction.removeFromParent()
            ]))
        }

        spawnPixelSparks(at: CGPoint(x: 0, y: chainFloorY), color: Px.amber,  count: 20)
        spawnPixelSparks(at: CGPoint(x: 0, y: chainFloorY), color: Px.orange, count: 14)

        playSFX("sfx_win.m4a")
        stopBackgroundMusic()
        flashText(loc.freeText, color: Px.amber)
        after(0.5) { [weak self] in self?.showGoodbyeLabel() }

        let wait   = SKAction.wait(forDuration: 0.60)
        let scurry = SKAction.moveBy(x: W * 1.2, y: 8, duration: 1.0)
        scurry.timingMode = .linear
        let done = SKAction.run { [weak self] in
            guard let s = self else { return }
            s.gameDelegate?.gameDidEnd(result: GameResult(
                won: true, completionTime: s.elapsedTime,
                foodEaten: s.foodEaten, garbageMistakes: s.garbageMistakes,
                mode: s.gameMode))
        }
        lobsterContainer.run(SKAction.sequence([wait, scurry, SKAction.fadeOut(withDuration: 0.15), done]))
    }

    private func showGoodbyeLabel() {
        let lbl = pixelLabel(loc.goodbyeText, size: 16, color: Px.white)
        lbl.position  = CGPoint(x: 0, y: lobsterY + bodyH + 44)
        lbl.zPosition = 25
        lbl.alpha     = 0
        addChild(lbl)
        lbl.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.wait(forDuration: 0.9),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Animation Library

    private func chompAnimation(_ obj: FallingObjectNode) {
        obj.run(SKAction.group([
            SKAction.scale(to: 0.05, duration: 0.10),
            SKAction.fadeOut(withDuration: 0.10)
        ])) { [weak self] in self?.finishObject(obj) }

        setMouthOpen(true)
        after(0.16) { [weak self] in self?.setMouthOpen(false) }

        let newScale = 1.0 + CGFloat(foodEaten) * GameConstants.visualGrowthPerFood
        let punch    = SKAction.scale(to: newScale * 1.20, duration: 0.06)
        punch.timingMode = .linear
        let settle   = SKAction.scale(to: newScale, duration: 0.10)
        settle.timingMode = .linear
        lobsterContainer.run(SKAction.sequence([punch, settle]))
    }

    private func foodGlowPop() {
        let ringSize: CGFloat = bodyW * 0.9
        let ring = px(ringSize, ringSize, fill: .clear, stroke: Px.green, sw: 3)
        ring.position  = lobsterContainer.position
        ring.zPosition = 9
        addChild(ring)
        let expand = SKAction.scale(to: 2.2, duration: 0.30)
        expand.timingMode = .linear
        ring.run(SKAction.group([expand, SKAction.fadeOut(withDuration: 0.28)])) {
            ring.removeFromParent()
        }
    }

    private func garbageDisgustAnimation(_ obj: FallingObjectNode) {
        obj.run(SKAction.group([
            SKAction.scale(to: 0.05, duration: 0.10),
            SKAction.fadeOut(withDuration: 0.10)
        ])) { [weak self] in self?.finishObject(obj) }

        setMouthOpen(true)
        after(0.10) { [weak self] in
            guard let s = self else { return }
            s.setMouthOpen(false)
            s.showXEyes(true)
            s.lobsterBody.fillColor = SKColor(red: 0.32, green: 0.65, blue: 0.14, alpha: 1)

            let recoil  = SKAction.moveBy(x: 0, y: -16, duration: 0.08)
            let restore = SKAction.moveBy(x: 0, y:  16, duration: 0.14)
            recoil.timingMode  = .linear
            restore.timingMode = .linear
            s.lobsterContainer.run(SKAction.sequence([recoil, restore]))

            s.spawnPixelVomit()

            let wobble = SKAction.repeat(SKAction.sequence([
                SKAction.rotate(byAngle:  0.18, duration: 0.05),
                SKAction.rotate(byAngle: -0.36, duration: 0.05),
                SKAction.rotate(byAngle:  0.18, duration: 0.05),
            ]), count: 3)
            s.lobsterContainer.run(wobble)

            s.after(GameConstants.vomitDuration - 0.05) { [weak s] in
                s?.showXEyes(false)
                s?.lobsterBody.fillColor = Px.lobRed
            }
        }
    }

    private func spawnPixelVomit() {
        for i in 0..<10 {
            let sz    = CGFloat(Int.random(in: 3...7)) * 2
            let blob  = px(sz, sz, fill: Px.green)
            let startY = lobsterY + bodyH/2 + 8
            blob.position  = CGPoint(x: CGFloat.random(in: -6...6), y: startY)
            blob.zPosition = 22
            addChild(blob)

            let angle = CGFloat.random(in: .pi * 0.50 ... .pi * 0.98)
            let spd   = CGFloat.random(in: 55...150)
            let dx    = cos(angle) * spd * (i % 2 == 0 ? 1 : -1)
            let dy    = sin(angle) * spd
            let move  = SKAction.moveBy(x: dx, y: dy, duration: 0.45)
            move.timingMode = .linear
            let fade  = SKAction.sequence([
                SKAction.wait(forDuration: 0.18),
                SKAction.fadeOut(withDuration: 0.28)
            ])
            blob.run(SKAction.group([move, fade])) { blob.removeFromParent() }
        }
    }

    private func bombExplosionAnimation(_ obj: FallingObjectNode) {
        flashText(loc.boomText, color: Px.red)

        obj.run(SKAction.sequence([
            SKAction.scale(to: 3.0, duration: 0.10),
            SKAction.fadeOut(withDuration: 0.16)
        ])) { [weak self] in self?.finishObject(obj) }

        let flash = SKSpriteNode(color: .white, size: CGSize(width: W, height: H))
        flash.position  = .zero
        flash.zPosition = 40
        addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.04),
            SKAction.fadeOut(withDuration: 0.20),
            SKAction.removeFromParent()
        ]))

        let shake = SKAction.sequence([
            SKAction.moveBy(x: -16, y:  6, duration: 0.04),
            SKAction.moveBy(x:  20, y: -10, duration: 0.04),
            SKAction.moveBy(x: -14, y:  8, duration: 0.04),
            SKAction.moveBy(x:  10, y: -4, duration: 0.04),
        ])
        run(SKAction.repeat(shake, count: 2))

        let squish = SKAction.scaleX(to: 2.0, y: 0.12, duration: 0.12)
        squish.timingMode = .linear
        lobsterContainer.run(SKAction.sequence([
            squish, SKAction.fadeOut(withDuration: 0.20)
        ]))

        spawnPixelSparks(at: lobsterContainer.position, color: Px.red,    count: 16)
        spawnPixelSparks(at: lobsterContainer.position, color: Px.orange,  count: 12)
        spawnPixelSparks(at: lobsterContainer.position, color: Px.amber,   count: 10)
    }

    // ── HAND CATCH ──────────────────────────────────────────────────────────
    private func handCatchAnimation(_ obj: FallingObjectNode) {
        let objPos  = obj.position
        let enterX: CGFloat = -W * 0.56

        let hand = SKNode()
        hand.position  = CGPoint(x: enterX, y: objPos.y)
        hand.zPosition = 20
        addChild(hand)

        let skinColor   = SKColor(red: 0.94, green: 0.76, blue: 0.58, alpha: 1)
        let skinStroke  = SKColor(red: 0.70, green: 0.50, blue: 0.35, alpha: 1)
        let palm = px(28, 30, fill: skinColor, stroke: skinStroke, sw: 2)
        hand.addChild(palm)

        let fingerConfigs: [(CGFloat, CGFloat, CGFloat)] = [
            (-10, 18, 16), (-3, 20, 20), (4, 20, 20), (11, 18, 16),
        ]
        for (xo, yo, fh) in fingerConfigs {
            let f = px(8, fh, fill: skinColor, stroke: skinStroke, sw: 1.5)
            f.position = CGPoint(x: xo, y: yo + fh/2)
            hand.addChild(f)
        }

        let thumb = px(16, 8, fill: skinColor, stroke: skinStroke, sw: 1.5)
        thumb.position = CGPoint(x: 20, y: 10)
        hand.addChild(thumb)

        for xk: CGFloat in [-10, -3, 4, 11] {
            let kn = px(4, 2, fill: SKColor(red: 1.0, green: 0.88, blue: 0.72, alpha: 0.60))
            kn.position = CGPoint(x: xk, y: 15)
            hand.addChild(kn)
        }

        let cuff = px(32, 12,
                      fill:   SKColor(red: 0.20, green: 0.30, blue: 0.70, alpha: 1),
                      stroke: SKColor(red: 0.12, green: 0.18, blue: 0.50, alpha: 1), sw: 2)
        cuff.position = CGPoint(x: 0, y: -20)
        hand.addChild(cuff)

        let slideIn  = SKAction.moveTo(x: objPos.x - 10, duration: 0.16)
        slideIn.timingMode = .linear

        obj.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.13),
            SKAction.group([
                SKAction.scale(to: 0.1, duration: 0.06),
                SKAction.fadeOut(withDuration: 0.06)
            ]),
            SKAction.run { [weak self] in self?.finishObject(obj) }
        ]))

        let exitX    = -W * 0.75
        let slideOut = SKAction.moveTo(x: exitX, duration: 0.18)
        slideOut.timingMode = .linear
        let fadeOut  = SKAction.fadeOut(withDuration: 0.14)

        hand.run(SKAction.sequence([
            slideIn,
            SKAction.wait(forDuration: 0.05),
            SKAction.group([slideOut, fadeOut]),
            SKAction.removeFromParent()
        ]))
    }

    // ── NET CATCH ───────────────────────────────────────────────────────────
    private func netCatchAnimation(_ obj: FallingObjectNode) {
        let objPos  = obj.position
        let enterX: CGFloat = W * 0.56

        let net = SKNode()
        net.position  = CGPoint(x: enterX, y: objPos.y)
        net.zPosition = 20
        addChild(net)

        let bagColor  = SKColor(red: 0.88, green: 0.76, blue: 0.30, alpha: 0.85)
        let ropeColor = SKColor(red: 0.72, green: 0.58, blue: 0.16, alpha: 1)

        let topBar = px(50, 4, fill: ropeColor)
        topBar.position = CGPoint(x: 0, y: 28)
        net.addChild(topBar)

        let botBar = px(50, 4, fill: ropeColor)
        botBar.position = CGPoint(x: 0, y: -28)
        net.addChild(botBar)

        let rightBar = px(4, 60, fill: ropeColor)
        rightBar.position = CGPoint(x: 24, y: 0)
        net.addChild(rightBar)

        let fill = px(48, 56, fill: bagColor)
        fill.position  = CGPoint(x: 1, y: 0)
        fill.zPosition = -1
        net.addChild(fill)

        for xi: CGFloat in [-8, 4, 16] {
            let cord = px(3, 56, fill: ropeColor.withAlphaComponent(0.55))
            cord.position = CGPoint(x: xi, y: 0)
            net.addChild(cord)
        }

        for yi: CGFloat in [-14, 0, 14] {
            let hcord = px(48, 2, fill: ropeColor.withAlphaComponent(0.45))
            hcord.position = CGPoint(x: 1, y: yi)
            net.addChild(hcord)
        }

        let pole = px(40, 6,
                      fill:   SKColor(red: 0.55, green: 0.35, blue: 0.14, alpha: 1),
                      stroke: SKColor(red: 0.36, green: 0.22, blue: 0.08, alpha: 1), sw: 1.5)
        pole.position = CGPoint(x: 44, y: 0)
        net.addChild(pole)

        let slideIn  = SKAction.moveTo(x: objPos.x + 12, duration: 0.16)
        slideIn.timingMode = .linear

        obj.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.13),
            SKAction.group([
                SKAction.scale(to: 0.1, duration: 0.06),
                SKAction.fadeOut(withDuration: 0.06)
            ]),
            SKAction.run { [weak self] in self?.finishObject(obj) }
        ]))

        let exitX    = W * 0.75
        let slideOut = SKAction.moveTo(x: exitX, duration: 0.18)
        slideOut.timingMode = .linear
        let fadeOut  = SKAction.fadeOut(withDuration: 0.14)

        net.run(SKAction.sequence([
            slideIn,
            SKAction.wait(forDuration: 0.05),
            SKAction.group([slideOut, fadeOut]),
            SKAction.removeFromParent()
        ]))
    }

    private func flyAway(_ obj: FallingObjectNode, dirVector: CGPoint, spin: Bool) {
        let dist: CGFloat = CGFloat.random(in: 200...300)
        let move = SKAction.moveBy(x: dirVector.x * dist, y: dirVector.y * dist,
                                   duration: 0.24)
        move.timingMode = .linear
        let fade = SKAction.fadeOut(withDuration: 0.20)
        var acts: [SKAction] = [move, fade]
        if spin { acts.append(SKAction.rotate(byAngle: .pi * 2, duration: 0.24)) }
        obj.run(SKAction.group(acts)) { [weak self] in self?.finishObject(obj) }
    }

    private func spawnPixelSparks(at pos: CGPoint, color: SKColor, count: Int = 12) {
        for _ in 0..<count {
            let sz    = CGFloat(Int.random(in: 1...3)) * 4
            let spark = px(sz, sz, fill: color)
            spark.position  = pos
            spark.zPosition = 30
            addChild(spark)
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist  = CGFloat.random(in: 40...200)
            let move  = SKAction.moveBy(x: cos(angle) * dist, y: sin(angle) * dist,
                                        duration: 0.44)
            move.timingMode = .linear
            spark.run(SKAction.sequence([
                SKAction.group([move, SKAction.fadeOut(withDuration: 0.44)]),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - HUD Updates

    private func flashText(_ text: String, color: SKColor) {
        feedbackLabel.text      = text
        feedbackLabel.fontColor = color
        feedbackLabel.alpha     = 1
        feedbackLabel.setScale(1.3)
        feedbackLabel.removeAllActions()
        feedbackLabel.run(SKAction.sequence([
            SKAction.scale(to: 1.0, duration: 0.06),
            SKAction.wait(forDuration: 0.44),
            SKAction.fadeOut(withDuration: 0.22)
        ]))
    }

    private func refreshBar() {
        guard gameMode == .chain, let fill = progressBarFill else { return }
        fill.removeFromParent()
        let bw    = W * 0.68, bh: CGFloat = 14
        let ratio = CGFloat(max(foodEaten, 0)) / CGFloat(GameConstants.chainBreakTarget)
        progressBarFill = makeFill(bw: bw, bh: bh, ratio: ratio)
        addChild(progressBarFill!)
        if let cap = childNode(withName: "barCaption") as? SKLabelNode {
            cap.text = "\(loc.chainLabel): \(max(foodEaten, 0))/\(GameConstants.chainBreakTarget)"
        }
    }

    private func tickTimer() {
        guard !isPaused_game else { return }
        elapsedTime = currentElapsed()
        // Keep left seaweed box in sync (chain = time, survival = food count)
        currentScoreLabel?.text = currentScoreText
    }

    // MARK: - Tutorial

    /// Called once the spawned tutorial object has drifted to mid-screen.
    /// Freezes the object in place, dims the scene, and shows the animated finger prompt.
    private func beginTutorialStep() {
        guard tutStep != .done else { return }
        isTutorialFrozen = true

        // Freeze the falling object in place
        currentObject?.removeAllActions()

        // Dim overlay
        let overlay = SKNode()
        overlay.zPosition = 60
        overlay.name      = "tutOverlay"

        let dim = SKSpriteNode(color: SKColor(red: 0, green: 0, blue: 0, alpha: 0.52),
                               size: CGSize(width: W, height: H))
        dim.position  = .zero
        dim.zPosition = 0
        overlay.addChild(dim)

        // Prompt text (two lines: action + "try it")
        let prompt = tutPromptText
        let lbl = pixelLabelTut(prompt, size: 22)
        lbl.position  = CGPoint(x: 0, y: H * 0.28)
        lbl.zPosition = 2
        lbl.numberOfLines = 0
        overlay.addChild(lbl)

        let tryLbl = pixelLabelTut(loc.tutTryIt, size: 16)
        tryLbl.fontColor = Px.amber
        tryLbl.position  = CGPoint(x: 0, y: H * 0.28 - 34)
        tryLbl.zPosition = 2
        overlay.addChild(tryLbl)

        // Animated SF Symbol finger — starts on the object, swipes in the correct direction
        let finger = buildFingerSprite(pointingAngle: fingerAngleForStep)
        finger.position  = tutFingerStartPos
        finger.zPosition = 3
        overlay.addChild(finger)
        animateSwipeFinger(finger)

        addChild(overlay)
        tutOverlay = overlay
    }

    /// Called after step 3 (swipe items done). Shows the tap-lobster prompt with no object.
    private func beginTapToPauseStep() {
        tutStep          = .tapToPause
        isTutorialFrozen = true

        let overlay = SKNode()
        overlay.zPosition = 60
        overlay.name      = "tutOverlay"

        let dim = SKSpriteNode(color: SKColor(red: 0, green: 0, blue: 0, alpha: 0.52),
                               size: CGSize(width: W, height: H))
        dim.position  = .zero
        dim.zPosition = 0
        overlay.addChild(dim)

        let lbl = pixelLabelTut(loc.tutPausePrompt, size: 22)
        lbl.position  = CGPoint(x: 0, y: H * 0.28)
        lbl.zPosition = 2
        lbl.numberOfLines = 0
        overlay.addChild(lbl)

        // SF Symbol finger pointing down toward the lobster, bobbing
        // Rotate so fingertip points downward (+π * 0.75, same as food swipe step)
        let finger = buildFingerSprite(pointingAngle: .pi * 0.75)
        finger.position  = CGPoint(x: 0, y: lobsterY + bodyH + 56)
        finger.zPosition = 3
        overlay.addChild(finger)

        // Bob down toward lobster then back up, repeat
        let down = SKAction.moveBy(x: 0, y: -24, duration: 0.42)
        let up   = SKAction.moveBy(x: 0, y: +24, duration: 0.42)
        down.timingMode = .easeInEaseOut
        up.timingMode   = .easeInEaseOut
        finger.run(SKAction.repeatForever(SKAction.sequence([
            down, SKAction.wait(forDuration: 0.08), up, SKAction.wait(forDuration: 0.12)
        ])), withKey: "fingerBob")

        addChild(overlay)
        tutOverlay = overlay
    }

    /// Removes the tutorial overlay and resumes / proceeds to next step.
    private func dismissTutorialOverlay(completion: @escaping () -> Void) {
        guard let ov = tutOverlay else { completion(); return }
        tutOverlay = nil
        isTutorialFrozen = false
        ov.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.18),
            SKAction.removeFromParent(),
            SKAction.run { completion() }
        ]))
    }

    /// Advance to the next tutorial step after a correct swipe action was performed.
    private func advanceTutorial() {
        dismissTutorialOverlay { [weak self] in
            guard let self else { return }
            switch self.tutStep {
            case .food:
                self.tutStep = .garbage
                self.spawnNextObject()
            case .garbage:
                self.tutStep = .bomb
                self.spawnNextObject()
            case .bomb:
                // Mark tutorial as done now — the swipe controls are learned.
                // Even if user quits during the pause step, it won't repeat.
                self.gameDelegate?.tutorialDidComplete()
                self.beginTapToPauseStep()
            case .tapToPause, .done:
                break
            }
        }
    }

    /// Called when the user taps the lobster during the tapToPause step.
    /// Shows a simple dim + "tap anywhere to resume" message. No regular pause overlay.
    private func handleTutorialPauseDone() {
        // Remove the finger prompt overlay that was showing the lobster-tap instruction
        tutOverlay?.removeFromParent()
        tutOverlay = nil

        let overlay = SKNode()
        overlay.zPosition = 60
        overlay.name      = "tutResumeOverlay"

        let dim = SKSpriteNode(color: SKColor(red: 0, green: 0, blue: 0, alpha: 0.60),
                               size: CGSize(width: W, height: H))
        dim.position  = .zero
        dim.zPosition = 0
        overlay.addChild(dim)

        let lbl = pixelLabelTut(loc.tutResumePrompt, size: 22)
        lbl.position  = CGPoint(x: 0, y: 0)
        lbl.zPosition = 2
        lbl.numberOfLines = 0
        overlay.addChild(lbl)

        addChild(overlay)
        tutOverlay = overlay
    }

    /// Called when the user taps anywhere during the tutorial paused step.
    private func completeTutorial() {
        // Fade out the tutorial resume overlay
        tutOverlay?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.18),
            SKAction.removeFromParent()
        ]))
        tutOverlay = nil
        isTutorialFrozen = false
        tutStep = .done
        // Clear any leftover tutorial objects
        activeObjects.forEach { $0.removeFromParent() }
        activeObjects.removeAll()
        // Reset game state so tutorial food/time doesn't pollute real game
        foodEaten          = 0
        garbageMistakes    = 0
        gameStartTime      = Date()
        totalPausedSeconds = 0
        // Reset visible HUD labels
        currentScoreLabel?.text = currentScoreText
        if gameMode == .chain { refreshBar() }
        // Kick off the first object immediately, timer will schedule subsequent ones
        spawnNextObject()
    }

    // ── Prompt text per step ──────────────────────────────────────────────────

    private var tutPromptText: String {
        switch tutStep {
        case .food:    return loc.tutFoodPrompt
        case .garbage: return loc.tutGarbagePrompt
        case .bomb:    return loc.tutBombPrompt
        default:       return ""
        }
    }

    // ── Finger builder (SF Symbol hand) ──────────────────────────────────────

    /// Builds a smooth pointing-hand sprite using an SF Symbol.
    /// `angle` rotates the base "hand.point.up.left.fill" symbol so it points
    /// in the swipe direction: 0 = up-left (default), rotated as needed.
    private func buildFingerSprite(pointingAngle: CGFloat) -> SKSpriteNode {
        let sprite = symbolSprite(named: "hand.point.up.left.fill",
                                  size: 52,
                                  tint: UIColor.white,
                                  weight: .regular)
        sprite.zRotation = pointingAngle
        sprite.alpha     = 0.92
        // Drop shadow for readability
        sprite.color     = .black
        sprite.colorBlendFactor = 0.0
        return sprite
    }

    /// Rotation angle (zRotation) for the hand symbol so it points in the swipe direction.
    /// "hand.point.up.left.fill" natural orientation: finger points upper-left (~135° from east).
    /// SpriteKit zRotation is counter-clockwise. We rotate so the tip aims in the swipe direction.
    private var fingerAngleForStep: CGFloat {
        // Default symbol points upper-left (135° CCW from east).
        // To aim at direction D: rotate by (D - 135°).
        //   Down  (270° = -90°): -90° - 135° = -225° = +135°  →  +π * 0.75
        //   Right (  0°):         0° - 135°  = -135°           →  -π * 0.75
        //   Left  (180°):        180° - 135° =  +45°           →  +π * 0.25
        switch tutStep {
        case .food:    return  .pi * 0.75   // point downward
        case .garbage: return -.pi * 0.75   // point right
        case .bomb:    return  .pi * 0.25   // point left
        default:       return 0
        }
    }

    /// Start position of the finger: ON the frozen object, offset slightly so the tip points at it.
    private var tutFingerStartPos: CGPoint {
        guard let obj = currentObject else { return .zero }
        let objPos = obj.position
        // Offset the hand so the fingertip starts at/near the object center
        switch tutStep {
        case .food:    return CGPoint(x: objPos.x,        y: objPos.y + 14)  // above, pointing down
        case .garbage: return CGPoint(x: objPos.x - 20,   y: objPos.y)       // left of obj, pointing right
        case .bomb:    return CGPoint(x: objPos.x + 20,   y: objPos.y)       // right of obj, pointing left
        default:       return objPos
        }
    }

    private func animateSwipeFinger(_ finger: SKSpriteNode) {
        let swipeDist: CGFloat       = 80
        let swipeDuration: TimeInterval = 0.38
        let holdPause: TimeInterval  = 0.20

        // Direction to move (away from object, matching the required swipe)
        let delta: CGPoint
        switch tutStep {
        case .food:    delta = CGPoint(x:  0,          y: -swipeDist)
        case .garbage: delta = CGPoint(x: +swipeDist,  y:  0)
        case .bomb:    delta = CGPoint(x: -swipeDist,  y:  0)
        default:       return
        }

        let startPos = finger.position

        let swipe  = SKAction.moveBy(x: delta.x, y: delta.y, duration: swipeDuration)
        swipe.timingMode = .easeIn

        // Trail: finger fades out at end, snaps back to start, fades in
        let fadeOut = SKAction.fadeOut(withDuration: 0.14)
        let snapBack = SKAction.run { finger.position = startPos }
        let fadeIn  = SKAction.sequence([
            SKAction.unhide(),
            SKAction.fadeIn(withDuration: 0.14)
        ])

        finger.run(SKAction.repeatForever(SKAction.sequence([
            swipe,
            fadeOut,
            snapBack,
            SKAction.wait(forDuration: holdPause),
            fadeIn,
            SKAction.wait(forDuration: 0.15)
        ])), withKey: "fingerSwipe")
    }

    // ── Label helper for tutorial (supports multi-line) ───────────────────────

    private func pixelLabelTut(_ text: String, size: CGFloat) -> SKLabelNode {
        let n = SKLabelNode(text: text)
        n.fontName                = "Courier-Bold"
        n.fontSize                = size
        n.fontColor               = Px.white
        n.horizontalAlignmentMode = .center
        n.verticalAlignmentMode   = .center
        n.preferredMaxLayoutWidth = W * 0.78
        return n
    }

    // MARK: - Sound

    /// Plays a looping background music track.
    /// Looks in the "Sounds" subfolder first, then falls back to the bundle root.
    private func startBackgroundMusic() {
        let candidates = ["bg_music.mp3", "bg_music.m4a", "bg_music.caf"]
        for name in candidates {
            let parts = name.components(separatedBy: ".")
            guard parts.count == 2 else { continue }
            let url = Bundle.main.url(forResource: parts[0], withExtension: parts[1],
                                      subdirectory: "Sounds")
                   ?? Bundle.main.url(forResource: parts[0], withExtension: parts[1])
            if let url {
                do {
                    bgMusicPlayer = try AVAudioPlayer(contentsOf: url)
                    bgMusicPlayer?.numberOfLoops = -1
                    bgMusicPlayer?.volume = 0.35
                    bgMusicPlayer?.play()
                } catch { /* file found but unreadable */ }
                break
            }
        }
    }

    private func stopBackgroundMusic() {
        bgMusicPlayer?.stop()
        bgMusicPlayer = nil
    }

    /// Plays a short SFX using the pre-loaded AVAudioPlayer for that file.
    /// If the player was not pre-loaded (file missing), does nothing silently.
    /// Filename must include extension, e.g. "sfx_chomp.m4a".
    private func playSFX(_ filename: String) {
        let base = filename.components(separatedBy: ".").first ?? filename
        guard let player = sfxPlayers[base] else { return }
        // If the previous play hasn't finished, restart from beginning
        if player.isPlaying { player.stop(); player.currentTime = 0 }
        player.play()
    }

    // MARK: - Utilities

    private func pixelLabel(_ text: String, size: CGFloat, color: SKColor) -> SKLabelNode {
        let n = SKLabelNode(text: text)
        n.fontName  = "Courier-Bold"
        n.fontSize  = size
        n.fontColor = color
        n.horizontalAlignmentMode = .center
        return n
    }

    private func after(_ t: TimeInterval, block: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + t, execute: block)
    }
}
