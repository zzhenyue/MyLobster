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

// MARK: - Delegate

protocol GameSceneDelegate: AnyObject {
    func gameDidEnd(result: GameResult)
    func gameDidQuitToTitle()          // ← NEW: quit goes back to title, not result
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
    var gameMode: GameMode = .chain

    // MARK: Delegate
    weak var gameDelegate: GameSceneDelegate?

    // MARK: State
    private var foodEaten       = 0
    private var garbageMistakes = 0
    private var isControlLocked = false
    private var isPaused_game   = false
    private var isTutorial      = true
    private var tutorialIndex   = 0

    // Timer — we track elapsed manually so pause truly freezes it
    private var pauseStartTime: Date?          // set when paused
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
    private var timerLabel:         SKLabelNode!
    private var progressLabel:      SKLabelNode!
    private var feedbackLabel:      SKLabelNode!
    private var hintLabel:          SKLabelNode!
    private var pauseBtn:           SKNode!
    private var currentObject:      FallingObjectNode?

    // MARK: Swipe tracking
    private var swipeStart     = CGPoint.zero
    private var swipeTime      = Date()
    private var swipeActive    = false
    private var lastSwipeDelta = CGPoint.zero

    // MARK: Layout  (anchorPoint 0.5,0.5 → origin at screen centre)
    private var W: CGFloat { size.width  }
    private var H: CGFloat { size.height }

