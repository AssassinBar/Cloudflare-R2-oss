import SwiftUI

// MARK: - Liquid Glass Effect (iOS 26+ with fallback)

struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = LiquidGlassTheme.cardCornerRadius
    var opacity: Double = 0.08
    var borderOpacity: Double = 0.14

    func body(content: Content) -> some View {
        content
            .background { glassBackground }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(borderOpacity), lineWidth: 0.5)
            }
            .shadow(color: LiquidGlassTheme.glassShadow, radius: 10, y: 4)
    }

    @ViewBuilder
    private var glassBackground: some View {
        if #available(iOS 26.0, *) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.clear)
                .glassEffect(.regular.tint(Color.white.opacity(opacity)).interactive())
        } else {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.white.opacity(opacity * 0.5))
                }
        }
    }
}

extension View {
    func liquidGlass(
        cornerRadius: CGFloat = LiquidGlassTheme.cardCornerRadius,
        opacity: Double = 0.08,
        borderOpacity: Double = 0.14
    ) -> some View {
        modifier(LiquidGlassModifier(
            cornerRadius: cornerRadius,
            opacity: opacity,
            borderOpacity: borderOpacity
        ))
    }

    func glassButtonStyle(isEnabled: Bool = true) -> some View {
        self
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(LiquidGlassTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background {
                RoundedRectangle(cornerRadius: LiquidGlassTheme.buttonCornerRadius, style: .continuous)
                    .fill(Color.white.opacity(isEnabled ? 0.12 : 0.05))
            }
            .overlay {
                RoundedRectangle(cornerRadius: LiquidGlassTheme.buttonCornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(isEnabled ? 0.18 : 0.08), lineWidth: 0.5)
            }
            .opacity(isEnabled ? 1 : 0.45)
    }
}

// MARK: - Press Animation

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Staggered Appear (subtle)

struct StaggeredAppearModifier: ViewModifier {
    let index: Int
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
            .onAppear {
                withAnimation(.easeOut(duration: 0.45).delay(Double(index) * 0.05)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func staggeredAppear(index: Int) -> some View {
        modifier(StaggeredAppearModifier(index: index))
    }
}
