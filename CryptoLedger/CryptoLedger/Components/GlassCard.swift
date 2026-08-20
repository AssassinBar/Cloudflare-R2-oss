import SwiftUI

struct GlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = LiquidGlassTheme.cardCornerRadius
    var padding: CGFloat = 20

    init(cornerRadius: CGFloat = LiquidGlassTheme.cardCornerRadius, padding: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .liquidGlass(cornerRadius: cornerRadius)
    }
}

struct CryptoIconView: View {
    let symbol: String
    var size: CGFloat = 40

    private var asset: CryptoAsset? {
        CryptoAsset.find(bySymbol: symbol)
    }

    var body: some View {
        Group {
            if let url = asset?.iconURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        fallbackIcon
                    case .empty:
                        Circle()
                            .fill(Color.white.opacity(0.06))
                    @unknown default:
                        fallbackIcon
                    }
                }
            } else {
                fallbackIcon
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            Circle()
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
        }
    }

    private var fallbackIcon: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.08))
            Text(String(symbol.prefix(1)).uppercased())
                .font(.system(size: size * 0.38, weight: .medium))
                .foregroundStyle(LiquidGlassTheme.textSecondary)
        }
    }
}

struct AnimatedNumber: View {
    let value: Double
    var prefix: String = ""
    var suffix: String = ""
    var decimals: Int = 2
    var color: Color = LiquidGlassTheme.textPrimary

    @State private var displayValue: Double = 0

    var body: some View {
        Text(formatted(displayValue))
            .font(.system(size: 36, weight: .semibold))
            .tracking(-0.8)
            .foregroundStyle(color)
            .contentTransition(.numericText(value: displayValue))
            .onAppear { animateToValue() }
            .onChange(of: value) { _, _ in animateToValue() }
    }

    private func animateToValue() {
        withAnimation(.easeOut(duration: 0.8)) {
            displayValue = value
        }
    }

    private func formatted(_ val: Double) -> String {
        let sign = val > 0 && prefix.isEmpty ? "+" : ""
        return "\(sign)\(prefix)\(String(format: "%.\(decimals)f", val))\(suffix)"
    }
}

struct PnLBadge: View {
    let pnl: Double
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 3) {
            Text(pnl >= 0 ? "▲" : "▼")
                .font(.system(size: compact ? 8 : 9, weight: .medium))
            Text(String(format: "%+.2f", pnl))
                .font(.system(size: compact ? 12 : 13, weight: .medium))
                .monospacedDigit()
        }
        .foregroundStyle(pnl >= 0 ? LiquidGlassTheme.profitGreen : LiquidGlassTheme.lossRed)
    }
}

struct StatPill: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(LiquidGlassTheme.textTertiary)
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .liquidGlass(cornerRadius: 14, opacity: 0.05, borderOpacity: 0.1)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(LiquidGlassTheme.textTertiary)

            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(LiquidGlassTheme.textPrimary)

            Text(subtitle)
                .font(.system(size: 13))
                .foregroundStyle(LiquidGlassTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .padding(40)
    }
}
