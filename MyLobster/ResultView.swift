//
//  ResultView.swift
//  MyLobster
//  Pixel-art style result screen — supports both Chain and Survival modes.
//

import SwiftUI

// MARK: - Pixel colour shorthands (local to this file)

private extension Color {
    static let pxNavy    = Color(red: 0.04, green: 0.07, blue: 0.16)
    static let pxWinDark = Color(red: 0.03, green: 0.18, blue: 0.10)
    static let pxWinMid  = Color(red: 0.05, green: 0.28, blue: 0.42)
    static let pxLoseDk  = Color(red: 0.20, green: 0.04, blue: 0.02)
    static let pxLoseMd  = Color(red: 0.10, green: 0.05, blue: 0.20)
    static let pxCream   = Color(red: 0.92, green: 0.92, blue: 0.86)
    static let pxAmber   = Color(red: 0.95, green: 0.72, blue: 0.06)
    static let pxGold    = Color(red: 0.96, green: 0.82, blue: 0.10)
    static let pxRed     = Color(red: 0.90, green: 0.14, blue: 0.10)
}

// MARK: - ResultView

struct ResultView: View {
    let result:          GameResult
    let bestTime:        TimeInterval?   // chain mode personal best
    let bestSurvivalFood: Int?           // survival mode personal best
    let onRestart:       () -> Void

    @State private var appeared = false

    private var isNewBestChain: Bool {
        guard result.mode == .chain, result.won else { return false }
        guard let best = bestTime else { return true }
        return result.completionTime < best
    }

    private var isNewBestSurvival: Bool {
        guard result.mode == .survival else { return false }
        guard let best = bestSurvivalFood else { return true }
        return result.foodEaten > best
    }

