import SwiftUI
import UserNotifications

@main
struct CryptoLedgerApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var tradeStore = TradeStore()
    @StateObject private var notificationManager = NotificationManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
                .environmentObject(tradeStore)
                .environmentObject(notificationManager)
                .preferredColorScheme(.dark)
                .onAppear {
                    notificationManager.requestAuthorization()
                }
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var authService: AuthService
    @State private var showSplash = true

    var body: some View {
        ZStack {
            LiquidBackground()

            if showSplash {
                SplashView()
                    .transition(.opacity.combined(with: .scale(scale: 1.1)))
            } else if authService.isAuthenticated {
                MainTabView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
            } else {
                AuthContainerView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .animation(.spring(response: 0.7, dampingFraction: 0.82), value: showSplash)
        .animation(.spring(response: 0.65, dampingFraction: 0.85), value: authService.isAuthenticated)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.78)) {
                    showSplash = false
                }
            }
        }
    }
}

struct SplashView: View {
    @State private var orbScale: CGFloat = 0.6
    @State private var orbRotation: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                LiquidGlassTheme.accentCyan.opacity(0.45),
                                LiquidGlassTheme.accentPurple.opacity(0.2),
                                .clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 120
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)
                    .scaleEffect(orbScale)

                GlassOrb(size: 100)
                    .scaleEffect(orbScale)
                    .rotation3DEffect(.degrees(orbRotation), axis: (x: 0.3, y: 1, z: 0.2))
            }

            VStack(spacing: 8) {
                Text("CryptoLedger")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, LiquidGlassTheme.accentCyan.opacity(0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .white.opacity(0.6), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 80)
                            .offset(x: shimmerOffset)
                            .mask(
                                Text("CryptoLedger")
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                            )
                    }

                Text("合约 · 现货 · 盈亏追踪")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.55))
            }
            .opacity(titleOpacity)
        }
        .onAppear {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.65)) {
                orbScale = 1.0
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: false)) {
                orbRotation = 360
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
                titleOpacity = 1
            }
            withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false).delay(0.6)) {
                shimmerOffset = 200
            }
        }
    }
}
