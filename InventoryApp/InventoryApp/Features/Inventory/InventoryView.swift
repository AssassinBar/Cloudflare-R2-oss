import SwiftUI

struct InventoryView: View {
    @State private var viewModel = InventoryViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        if let error = viewModel.errorMessage {
                            ErrorBanner(message: error) {
                                Task { await viewModel.load() }
                            }
                        }

                        if let summary = viewModel.summary {
                            summaryHeader(summary)
                            summaryMetrics(summary)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "库存流水")
                                .appearAnimation(index: 4)

                            if viewModel.movements.isEmpty && !viewModel.isLoading {
                                EmptyStateView(
                                    icon: "arrow.left.arrow.right",
                                    title: "暂无流水",
                                    message: "出入库记录将在此按时间展示"
                                )
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(Array(viewModel.movements.enumerated()), id: \.element.id) { index, item in
                                        movementRow(item)
                                        if index < viewModel.movements.count - 1 {
                                            Divider().overlay(AppTheme.separator)
                                        }
                                    }
                                }
                                .surfaceCard()
                                .appearAnimation(index: 5)
                            }
                        }
                    }
                    .padding(AppTheme.pagePadding)
                }
                .refreshable { await viewModel.load() }

                if viewModel.isLoading && viewModel.summary == nil {
                    LoadingOverlay()
                }
            }
            .navigationTitle("库存")
            .task { await viewModel.load() }
        }
    }

    private func summaryHeader(_ summary: InventorySummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("库存总览")
                .font(AppTheme.caption())
                .foregroundStyle(AppTheme.textSecondary)
            Text(Formatters.money(summary.totalValue))
                .font(AppTheme.display(32))
                .foregroundStyle(AppTheme.textPrimary)
                .contentTransition(.numericText())
            Text("覆盖 \(summary.skuCount) 个 SKU · \(summary.totalUnits) 件在库")
                .font(AppTheme.body(14))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appearAnimation(index: 0)
    }

    private func summaryMetrics(_ summary: InventorySummary) -> some View {
        HStack(spacing: 12) {
            MetricPill(
                title: "SKU 数量",
                value: "\(summary.skuCount)",
                icon: "square.grid.2x2",
                tint: AppTheme.accent
            )
            .appearAnimation(index: 1)

            MetricPill(
                title: "低库存",
                value: "\(summary.lowStockCount)",
                icon: "exclamationmark.circle",
                tint: summary.lowStockCount > 0 ? AppTheme.danger : AppTheme.success
            )
            .appearAnimation(index: 2)
        }
    }

    private func movementRow(_ item: StockMovement) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color(for: item.type).opacity(0.12))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: icon(for: item.type))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(color(for: item.type))
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.productName)
                    .font(AppTheme.body(14).weight(.medium))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                Text("\(item.type.title) · 结余 \(item.balanceAfter)")
                    .font(AppTheme.caption(12))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(signedQuantity(item))
                    .font(AppTheme.mono(14))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(Formatters.compactDate.string(from: item.createdAt))
                    .font(AppTheme.caption(11))
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
        .padding(.vertical, 10)
    }

    private func signedQuantity(_ item: StockMovement) -> String {
        switch item.type {
        case .inbound:
            return "+\(item.quantity)"
        case .outbound:
            return "-\(abs(item.quantity))"
        case .adjust:
            return item.quantity >= 0 ? "+\(item.quantity)" : "\(item.quantity)"
        }
    }

    private func icon(for type: StockMovementType) -> String {
        switch type {
        case .inbound: return "arrow.down.to.line"
        case .outbound: return "arrow.up.to.line"
        case .adjust: return "slider.horizontal.3"
        }
    }

    private func color(for type: StockMovementType) -> Color {
        switch type {
        case .inbound: return AppTheme.success
        case .outbound: return AppTheme.accent
        case .adjust: return AppTheme.warning
        }
    }
}
