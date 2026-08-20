import SwiftUI

/// Quiet luxury palette — graphite, platinum, muted P&L. No neon.
enum LiquidGlassTheme {
    /// Primary interactive accent (platinum)
    static let accent = Color(red: 0.78, green: 0.80, blue: 0.84)
    /// Secondary accent (warm stone)
    static let accentMuted = Color(red: 0.62, green: 0.58, blue: 0.52)
    /// Tertiary (soft champagne, use sparingly)
    static let accentSoft = Color(red: 0.72, green: 0.66, blue: 0.55)

    /// Legacy aliases — remapped away from neon cyan/purple
    static let accentCyan = accent
    static let accentPurple = accentMuted
    static let accentGold = accentSoft

    static let profitGreen = Color(red: 0.45, green: 0.68, blue: 0.55)
    static let lossRed = Color(red: 0.78, green: 0.48, blue: 0.45)

    static let backgroundTop = Color(red: 0.05, green: 0.05, blue: 0.055)
    static let backgroundMid = Color(red: 0.07, green: 0.07, blue: 0.075)
    static let backgroundBottom = Color(red: 0.09, green: 0.085, blue: 0.08)

    static let textPrimary = Color.white.opacity(0.92)
    static let textSecondary = Color.white.opacity(0.48)
    static let textTertiary = Color.white.opacity(0.28)

    static let glassBorder = Color.white.opacity(0.12)
    static let glassHighlight = Color.white.opacity(0.28)
    static let glassShadow = Color.black.opacity(0.22)

    static let cardCornerRadius: CGFloat = 20
    static let buttonCornerRadius: CGFloat = 14
}

struct LiquidBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    LiquidGlassTheme.backgroundTop,
                    LiquidGlassTheme.backgroundMid,
                    LiquidGlassTheme.backgroundBottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Single soft light — top-left, barely there
            RadialGradient(
                colors: [
                    Color.white.opacity(0.06),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 10,
                endRadius: 420
            )

            // Faint warm wash at bottom
            RadialGradient(
                colors: [
                    LiquidGlassTheme.accentSoft.opacity(0.04),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 20,
                endRadius: 360
            )
        }
        .ignoresSafeArea()
    }
}

struct GlassOrb: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.18),
                            Color.white.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            LiquidGlassTheme.glassHighlight,
                            LiquidGlassTheme.glassBorder,
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )

            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: size * 0.28, weight: .light))
                .foregroundStyle(LiquidGlassTheme.textPrimary.opacity(0.85))
        }
        .frame(width: size, height: size)
        .liquidGlass(cornerRadius: size / 2, opacity: 0.08, borderOpacity: 0.15)
    }
}
