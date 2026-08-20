import SwiftUI

struct FloatingTabBar: View {
    @Binding var selectedTab: MainTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 10)
        .liquidGlass(cornerRadius: 24, opacity: 0.1, borderOpacity: 0.12)
        .padding(.horizontal, 20)
        .padding(.bottom, 6)
    }

    private func tabButton(for tab: MainTab) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.22)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 5) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18, weight: selectedTab == tab ? .medium : .regular))
                    .foregroundStyle(
                        selectedTab == tab
                            ? LiquidGlassTheme.textPrimary
                            : LiquidGlassTheme.textTertiary
                    )

                Text(tab.title)
                    .font(.system(size: 10, weight: selectedTab == tab ? .medium : .regular))
                    .foregroundStyle(
                        selectedTab == tab
                            ? LiquidGlassTheme.textSecondary
                            : LiquidGlassTheme.textTertiary
                    )
            }
            .frame(maxWidth: .infinity)
            .opacity(selectedTab == tab ? 1 : 0.7)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

enum MainTab: String, CaseIterable, Identifiable {
    case dashboard
    case trades
    case add
    case notifications
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "概览"
        case .trades: return "记录"
        case .add: return "添加"
        case .notifications: return "通知"
        case .profile: return "我的"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .trades: return "list.bullet"
        case .add: return "plus"
        case .notifications: return "bell"
        case .profile: return "person"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: MainTab = .dashboard
    @EnvironmentObject private var notificationManager: NotificationManager

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView()
                case .trades:
                    TradeListView()
                case .add:
                    AddTradeView(onComplete: {
                        withAnimation(.easeOut(duration: 0.25)) { selectedTab = .trades }
                    })
                case .notifications:
                    NotificationsView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            FloatingTabBar(selectedTab: $selectedTab)
        }
    }
}
