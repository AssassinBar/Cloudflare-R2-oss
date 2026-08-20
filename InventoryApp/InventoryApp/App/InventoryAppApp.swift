import SwiftUI

@main
struct InventoryAppApp: App {
    var body: some Scene {
        WindowGroup {
            LaunchGateView()
        }
    }
}

/// Soft launch transition into the main tab shell.
struct LaunchGateView: View {
    @State private var ready = false
    @State private var logoScale: CGFloat = 0.92
    @State private var logoOpacity: Double = 0

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if ready {
                RootTabView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                VStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(AppTheme.surface)
                        .frame(width: 84, height: 84)
                        .softShadow()
                        .overlay {
                            Image(systemName: "cube.transparent")
                                .font(.system(size: 34, weight: .light))
                                .foregroundStyle(AppTheme.accent)
                        }
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)

                    Text("库存通")
                        .font(AppTheme.title(24))
                        .foregroundStyle(AppTheme.textPrimary)
                        .opacity(logoOpacity)

                    Text("进销存")
                        .font(AppTheme.caption())
                        .foregroundStyle(AppTheme.textSecondary)
                        .opacity(logoOpacity)
                }
            }
        }
        .task {
            withAnimation(AppAnimation.softSpring) {
                logoOpacity = 1
                logoScale = 1
            }
            try? await Task.sleep(nanoseconds: 900_000_000)
            withAnimation(AppAnimation.softSpring) {
                ready = true
            }
        }
    }
}
