//
//  LobsterComponents.swift
//  MyLobster
//
//  Shared pixel-art lobster SwiftUI view + SF Symbol icon helpers used across
//  TitleView, ResultView, and GameScene.
//

import SwiftUI
import SpriteKit
import UIKit

// MARK: - SF Symbol → SKSpriteNode (reliable on all devices & simulators)

/// Renders an SF Symbol into an SKSpriteNode.
/// Falls back to a coloured square with a bold letter if the symbol name is unknown.
func symbolSprite(named systemName: String,
                  size: CGFloat,
                  tint: UIColor,
                  weight: UIImage.SymbolWeight = .bold) -> SKSpriteNode {
    let cfg = UIImage.SymbolConfiguration(pointSize: size * 0.55, weight: weight)
    if let raw = UIImage(systemName: systemName, withConfiguration: cfg) {
        let coloured = raw.withTintColor(tint, renderingMode: .alwaysOriginal)
        let canvas = CGSize(width: size, height: size)
        let renderer = UIGraphicsImageRenderer(size: canvas)
        let img = renderer.image { _ in
            let origin = CGPoint(x: (canvas.width  - coloured.size.width)  / 2,
                                 y: (canvas.height - coloured.size.height) / 2)
            coloured.draw(at: origin)
        }
        let node = SKSpriteNode(texture: SKTexture(image: img))
        node.size = canvas
        return node
    }
    return fallbackSquare(size: size, color: tint)
}

private func fallbackSquare(size: CGFloat, color: UIColor) -> SKSpriteNode {
    let canvas = CGSize(width: size, height: size)
    let renderer = UIGraphicsImageRenderer(size: canvas)
    let img = renderer.image { ctx in
        color.setFill()
        ctx.cgContext.fill(CGRect(origin: .zero, size: canvas))
    }
    let node = SKSpriteNode(texture: SKTexture(image: img))
    node.size = canvas
    return node
}

// MARK: - Falling object symbol name tables

enum ObjectIcon {
    static let food: [(symbol: String, tint: UIColor)] = [
        ("fork.knife",       UIColor(red: 0.95, green: 0.88, blue: 0.20, alpha: 1)),
        ("birthday.cake",    UIColor(red: 1.00, green: 0.70, blue: 0.30, alpha: 1)),
        ("fish",             UIColor(red: 0.40, green: 0.80, blue: 1.00, alpha: 1)),
        ("carrot",           UIColor(red: 1.00, green: 0.60, blue: 0.15, alpha: 1)),
        ("leaf.fill",        UIColor(red: 0.30, green: 0.95, blue: 0.35, alpha: 1)),
        ("flame.fill",       UIColor(red: 1.00, green: 0.70, blue: 0.20, alpha: 1)),
        ("popcorn.fill",     UIColor(red: 1.00, green: 0.92, blue: 0.40, alpha: 1)),
    ]

    static let garbage: [(symbol: String, tint: UIColor)] = [
        ("trash.fill",       UIColor(red: 0.55, green: 0.55, blue: 0.55, alpha: 1)),
        ("bag.fill",         UIColor(red: 0.50, green: 0.45, blue: 0.42, alpha: 1)),
        ("shoe.fill",        UIColor(red: 0.48, green: 0.38, blue: 0.30, alpha: 1)),
        ("tshirt.fill",      UIColor(red: 0.44, green: 0.44, blue: 0.50, alpha: 1)),
        ("battery.0percent", UIColor(red: 0.52, green: 0.52, blue: 0.52, alpha: 1)),
    ]

    static let bomb: (symbol: String, tint: UIColor) =
        ("bolt.fill",        UIColor(red: 0.95, green: 0.20, blue: 0.15, alpha: 1))

    static func randomFood()    -> (symbol: String, tint: UIColor) { food.randomElement()! }
    static func randomGarbage() -> (symbol: String, tint: UIColor) { garbage.randomElement()! }
}

// MARK: - Pixel palette (mirrors GameScene's Px enum for SwiftUI)

private enum PxColor {
    static let lobRed   = Color(red: 0.88, green: 0.26, blue: 0.06)
    static let lobDark  = Color(red: 0.58, green: 0.10, blue: 0.02)
    static let lobShell = Color(red: 0.72, green: 0.18, blue: 0.04)
    static let nearBlk  = Color(red: 0.08, green: 0.06, blue: 0.06)
    static let cream    = Color(red: 0.92, green: 0.92, blue: 0.86)
}

// MARK: - Pixel helper for SwiftUI Canvas

private func pixelRect(_ ctx: inout GraphicsContext,
                       x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat,
                       fill: Color, stroke: Color = .clear, lineWidth: CGFloat = 0) {
    let r = CGRect(x: x, y: y, width: w, height: h)
    ctx.fill(Path(r), with: .color(fill))
    if lineWidth > 0 {
        ctx.stroke(Path(r), with: .color(stroke), lineWidth: lineWidth)
    }
}

// MARK: - Pixel Drawn Lobster (SwiftUI Canvas) — used on TitleView & ResultView

struct DrawnLobsterView: View {
    var mouthOpen: Bool = false
    var sickFace:  Bool = false
    var animated:  Bool = true

    @State private var bob: CGFloat = 0

