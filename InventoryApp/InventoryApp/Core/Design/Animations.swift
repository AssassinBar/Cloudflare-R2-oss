import SwiftUI

enum AppAnimation {
    static let spring = Animation.spring(response: 0.45, dampingFraction: 0.82)
    static let softSpring = Animation.spring(response: 0.55, dampingFraction: 0.88)
    static let snappy = Animation.spring(response: 0.32, dampingFraction: 0.78)
    static let fade = Animation.easeInOut(duration: 0.28)
}

struct AppearAnimation: ViewModifier {
    let index: Int
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 14)
            .scaleEffect(shown ? 1 : 0.98)
            .onAppear {
                withAnimation(AppAnimation.softSpring.delay(Double(index) * 0.05)) {
                    shown = true
                }
            }
    }
}

extension View {
    func appearAnimation(index: Int = 0) -> some View {
        modifier(AppearAnimation(index: index))
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(AppAnimation.snappy, value: configuration.isPressed)
    }
}