    // In chain mode the lobster sits a bit higher (chain hangs below).
    // In survival mode the lobster sits on the sand floor.
    private var lobsterY: CGFloat {
        gameMode == .survival ? (-H * 0.42 + bodyH / 2) : -H * 0.12
    }
    private var spawnY:       CGFloat { H * 0.48 }
    private var barY:         CGFloat { H * 0.36 }
    private var hintY:        CGFloat { -H * 0.43 }
    private var chainBottomY: CGFloat { -H * 0.47 }

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
        buildHUD()
        buildHintLabel()
        buildPauseButton()
        gameStartTime = Date()
        totalPausedSeconds = 0
        spawnNextObject()
        run(SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: 0.05),
            SKAction.run { [weak self] in self?.tickTimer() }
        ])), withKey: "timer")
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

        // Pixel seaweed
        for xPos: CGFloat in [-W * 0.38, W * 0.38] {
            let col = SKColor(red: 0.10, green: 0.50, blue: 0.18, alpha: 0.85)
            for j in 0..<5 {
                let seg = px(6, 8, fill: col)
                seg.position  = CGPoint(x: xPos + (j % 2 == 0 ? 4 : -4),
                                        y: -H/2 + 28 + CGFloat(j) * 8)
                seg.zPosition = 3
                addChild(seg)
            }
        }
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

        let cap = pixelLabel("CHAIN: 0/\(GameConstants.chainBreakTarget)", size: 10,
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

    private func buildChain() {
        let startY  = lobsterY - bodyH/2 - 12
        let count   = 10
        let spacing = (startY - chainBottomY) / CGFloat(count)

        for i in 0..<count {
            let container = SKNode()
            container.position = CGPoint(x: 0, y: startY - CGFloat(i) * spacing)
            container.zPosition = 8
            addChild(container)
            chainLinks.append(container)

            let isEven = (i % 2 == 0)
            let ow: CGFloat = isEven ? 22 : 14
            let oh: CGFloat = isEven ? 14 : 24

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

        let plate = px(30, 12, fill: Px.darkSteel, stroke: Px.steel, sw: 1.5)
        plate.position  = CGPoint(x: 0, y: chainBottomY)
        plate.zPosition = 8
        addChild(plate)
        for xOff: CGFloat in [-7, 7] {
            let bolt = px(4, 4, fill: Px.steel)
            bolt.position = CGPoint(x: xOff, y: 0)
            plate.addChild(bolt)
        }

        let cap = pixelLabel("CHAINED", size: 9, color: Px.dimWhite)
        cap.position  = CGPoint(x: 0, y: chainBottomY - 16)
        cap.zPosition = 8
        addChild(cap)
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
            let snap = chainLinks[idx]
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

    // MARK: - HUD

    private func buildHUD() {
        // Timer (top right)
        let tBg = px(84, 26, fill: Px.navy, stroke: Px.steel, sw: 2)
        tBg.position  = CGPoint(x: W * 0.34, y: H * 0.44)
        tBg.zPosition = 19
        addChild(tBg)

        timerLabel          = pixelLabel("0.0s", size: 14, color: Px.white)
        timerLabel.position  = CGPoint(x: W * 0.34, y: H * 0.44 - 5)
        timerLabel.zPosition = 20
        addChild(timerLabel)

        // Progress / food count (top left)
        if gameMode == .chain {
            progressLabel = pixelLabel("0/\(GameConstants.chainBreakTarget)",
                                       size: 14, color: Px.white)
        } else {
            progressLabel = pixelLabel("FOOD: 0", size: 14, color: Px.survivalGold)
        }
        progressLabel.horizontalAlignmentMode = .left
        progressLabel.position  = CGPoint(x: -W * 0.44, y: H * 0.44 - 5)
        progressLabel.zPosition = 20
        addChild(progressLabel)

        // Survival mode badge
        if gameMode == .survival {
            let badge = pixelLabel("SURVIVAL", size: 9, color: Px.survivalGold)
            badge.position  = CGPoint(x: -W * 0.44 + 34, y: H * 0.44 + 8)
            badge.zPosition = 20
            addChild(badge)
        }

        feedbackLabel          = pixelLabel("", size: 22, color: Px.white)
        feedbackLabel.position  = CGPoint(x: 0, y: lobsterY + bodyH + 32)
        feedbackLabel.zPosition = 22
        addChild(feedbackLabel)
    }

    private func buildHintLabel() {
        hintLabel          = pixelLabel("", size: 11, color: Px.dimWhite)
        hintLabel.position  = CGPoint(x: 0, y: hintY)
        hintLabel.zPosition = 20
        addChild(hintLabel)
    }

    // MARK: - Pause Button

    private func buildPauseButton() {
        pauseBtn          = SKNode()
        pauseBtn.position  = CGPoint(x: -W * 0.40, y: H * 0.44)
        pauseBtn.zPosition = 25
        addChild(pauseBtn)

        let bg = px(52, 52, fill: Px.navy, stroke: Px.steel, sw: 2)
        bg.name = "pauseBtnBg"
        pauseBtn.addChild(bg)

        for x: CGFloat in [-7, 7] {
            let bar = px(6, 18, fill: Px.white)
            bar.position = CGPoint(x: x, y: 0)
            bar.name     = "pauseBar"
            pauseBtn.addChild(bar)
        }
    }

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
            showPauseOverlay()
        } else {
            resumeElapsedTime()
            hidePauseOverlay()
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

        let panel = px(240, 190, fill: Px.navy, stroke: Px.steel, sw: 3)
        panel.position  = .zero
        panel.zPosition = 1
        overlay.addChild(panel)

        let title = pixelLabel("PAUSED", size: 22, color: Px.white)
        title.position  = CGPoint(x: 0, y: 58)
        title.zPosition = 2
        overlay.addChild(title)

        let resumeBtn = makePixelButton(text: "RESUME", width: 160, height: 38, y: 10,
                                        fill: SKColor(red: 0.12, green: 0.38, blue: 0.68, alpha: 1))
        resumeBtn.name = "resumeBtn"
        overlay.addChild(resumeBtn)

        let quitBtn = makePixelButton(text: "QUIT", width: 160, height: 38, y: -40,
                                       fill: SKColor(red: 0.52, green: 0.10, blue: 0.08, alpha: 1))
        quitBtn.name = "quitBtn"
        overlay.addChild(quitBtn)

        addChild(overlay)
        pauseOverlay = overlay

        pauseBtn.children.filter { $0.name == "pauseBar" }.forEach { $0.isHidden = true }
        for (j, w): (Int, CGFloat) in [(0, 14), (1, 10), (2, 6), (3, 2)] {
            let bar = px(w, 4, fill: Px.white)
            bar.position = CGPoint(x: 2 + CGFloat(j) * 1, y: -CGFloat(j) * 5 + 6)
            bar.name     = "playIcon"
            pauseBtn.addChild(bar)
        }
    }

    private func hidePauseOverlay() {
        pauseOverlay?.removeFromParent()
        pauseOverlay = nil
        pauseBtn.children.filter { $0.name == "playIcon" }.forEach { $0.removeFromParent() }
        pauseBtn.children.filter { $0.name == "pauseBar" }.forEach { $0.isHidden = false }
    }

    private func makePixelButton(text: String, width: CGFloat, height: CGFloat, y: CGFloat,
                                  fill: SKColor) -> SKNode {
        let btn = SKNode()
        btn.position  = CGPoint(x: 0, y: y)
        btn.zPosition = 2

        let bg = px(width, height, fill: fill, stroke: Px.white.withAlphaComponent(0.35), sw: 2)
        btn.addChild(bg)

        let lbl = pixelLabel(text, size: 15, color: Px.white)
        lbl.position = CGPoint(x: 0, y: -5)
        btn.addChild(lbl)
        return btn
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let pos = t.location(in: self)

        if pauseBtn.contains(pos) { togglePause(); return }

        if isPaused_game {
            if let overlay = pauseOverlay {
                let lp = t.location(in: overlay)
                if let resume = overlay.childNode(withName: "resumeBtn"),
                   resume.contains(lp) {
                    togglePause()
                } else if let quit = overlay.childNode(withName: "quitBtn"),
                          quit.contains(lp) {
                    // Resume elapsed accounting, then navigate to title (not result)
                    resumeElapsedTime()
                    isPaused_game = false
                    self.speed    = 1
                    hidePauseOverlay()
                    removeAction(forKey: "timer")
                    after(0.05) { [weak self] in
                        self?.gameDelegate?.gameDidQuitToTitle()
                    }
                }
            }
            return
        }

        guard !isControlLocked else { return }
        swipeStart  = pos
        swipeTime   = Date()
        swipeActive = true
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first, swipeActive, !isPaused_game else { return }
        swipeActive = false
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
        guard let obj = currentObject, !obj.isResolved, !isControlLocked else { return }
        let swipeVec = lastSwipeDelta

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
            flashText("MISS!", color: Px.amber)
            flyAway(obj, dirVector: swipeVec, spin: true)
            spawnNextObject()

        case (.garbage, .right):
            obj.isResolved = true
            obj.removeAllActions()
            flashText("CAUGHT!", color: Px.green)
            netCatchAnimation(obj)
            spawnNextObject()

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
            flashText("SAVED!", color: Px.green)
            handCatchAnimation(obj)
            spawnNextObject()

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
        guard !obj.isResolved else { return }
        obj.isResolved = true
        switch obj.objectType {
        case .food:    autoEatFood(obj)
        case .garbage: autoEatGarbage(obj)
        case .bomb:    autoEatBomb(obj)
        }
    }

    // MARK: - Spawn

    private func spawnNextObject() {
        guard !isPaused_game else { return }

        let type: ObjectType
        if isTutorial {
            if tutorialIndex < GameConstants.tutorialSequence.count {
                type = GameConstants.tutorialSequence[tutorialIndex]
                tutorialIndex += 1
                showHint(for: type)
            } else {
                isTutorial     = false
                hintLabel.text = ""
                type = randomType()
            }
        } else {
            type = randomType()
        }

        let obj = FallingObjectNode(type: type)
        obj.position  = CGPoint(x: 0, y: spawnY)
        obj.zPosition = 15
        addChild(obj)
        currentObject = obj

        let speed    = GameConstants.fallSpeed(foodEaten: foodEaten, mode: gameMode)
        // In survival the lobster sits on the floor so the fall distance shrinks as it grows.
        // spawnY is fixed; lobsterY is also fixed but the lobster visually fills more
        // of the screen. The actual collision y is still lobsterY so distance is constant —
        // but the lobster body is huge, making it *feel* faster, which is the design intent.
        let distance = spawnY - lobsterY
        let duration = TimeInterval(distance / speed)

        obj.run(SKAction.sequence([
            SKAction.moveTo(y: lobsterY, duration: duration),
            SKAction.run { [weak self] in self?.autoResolve(obj: obj) }
        ]))
    }

    private func randomType() -> ObjectType {
        let w = GameConstants.spawnWeights(foodEaten: foodEaten, mode: gameMode)
        let r = Double.random(in: 0..<1)
        if r < w.food             { return .food }
        if r < w.food + w.garbage { return .garbage }
        return .bomb
    }

    private func showHint(for type: ObjectType) {
        switch type {
        case .food:    hintLabel.text = "SWIPE DOWN to eat!"
        case .garbage: hintLabel.text = "SWIPE RIGHT → net catches it!"
        case .bomb:    hintLabel.text = "SWIPE LEFT ← hand takes it!"
        }
    }

    // MARK: - Outcomes

    private func autoEatFood(_ obj: FallingObjectNode) {
        foodEaten += 1
        flashText("+1 NOM!", color: Px.green)
        chompAnimation(obj)
        foodGlowPop()

        if gameMode == .chain {
            strainChain()
            refreshBar()
            progressLabel.text = "\(foodEaten)/\(GameConstants.chainBreakTarget)"
            checkChainBreak()
            if foodEaten < GameConstants.chainBreakTarget { spawnNextObject() }
        } else {
            // Survival: just update count label and keep going
            progressLabel.text = "FOOD: \(foodEaten)"
            spawnNextObject()
        }
    }

    private func autoEatGarbage(_ obj: FallingObjectNode) {
        garbageMistakes += 1
        if foodEaten > 0 {
            foodEaten -= 1
            if gameMode == .chain {
                refreshBar()
                progressLabel.text = "\(foodEaten)/\(GameConstants.chainBreakTarget)"
                strainChain()
            } else {
                progressLabel.text = "FOOD: \(foodEaten)"
            }
        }
        isControlLocked = true
        flashText("BLECH! -1", color: Px.orange)
        garbageDisgustAnimation(obj)
        after(GameConstants.vomitDuration) { [weak self] in
            self?.isControlLocked = false
            self?.spawnNextObject()
        }
    }

    private func autoEatBomb(_ obj: FallingObjectNode) {
        isControlLocked = true
        removeAction(forKey: "timer")
        elapsedTime = currentElapsed()
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
        isControlLocked = true
        removeAction(forKey: "timer")
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

        spawnPixelSparks(at: CGPoint(x: 0, y: lobsterY - bodyH/2 - 14), color: Px.amber,  count: 20)
        spawnPixelSparks(at: CGPoint(x: 0, y: lobsterY - bodyH/2 - 14), color: Px.orange, count: 14)

        flashText("FREE!!!", color: Px.amber)
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
        let lbl = pixelLabel("THANK YOU, GOODBYE!", size: 16, color: Px.white)
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
        ])) { obj.removeFromParent() }

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
        ])) { obj.removeFromParent() }

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
        flashText("BOOM!", color: Px.red)

        obj.run(SKAction.sequence([
            SKAction.scale(to: 3.0, duration: 0.10),
            SKAction.fadeOut(withDuration: 0.16)
        ])) { obj.removeFromParent() }

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
            SKAction.removeFromParent()
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
            SKAction.removeFromParent()
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
        obj.run(SKAction.group(acts)) { obj.removeFromParent() }
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
            cap.text = "CHAIN: \(max(foodEaten, 0))/\(GameConstants.chainBreakTarget)"
        }
    }

    private func tickTimer() {
        guard !isPaused_game else { return }
        elapsedTime     = currentElapsed()
        timerLabel.text = String(format: "%.1fs", elapsedTime)
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