    var body: some View {
        Canvas { ctx, sz in
            drawPixelLobster(&ctx, size: sz)
        }
        .offset(y: bob)
        .onAppear {
            guard animated else { return }
            withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: true)) {
                bob = -6
            }
        }
    }

    // MARK: - Pixel block lobster drawing

    private func drawPixelLobster(_ ctx: inout GraphicsContext, size: CGSize) {
        // Canvas is e.g. 120×120; we draw relative to centre
        let cx = (size.width  / 2).rounded()
        let cy = (size.height / 2).rounded()

        // Convenience wrappers that centre-offset coordinates
        func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat,
                  _ fill: Color, stroke: Color = .clear, lw: CGFloat = 0) {
            pixelRect(&ctx,
                      x: (cx + x - w/2).rounded(),
                      y: (cy + y - h/2).rounded(),
                      w: w, h: h,
                      fill: fill, stroke: stroke, lineWidth: lw)
        }

        // ── Tail (3 rect blocks below body, stairstepped) ──
        let tailOffsets: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (-12, 26, 10, 18),   // left segment
            (  0, 28, 14, 22),   // centre segment (tallest)
            ( 12, 26, 10, 18),   // right segment
        ]
        for (tx, ty, tw, th) in tailOffsets {
            rect(tx, ty, tw, th, PxColor.lobDark,
                 stroke: PxColor.lobShell, lw: 1)
            // rib line inside each segment
            rect(tx, ty - 2, tw - 4, 2, PxColor.lobShell)
        }

        // ── Arms (blocky side limbs) ──
        for xOff: CGFloat in [-22, 22] {
            rect(xOff, 10, 8, 24, PxColor.lobDark)
        }

        // ── Claws ──
        for (xOff, flip) in [(-32.0, false), (32.0, true)] as [(CGFloat, Bool)] {
            // Main claw block
            rect(xOff, -8, 22, 16, PxColor.lobRed,
                 stroke: PxColor.lobDark, lw: 1)
            // Pincer block
            let pincerX = xOff + (flip ? -6.0 : 6.0)
            rect(pincerX, 4, 10, 8, PxColor.lobDark)
            // Claw highlight
            rect(xOff - 4, -12, 6, 4, PxColor.lobShell)
        }

        // ── Body ──
        rect(0, -4, 56, 60, PxColor.lobRed,
             stroke: PxColor.lobDark, lw: 1.5)

        // Sheen stripe (top of body)
        rect(0, -22, 14, 6, PxColor.lobShell.opacity(0.7))

        // Shell segment lines (4 horizontal pixel lines on body)
        let segColors: [Color] = [PxColor.lobShell, PxColor.lobDark, PxColor.lobShell, PxColor.lobDark]
        for (i, col) in segColors.enumerated() {
            rect(0, CGFloat(-10 + i * 10), 44, 2, col)
        }

        // ── Antennae (stairstepped pixel squares, left & right) ──
        for (side, xDir) in [(-1.0, -1.0), (1.0, 1.0)] as [(CGFloat, CGFloat)] {
            let ax: CGFloat = side * 8
            let ay: CGFloat = -34
            for step in 0..<5 {
                let stepX = ax + xDir * CGFloat(step) * 4
                let stepY = ay - CGFloat(step) * 7
                rect(stepX, stepY, 4, 4, PxColor.lobDark)
            }
        }

        // ── Eyes on stalks ──
        for xOff: CGFloat in [-10, 10] {
            // Stalk (thin vertical block)
            rect(xOff, -30, 4, 8, PxColor.lobDark)

            if sickFace {
                // X eyes — two diagonal pixel strokes
                let ex = cx + xOff
                let ey = cy - 38
                var xp1 = Path()
                xp1.move(to: CGPoint(x: ex - 4, y: ey - 4))
                xp1.addLine(to: CGPoint(x: ex + 4, y: ey + 4))
                ctx.stroke(xp1, with: .color(PxColor.nearBlk), lineWidth: 2)
                var xp2 = Path()
                xp2.move(to: CGPoint(x: ex + 4, y: ey - 4))
                xp2.addLine(to: CGPoint(x: ex - 4, y: ey + 4))
                ctx.stroke(xp2, with: .color(PxColor.nearBlk), lineWidth: 2)
            } else {
                // White eyeball block
                rect(xOff, -38, 8, 8, PxColor.cream,
                     stroke: PxColor.lobDark, lw: 1)
                // Pupil block
                rect(xOff + 1, -38, 4, 4, PxColor.nearBlk)
                // Catchlight
                rect(xOff - 1, -40, 2, 2, PxColor.cream)
            }
        }

        // ── Mouth ──
        if mouthOpen {
            // Open: wide dark rect on lower body
            rect(0, -4, 18, 10, PxColor.nearBlk)
            // Tooth block
            rect(-4, -4, 4, 4, PxColor.cream)
            rect( 4, -4, 4, 4, PxColor.cream)
        } else if sickFace {
            // Sick: wavy squiggle — draw as 3 small pixel dots in a frown shape
            for (mx, my): (CGFloat, CGFloat) in [(-6, -5), (0, -8), (6, -5)] {
                rect(mx, my, 3, 3, PxColor.nearBlk)
            }
        } else {
            // Normal smile — 3 pixel dots in an arc
            for (mx, my): (CGFloat, CGFloat) in [(-6, -7), (0, -4), (6, -7)] {
                rect(mx, my, 3, 3, PxColor.nearBlk)
            }
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        DrawnLobsterView()
            .frame(width: 120, height: 120)
        DrawnLobsterView(mouthOpen: true)
            .frame(width: 120, height: 120)
        DrawnLobsterView(sickFace: true)
            .frame(width: 120, height: 120)
    }
    .padding(20)
    .background(Color(red: 0.04, green: 0.07, blue: 0.16))
}