    var body: some View {
        ZStack {
            // ── Pixel background bands ──
            GeometryReader { geo in
                let W = geo.size.width
                let H = geo.size.height
                let (darkBand, lightBand): (Color, Color) = result.won
                    ? (.pxWinDark, .pxWinMid)
                    : (.pxLoseDk,  .pxLoseMd)
                Rectangle()
                    .fill(darkBand)
                    .frame(width: W, height: H * 0.5)
                    .position(x: W/2, y: H * 0.75)
                Rectangle()
                    .fill(lightBand)
                    .frame(width: W, height: H * 0.5)
                    .position(x: W/2, y: H * 0.25)

                let bubbles: [(CGFloat, CGFloat, CGFloat)] = [
                    (0.10, 0.15, 14), (0.82, 0.28, 10),
                    (0.50, 0.08, 18), (0.28, 0.72, 12),
                    (0.75, 0.65, 16), (0.42, 0.40, 8),
                ]
                ForEach(Array(bubbles.enumerated()), id: \.offset) { _, bd in
                    let (xf, yf, s) = bd
                    Rectangle()
                        .fill(Color.white.opacity(0.04))
                        .frame(width: s, height: s)
                        .position(x: xf * W, y: yf * H)
                }
            }
            .ignoresSafeArea()

            // ── Content ──
            VStack(spacing: 0) {
                Spacer()

                // Hero
                if result.won {
                    DrawnLobsterView(animated: true)
                        .frame(width: 110, height: 110)
                        .scaleEffect(appeared ? 1.0 : 0.2)
                        .opacity(appeared ? 1 : 0)
                        .animation(.linear(duration: 0.18), value: appeared)
                        .padding(.bottom, 12)
                } else {
                    Image(systemName: "xmark.octagon.fill")
                        .font(.system(size: 78, weight: .black))
                        .foregroundColor(.pxRed)
                        .scaleEffect(appeared ? 1.0 : 0.2)
                        .opacity(appeared ? 1 : 0)
                        .animation(.linear(duration: 0.18), value: appeared)
                        .padding(.bottom, 12)
                }

                // Mode badge
                Text(result.mode == .survival ? "SURVIVAL MODE" : "CHAIN MODE")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundColor(result.mode == .survival ? .pxGold : .pxAmber)
                    .padding(.bottom, 4)

                // Status title
                Text(statusTitle)
                    .font(.system(size: 26, weight: .black, design: .monospaced))
                    .foregroundColor(.pxCream)
                    .shadow(color: .black.opacity(0.6), radius: 0, x: 2, y: 2)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 6)

                // New best badge
                if isNewBestChain || isNewBestSurvival {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(.pxGold)
                        Text("NEW PERSONAL BEST!")
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                            .foregroundColor(.pxGold)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.pxGold.opacity(0.15))
                    .overlay(Rectangle().stroke(Color.pxGold.opacity(0.5), lineWidth: 1))
                    .padding(.bottom, 16)
                } else {
                    Spacer().frame(height: 22)
                }

                // ── Stats card ──
                VStack(spacing: 0) {
                    if result.mode == .chain && result.won {
                        statRow(label: "COMPLETION TIME",
                                value: formattedTime(result.completionTime),
                                valueColor: .pxAmber)
                        pixelDivider()
                    }
                    statRow(label: result.mode == .chain
                                ? "FOOD EATEN"
                                : "FOOD EATEN (BEST)",
                            value: result.mode == .chain
                                ? "\(result.foodEaten) / \(GameConstants.chainBreakTarget)"
                                : "\(result.foodEaten)")
                    pixelDivider()
                    statRow(label: "TRASH EATEN",
                            value: "\(result.garbageMistakes)",
                            valueColor: result.garbageMistakes > 0 ? .pxRed : .pxCream)
                    pixelDivider()
                    statRow(label: "CAUSE OF DEATH",
                            icon: "bolt.fill",
                            value: "BOMB",
                            valueColor: .pxRed)

                    // Personal best row
                    if result.mode == .chain, let best = bestTime {
                        pixelDivider()
                        statRow(label: "BEST TIME", value: formattedTime(best))
                    } else if result.mode == .survival, let best = bestSurvivalFood {
                        pixelDivider()
                        statRow(label: "BEST FOOD", value: "\(best)")
                    }
                }
                .background(Color.white.opacity(0.08))
                .overlay(Rectangle().stroke(Color.white.opacity(0.18), lineWidth: 1))
                .padding(.horizontal, 28)
                .padding(.bottom, 32)

                // ── Play Again button ──
                Button(action: onRestart) {
                    Text("[ PLAY AGAIN ]")
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundColor(.pxNavy)
                        .frame(width: 230, height: 54)
                        .background(Color.pxCream)
                        .overlay(alignment: .bottomTrailing) {
                            Rectangle()
                                .fill(Color.black.opacity(0.4))
                                .frame(width: 230, height: 54)
                                .offset(x: 4, y: 4)
                                .zIndex(-1)
                        }
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .onAppear { appeared = true }
    }

    // MARK: - Helpers

    private var statusTitle: String {
        if result.mode == .survival { return "BOOM! \(result.foodEaten) FOOD" }
        return result.won ? "YOU BROKE FREE!" : "BOMB HIT!"
    }

    @ViewBuilder
    private func statRow(label: String, icon: String? = nil,
                         value: String, valueColor: Color = .pxCream) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.pxCream.opacity(0.65))
            Spacer()
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.pxRed)
            }
            Text(value)
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundColor(valueColor)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func pixelDivider() -> some View {
        Rectangle()
            .fill(Color.white.opacity(0.12))
            .frame(height: 1)
            .padding(.horizontal, 10)
    }

    private func formattedTime(_ t: TimeInterval) -> String {
        String(format: "%.2fs", t)
    }
}

#Preview {
    ResultView(
        result: GameResult(won: false, completionTime: 38.5,
                           foodEaten: 22, garbageMistakes: 3, mode: .survival),
        bestTime: nil,
        bestSurvivalFood: 18,
        onRestart: {}
    )
}
