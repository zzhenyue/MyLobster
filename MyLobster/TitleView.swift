//
//  TitleView.swift
//  MyLobster
//  Pixel-art style title + mode-selection screen.
//

import SwiftUI

// MARK: - Pixel colour shorthands (local to this file)

private extension Color {
    static let pxNavy   = Color(red: 0.04, green: 0.07, blue: 0.16)
    static let pxOcean1 = Color(red: 0.06, green: 0.12, blue: 0.24)
    static let pxOcean2 = Color(red: 0.08, green: 0.18, blue: 0.32)
    static let pxOcean3 = Color(red: 0.10, green: 0.24, blue: 0.40)
    static let pxCream  = Color(red: 0.92, green: 0.92, blue: 0.86)
    static let pxAmber  = Color(red: 0.95, green: 0.72, blue: 0.06)
    static let pxGreen  = Color(red: 0.10, green: 0.72, blue: 0.22)
    static let pxRed    = Color(red: 0.90, green: 0.14, blue: 0.10)
    static let pxSand   = Color(red: 0.55, green: 0.44, blue: 0.26)
    static let pxGold   = Color(red: 0.96, green: 0.82, blue: 0.10)
}

// MARK: - TitleView

struct TitleView: View {
    let onPlay: (GameMode) -> Void

    @State private var selectedMode: GameMode = .chain

    var body: some View {
        ZStack {
            // ── Pixel ocean background bands ──
            GeometryReader { geo in
                let W = geo.size.width
                let H = geo.size.height
                let bands: [(Color, CGFloat, CGFloat)] = [
                    (.pxNavy,   0.00, 0.28),
                    (.pxOcean1, 0.28, 0.52),
                    (.pxOcean2, 0.52, 0.74),
                    (.pxOcean3, 0.74, 1.00),
                ]
                ForEach(Array(bands.enumerated()), id: \.offset) { _, band in
                    let (col, top, bot) = band
                    Rectangle()
                        .fill(col)
                        .frame(width: W, height: (bot - top) * H)
                        .position(x: W/2, y: H - (top + (bot - top)/2) * H)
                }

                // Pixel bubble squares
                let bubbleDefs: [(CGFloat, CGFloat, CGFloat)] = [
                    (0.12, 0.22, 22), (0.78, 0.32, 14), (0.40, 0.12, 18),
                    (0.65, 0.55, 10), (0.22, 0.65, 26), (0.88, 0.18, 8),
                    (0.55, 0.78, 16), (0.08, 0.45, 12), (0.70, 0.70, 20),
                ]
                ForEach(Array(bubbleDefs.enumerated()), id: \.offset) { _, bd in
                    let (xf, yf, s) = bd
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: s, height: s)
                        .position(x: xf * W, y: yf * H)
                }

                // Sand floor
                Rectangle()
                    .fill(Color.pxSand)
                    .frame(width: W, height: 16)
                    .position(x: W/2, y: H - 8)
                Rectangle()
                    .fill(Color.pxSand.opacity(0.6))
                    .frame(width: W, height: 6)
                    .position(x: W/2, y: H - 19)
            }
            .ignoresSafeArea()

            // ── Content ──
            VStack(spacing: 0) {
                Spacer()

                // Pixel lobster hero
                DrawnLobsterView(animated: true)
                    .frame(width: 120, height: 120)
                    .padding(.bottom, 10)

                // Title
                Text("MY LOBSTER")
                    .font(.system(size: 34, weight: .black, design: .monospaced))
                    .foregroundColor(.pxCream)
                    .shadow(color: .black.opacity(0.6), radius: 0, x: 3, y: 3)
                    .padding(.bottom, 2)

                Text("FEED. GROW. ESCAPE.")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.pxAmber)
                    .padding(.bottom, 20)

                // ── Mode picker ──
                VStack(spacing: 0) {
                    Text("SELECT MODE")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundColor(.pxCream.opacity(0.55))
                        .padding(.bottom, 8)

                    HStack(spacing: 10) {
                        modeTile(
                            mode: .chain,
                            icon: "link",
                            title: "CHAIN",
                            subtitle: "Eat 30.\nBreak free."
                        )
                        modeTile(
                            mode: .survival,
                            icon: "infinity",
                            title: "SURVIVAL",
                            subtitle: "Eat forever.\nGrow huge."
                        )
                    }
                }
                .padding(.bottom, 16)

                // ── PLAY button ──
                Button(action: { onPlay(selectedMode) }) {
                    Text("[ PLAY ]")
                        .font(.system(size: 24, weight: .black, design: .monospaced))
                        .foregroundColor(.pxNavy)
                        .frame(width: 200, height: 54)
                        .background(Color.pxCream)
                        .overlay(alignment: .bottomTrailing) {
                            Rectangle()
                                .fill(Color.black.opacity(0.45))
                                .frame(width: 200, height: 54)
                                .offset(x: 4, y: 4)
                                .zIndex(-1)
                        }
                }
                .padding(.bottom, 20)

                // ── Control badges ──
                HStack(spacing: 8) {
                    controlBadge(
                        icon: "fork.knife",  iconColor: .pxGreen,
                        label: "FOOD",  swipe: "↓ EAT",     miss: "↑←→ MISS"
                    )
                    controlBadge(
                        icon: "trash.fill",  iconColor: .pxCream.opacity(0.7),
                        label: "TRASH", swipe: "→ NET",      miss: "OTHER = -1"
                    )
                    controlBadge(
                        icon: "bolt.fill",   iconColor: .pxRed,
                        label: "BOMB",  swipe: "← HAND",    miss: "OTHER = BOOM"
                    )
                }
                .padding(.bottom, 8)

                Text("Trash = lose progress  •  Wrong bomb = instant death!")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundColor(.pxCream.opacity(0.40))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 6)

                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Mode tile

    @ViewBuilder
    private func modeTile(mode: GameMode, icon: String, title: String, subtitle: String) -> some View {
        let isSelected = selectedMode == mode
        let borderColor: Color = isSelected
            ? (mode == .survival ? .pxGold : .pxAmber)
            : Color.white.opacity(0.18)
        let bgOpacity: Double = isSelected ? 0.16 : 0.07
        let titleColor: Color = isSelected
            ? (mode == .survival ? .pxGold : .pxAmber)
            : .pxCream

        Button(action: { selectedMode = mode }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(titleColor)

                Text(title)
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(titleColor)

                Text(subtitle)
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundColor(.pxCream.opacity(0.60))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            .frame(width: 130, height: 88)
            .background(Color.white.opacity(bgOpacity))
            .overlay(
                Rectangle()
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Control badge

    @ViewBuilder
    private func controlBadge(icon: String, iconColor: Color,
                               label: String, swipe: String, miss: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .black))
                .foregroundColor(iconColor)
                .frame(height: 22)
            Text(label)
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundColor(.pxCream)
            Text(swipe)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.pxAmber)
            Text(miss)
                .font(.system(size: 8, weight: .regular, design: .monospaced))
                .foregroundColor(.pxCream.opacity(0.5))
        }
        .frame(width: 96, height: 80)
        .background(Color.white.opacity(0.07))
        .overlay(Rectangle().stroke(Color.white.opacity(0.18), lineWidth: 1))
    }
}

#Preview {
    TitleView(onPlay: { _ in })
}
