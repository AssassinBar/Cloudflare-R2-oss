import SwiftUI

enum LiquidGlassTheme {
    static let accentCyan = Color(red: 0.38, green: 0.92, blue: 0.98)
    static let accentPurple = Color(red: 0.55, green: 0.35, blue: 0.95)
    static let accentGold = Color(red: 0.95, green: 0.78, blue: 0.35)
    static let profitGreen = Color(red: 0.25, green: 0.88, blue: 0.55)
    static let lossRed = Color(red: 0.98, green: 0.35, blue: 0.42)

    static let backgroundTop = Color(red: 0.04, green: 0.05, blue: 0.12)
    static let backgroundBottom = Color(red: 0.08, green: 0.06, blue: 0.18)

    static let glassBorder = Color.white.opacity(0.22)
    static let glassHighlight = Color.white.opacity(0.45)
    static let glassShadow = Color.black.opacity(0.35)

    static let cardCornerRadius: CGFloat = 24
    static let buttonCornerRadius: CGFloat = 16
}

struct LiquidBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [LiquidGlassTheme.backgroundTop, LiquidGlassTheme.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(LiquidGlassTheme.accentPurple.opacity(0.25))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: animate ? -80 : -120, y: animate ? -200 : -160)

            Circle()
                .fill(LiquidGlassTheme.accentCyan.opacity(0.18))
                .frame(width: 280, height: 280)
                .blur(radius: 70)
                .offset(x: animate ? 100 : 140, y: animate ? 300 : 260)

            Circle()
                .fill(LiquidGlassTheme.accentGold.opacity(0.08))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(x: animate ? -60 : 20, y: animate ? 100 : 40)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

struct GlassOrb: View {
    let size: CGFloat
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            LiquidGlassTheme.accentCyan.opacity(0.6),
                            LiquidGlassTheme.accentPurple.opacity(0.3),
                            Color.white.opacity(0.05)
                        ],
                        center: .topLeading,
                        startRadius: 5,
                        endRadius: size * 0.7
                    )
                )

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            LiquidGlassTheme.glassHighlight,
                            LiquidGlassTheme.glassBorder,
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )

            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: size * 0.32, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, LiquidGlassTheme.accentCyan],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .frame(width: size, height: size)
        .liquidGlass(cornerRadius: size / 2)
        .scaleEffect(pulse ? 1.04 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
