import SwiftUI

struct FloatingTabBar: View {
    @Binding var selectedTab: MainTab
    @Namespace private var tabAnimation

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .liquidGlass(cornerRadius: 28, opacity: 0.15)
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }

    private func tabButton(for tab: MainTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if selectedTab == tab {
                        Capsule()
                            .fill(LiquidGlassTheme.accentCyan.opacity(0.2))
                            .matchedGeometryEffect(id: "tab_bg", in: tabAnimation)
                            .frame(width: 52, height: 32)
                    }

                    Image(systemName: tab.icon)
                        .font(.system(size: 18, weight: selectedTab == tab ? .semibold : .regular))
                        .foregroundStyle(selectedTab == tab ? LiquidGlassTheme.accentCyan : .white.opacity(0.45))
                        .symbolEffect(.bounce, value: selectedTab == tab)
                }
                .frame(height: 32)

                Text(tab.title)
                    .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .regular))
                    .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
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
        case .dashboard: return "chart.pie.fill"
        case .trades: return "list.bullet.rectangle.fill"
        case .add: return "plus.circle.fill"
        case .notifications: return "bell.fill"
        case .profile: return "person.fill"
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
                        withAnimation { selectedTab = .trades }
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
        .overlay(alignment: .topTrailing) {
            if notificationManager.unreadCount > 0 && selectedTab != .notifications {
                Text("\(notificationManager.unreadCount)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 18, height: 18)
                    .background(LiquidGlassTheme.lossRed)
                    .clipShape(Circle())
                    .offset(x: -36, y: 8)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
}
