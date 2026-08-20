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
                    .transition(.opacity)
            } else if authService.isAuthenticated {
                MainTabView()
                    .transition(.opacity)
            } else {
                AuthContainerView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.55), value: showSplash)
        .animation(.easeInOut(duration: 0.45), value: authService.isAuthenticated)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeInOut(duration: 0.55)) {
                    showSplash = false
                }
            }
        }
    }
}

struct SplashView: View {
    @State private var opacity: Double = 0
    @State private var markScale: CGFloat = 0.92

    var body: some View {
        VStack(spacing: 32) {
            GlassOrb(size: 88)
                .scaleEffect(markScale)

            VStack(spacing: 10) {
                Text("CryptoLedger")
                    .font(.system(size: 32, weight: .semibold))
                    .tracking(-0.5)
                    .foregroundStyle(LiquidGlassTheme.textPrimary)

                Text("合约 · 现货 · 盈亏")
                    .font(.system(size: 14, weight: .regular))
                    .tracking(1.5)
                    .foregroundStyle(LiquidGlassTheme.textSecondary)
            }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.9)) {
                opacity = 1
                markScale = 1
            }
        }
    }
}
