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
                        ProgressView()
                            .scaleEffect(0.6)
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
                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
    }

    private var fallbackIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [LiquidGlassTheme.accentPurple.opacity(0.6), LiquidGlassTheme.accentCyan.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(String(symbol.prefix(1)).uppercased())
                .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}

struct AnimatedNumber: View {
    let value: Double
    var prefix: String = ""
    var suffix: String = ""
    var decimals: Int = 2
    var color: Color = .white

    @State private var displayValue: Double = 0

    var body: some View {
        Text(formatted(displayValue))
            .font(.system(.title, design: .rounded, weight: .bold))
            .foregroundStyle(color)
            .contentTransition(.numericText(value: displayValue))
            .onAppear {
                animateToValue()
            }
            .onChange(of: value) { _, _ in
                animateToValue()
            }
    }

    private func animateToValue() {
        withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
            displayValue = value
        }
    }

    private func formatted(_ val: Double) -> String {
        let sign = val >= 0 && prefix.isEmpty ? (val > 0 ? "+" : "") : ""
        return "\(sign)\(prefix)\(String(format: "%.\(decimals)f", val))\(suffix)"
    }
}

struct PnLBadge: View {
    let pnl: Double
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: pnl >= 0 ? "arrow.up.right" : "arrow.down.right")
                .font(compact ? .caption2 : .caption)
            Text(String(format: "%+.2f", pnl))
                .font(compact ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
        }
        .foregroundStyle(pnl >= 0 ? LiquidGlassTheme.profitGreen : LiquidGlassTheme.lossRed)
        .padding(.horizontal, compact ? 8 : 12)
        .padding(.vertical, compact ? 4 : 6)
        .background {
            Capsule()
                .fill((pnl >= 0 ? LiquidGlassTheme.profitGreen : LiquidGlassTheme.lossRed).opacity(0.15))
        }
    }
}

struct StatPill: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .liquidGlass(cornerRadius: 14, opacity: 0.08)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    @State private var float = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [LiquidGlassTheme.accentCyan, LiquidGlassTheme.accentPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .offset(y: float ? -6 : 6)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: float)

            Text(title)
                .font(.headline)
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .onAppear { float = true }
    }
}
