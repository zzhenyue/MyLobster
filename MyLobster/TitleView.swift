//
//  TitleView.swift
//  MyLobster
//  Pixel-art style title + mode-selection screen. Supports ZH / EN.
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
    static let pxSand   = Color(red: 0.55, green: 0.44, blue: 0.26)
    static let pxGold   = Color(red: 0.96, green: 0.82, blue: 0.10)
}

// MARK: - TitleView

struct TitleView: View {
    let onPlay: (GameMode) -> Void

    @State  private var selectedMode: GameMode = .chain
    // Language stored in UserDefaults so it persists across launches
    @AppStorage("language") private var langRaw: String = AppLanguage.zh.rawValue

    private var loc: L { L(lang: AppLanguage(rawValue: langRaw) ?? .zh) }

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

            // ── Language toggle — top-right corner ──
            VStack {
                HStack {
                    Spacer()
                    langToggleButton
                        .padding(.top, 54)
                        .padding(.trailing, 20)
                }
                Spacer()
            }

            // ── Main content ──
            VStack(spacing: 0) {
                Spacer()

                // Pixel lobster hero
                DrawnLobsterView(animated: true)
                    .frame(width: 120, height: 120)
                    .padding(.bottom, 10)

                // Title
                Text(loc.appTitle)
                    .font(titleFont)
                    .foregroundColor(.pxCream)
                    .shadow(color: .black.opacity(0.6), radius: 0, x: 3, y: 3)
                    .padding(.bottom, 28)

                // ── Mode picker ──
                VStack(spacing: 0) {
                    Text(loc.selectMode)
                        .font(captionFont)
                        .foregroundColor(.pxCream.opacity(0.55))
                        .padding(.bottom, 10)

                    HStack(spacing: 12) {
                        modeTile(mode: .chain,
                                 icon: "link",
                                 title: loc.chainTitle,
                                 subtitle: loc.chainSubtitle)
                        modeTile(mode: .survival,
                                 icon: "infinity",
                                 title: loc.survivalTitle,
                                 subtitle: loc.survivalSubtitle)
                    }
                }
                .padding(.bottom, 28)

                // ── PLAY button ──
                Button(action: { onPlay(selectedMode) }) {
                    Text(loc.playButton)
                        .font(playFont)
                        .foregroundColor(.pxNavy)
                        .frame(width: 220, height: 58)
                        .background(Color.pxCream)
                        .overlay(alignment: .bottomTrailing) {
                            Rectangle()
                                .fill(Color.black.opacity(0.45))
                                .frame(width: 220, height: 58)
                                .offset(x: 4, y: 4)
                                .zIndex(-1)
                        }
                }

                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Language toggle button

    @ViewBuilder
    private var langToggleButton: some View {
        let isZh = langRaw == AppLanguage.zh.rawValue
        Button(action: {
            langRaw = isZh ? AppLanguage.en.rawValue : AppLanguage.zh.rawValue
        }) {
            ZStack {
                Rectangle()
                    .fill(Color.white.opacity(0.10))
                Rectangle()
                    .stroke(Color.white.opacity(0.30), lineWidth: 1)
            }
            .frame(width: 48, height: 30)
            .overlay(
                Text(isZh ? "EN" : "中文")
                    .font(.system(size: isZh ? 13 : 11, weight: .black, design: .monospaced))
                    .foregroundColor(.pxCream)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Font helpers (CJK needs system font, not monospaced)

    private var isZh: Bool { langRaw == AppLanguage.zh.rawValue }
    private var titleFont: Font {
        isZh ? .system(size: 36, weight: .black)
              : .system(size: 38, weight: .black, design: .monospaced)
    }
    private var captionFont: Font {
        isZh ? .system(size: 13, weight: .black)
              : .system(size: 12, weight: .black, design: .monospaced)
    }
    private var playFont: Font {
        isZh ? .system(size: 24, weight: .black)
              : .system(size: 26, weight: .black, design: .monospaced)
    }

    // MARK: - Mode tile

    @ViewBuilder
    private func modeTile(mode: GameMode, icon: String, title: String, subtitle: String) -> some View {
        let isSelected  = selectedMode == mode
        let borderColor: Color = isSelected
            ? (mode == .survival ? .pxGold : .pxAmber)
            : Color.white.opacity(0.18)
        let bgOpacity: Double  = isSelected ? 0.16 : 0.07
        let titleColor: Color  = isSelected
            ? (mode == .survival ? .pxGold : .pxAmber)
            : .pxCream

        Button(action: { selectedMode = mode }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .black))
                    .foregroundColor(titleColor)

                Text(title)
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(titleColor)

                Text(subtitle)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.pxCream.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .frame(width: 148, height: 100)
            .background(Color.white.opacity(bgOpacity))
            .overlay(
                Rectangle()
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TitleView(onPlay: { _ in })
}
