import SwiftUI

// MARK: - Liquid Glass Effect (iOS 26+ with fallback)

struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = LiquidGlassTheme.cardCornerRadius
    var opacity: Double = 0.12
    var borderOpacity: Double = 0.25

    func body(content: Content) -> some View {
        content
            .background {
                glassBackground
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(borderOpacity + 0.15),
                                Color.white.opacity(borderOpacity * 0.4),
                                Color.white.opacity(borderOpacity * 0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            }
            .shadow(color: LiquidGlassTheme.glassShadow, radius: 16, y: 8)
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
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(opacity + 0.06),
                                    Color.white.opacity(opacity * 0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
        }
    }
}

extension View {
    func liquidGlass(
        cornerRadius: CGFloat = LiquidGlassTheme.cardCornerRadius,
        opacity: Double = 0.12,
        borderOpacity: Double = 0.25
    ) -> some View {
        modifier(LiquidGlassModifier(
            cornerRadius: cornerRadius,
            opacity: opacity,
            borderOpacity: borderOpacity
        ))
    }

    func glassButtonStyle(isEnabled: Bool = true) -> some View {
        self
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .liquidGlass(cornerRadius: LiquidGlassTheme.buttonCornerRadius, opacity: isEnabled ? 0.18 : 0.08)
            .opacity(isEnabled ? 1 : 0.5)
    }
}

// MARK: - Shimmer Animation

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.25), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.4)
                    .offset(x: phase * geo.size.width * 1.4 - geo.size.width * 0.4)
                    .mask(content)
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Press Animation

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Staggered Appear

struct StaggeredAppearModifier: ViewModifier {
    let index: Int
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 24)
            .scaleEffect(appeared ? 1 : 0.95)
            .onAppear {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.78).delay(Double(index) * 0.08)) {
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
