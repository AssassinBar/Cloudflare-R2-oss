import SwiftUI

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @State private var heroAppeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        heroHeader
                            .appearAnimation(index: 0)

                        if let error = viewModel.errorMessage {
                            ErrorBanner(message: error) {
                                Task { await viewModel.load() }
                            }
                            .appearAnimation(index: 1)
                        }

                        if let snapshot = viewModel.snapshot {
                            metricsGrid(snapshot)
                            lowStockSection(snapshot)
                            recentActivity(snapshot)
                        } else if !viewModel.isLoading {
                            EmptyStateView(
                                icon: "chart.bar.doc.horizontal",
                                title: "暂无数据",
                                message: "连接接口后，这里会展示经营概览"
                            )
                        }
                    }
                    .padding(.horizontal, AppTheme.pagePadding)
                    .padding(.bottom, 32)
                    .padding(.top, 8)
                }
                .refreshable { await viewModel.load() }

                if viewModel.isLoading && viewModel.snapshot == nil {
                    LoadingOverlay()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("库存通")
                        .font(AppTheme.title(17))
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
            .task { await viewModel.load() }
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今日概览")
                .font(AppTheme.caption())
                .foregroundStyle(AppTheme.textSecondary)
                .opacity(heroAppeared ? 1 : 0)

            Text("经营一目了然")
                .font(AppTheme.display(30))
                .foregroundStyle(AppTheme.textPrimary)
                .offset(y: heroAppeared ? 0 : 10)
                .opacity(heroAppeared ? 1 : 0)

            Text("进货、销售与库存动态，随时掌握。")
                .font(AppTheme.body(15))
                .foregroundStyle(AppTheme.textSecondary)
                .opacity(heroAppeared ? 1 : 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
        .onAppear {
            withAnimation(AppAnimation.softSpring) {
                heroAppeared = true
            }
        }
    }

    private func metricsGrid(_ snapshot: DashboardSnapshot) -> some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            MetricPill(
                title: "今日销售额",
                value: Formatters.money(snapshot.todaySalesAmount),
                icon: "arrow.up.right",
                tint: AppTheme.success
            )
            .appearAnimation(index: 1)

            MetricPill(
                title: "今日进货额",
                value: Formatters.money(snapshot.todayPurchaseAmount),
                icon: "shippingbox",
                tint: AppTheme.accent
            )
            .appearAnimation(index: 2)

            MetricPill(
                title: "库存总值",
                value: Formatters.money(snapshot.inventory.totalValue),
                icon: "cube.box",
                tint: AppTheme.textPrimary
            )
            .appearAnimation(index: 3)

            MetricPill(
                title: "待处理单据",
                value: "\(snapshot.pendingOrders)",
                icon: "clock",
                tint: AppTheme.warning
            )
            .appearAnimation(index: 4)
        }
    }

    private func lowStockSection(_ snapshot: DashboardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "库存预警")
                .appearAnimation(index: 5)

            if snapshot.lowStockProducts.isEmpty {
                Text("暂无低库存商品")
                    .font(AppTheme.body(14))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(snapshot.lowStockProducts.enumerated()), id: \.element.id) { index, product in
                    NavigationLink {
                        ProductDetailView(product: product)
                    } label: {
                        HStack(spacing: 14) {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(AppTheme.danger.opacity(0.1))
                                .frame(width: 44, height: 44)
                                .overlay {
                                    Image(systemName: "exclamationmark")
                                        .foregroundStyle(AppTheme.danger)
                                        .fontWeight(.semibold)
                                }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(product.name)
                                    .font(AppTheme.body(15).weight(.medium))
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .lineLimit(1)
                                Text("剩余 \(product.stockQuantity) \(product.unit) · 阈值 \(product.lowStockThreshold)")
                                    .font(AppTheme.caption(12))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }

                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                        .surfaceCard(padding: 14)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .appearAnimation(index: 6 + index)
                }
            }
        }
    }

    private func recentActivity(_ snapshot: DashboardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "最近动态")
                .appearAnimation(index: 8)

            VStack(spacing: 0) {
                ForEach(Array(snapshot.recentMovements.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(movementColor(item.type).opacity(0.14))
                            .frame(width: 36, height: 36)
                            .overlay {
                                Image(systemName: movementIcon(item.type))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(movementColor(item.type))
                            }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.productName)
                                .font(AppTheme.body(14).weight(.medium))
                                .foregroundStyle(AppTheme.textPrimary)
                                .lineLimit(1)
                            Text("\(item.type.title) · \(Formatters.compactDate.string(from: item.createdAt))")
                                .font(AppTheme.caption(12))
                                .foregroundStyle(AppTheme.textSecondary)
                        }

                        Spacer()

                        Text("\(item.quantity > 0 && item.type != .outbound ? "+" : "")\(item.type == .outbound ? -abs(item.quantity) : item.quantity)")
                            .font(AppTheme.mono(14))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    .padding(.vertical, 12)

                    if index < snapshot.recentMovements.count - 1 {
                        Divider().overlay(AppTheme.separator)
                    }
                }
            }
            .surfaceCard()
            .appearAnimation(index: 9)
        }
    }

    private func movementIcon(_ type: StockMovementType) -> String {
        switch type {
        case .inbound: return "arrow.down"
        case .outbound: return "arrow.up"
        case .adjust: return "slider.horizontal.3"
        }
    }

    private func movementColor(_ type: StockMovementType) -> Color {
        switch type {
        case .inbound: return AppTheme.success
        case .outbound: return AppTheme.accent
        case .adjust: return AppTheme.warning
        }
    }
}
