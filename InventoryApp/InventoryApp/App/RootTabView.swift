import SwiftUI
import UIKit

enum AppTab: Hashable {
    case dashboard
    case products
    case purchases
    case sales
    case more
}

struct RootTabView: View {
    @State private var selectedTab: AppTab = .dashboard
    @State private var morePath = NavigationPath()

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("概览", systemImage: "square.grid.2x2.fill")
                }
                .tag(AppTab.dashboard)

            ProductsView()
                .tabItem {
                    Label("商品", systemImage: "cube.box.fill")
                }
                .tag(AppTab.products)

            PurchasesView()
                .tabItem {
                    Label("进货", systemImage: "shippingbox.fill")
                }
                .tag(AppTab.purchases)

            SalesView()
                .tabItem {
                    Label("销售", systemImage: "cart.fill")
                }
                .tag(AppTab.sales)

            MoreHubView()
                .tabItem {
                    Label("更多", systemImage: "ellipsis.circle.fill")
                }
                .tag(AppTab.more)
        }
        .tint(AppTheme.accent)
        .onChange(of: selectedTab) { _, _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

struct MoreHubView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        NavigationLink {
                            InventoryView()
                        } label: {
                            moreRow(icon: "archivebox.fill", title: "库存流水", subtitle: "出入库与结余", tint: AppTheme.accent)
                        }
                        .buttonStyle(PressableButtonStyle())
                        .appearAnimation(index: 0)

                        NavigationLink {
                            PartnersView()
                        } label: {
                            moreRow(icon: "person.2.fill", title: "往来单位", subtitle: "供应商与客户", tint: AppTheme.success)
                        }
                        .buttonStyle(PressableButtonStyle())
                        .appearAnimation(index: 1)

                        NavigationLink {
                            SettingsView()
                        } label: {
                            moreRow(icon: "gearshape.fill", title: "设置与对接", subtitle: "API 环境切换", tint: AppTheme.textPrimary)
                        }
                        .buttonStyle(PressableButtonStyle())
                        .appearAnimation(index: 2)
                    }
                    .padding(AppTheme.pagePadding)
                }
            }
            .navigationTitle("更多")
        }
    }

    private func moreRow(icon: String, title: String, subtitle: String, tint: Color) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tint.opacity(0.12))
                .frame(width: 46, height: 46)
                .overlay {
                    Image(systemName: icon)
                        .foregroundStyle(tint)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.body(16).weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(subtitle)
                    .font(AppTheme.caption())
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textTertiary)
        }
        .surfaceCard()
    }
}
