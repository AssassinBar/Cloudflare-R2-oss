import SwiftUI

struct PurchasesView: View {
    @State private var viewModel = PurchasesViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                Group {
                    if let error = viewModel.errorMessage, viewModel.orders.isEmpty {
                        VStack {
                            ErrorBanner(message: error) {
                                Task { await viewModel.load() }
                            }
                            .padding(AppTheme.pagePadding)
                            Spacer()
                        }
                    } else if viewModel.orders.isEmpty && !viewModel.isLoading {
                        EmptyStateView(
                            icon: "shippingbox",
                            title: "暂无进货单",
                            message: "对接进货接口后，采购单据会显示在这里"
                        )
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(viewModel.orders.enumerated()), id: \.element.id) { index, order in
                                    NavigationLink {
                                        PurchaseDetailView(order: order)
                                    } label: {
                                        PurchaseRow(order: order)
                                    }
                                    .buttonStyle(PressableButtonStyle())
                                    .appearAnimation(index: index)
                                }
                            }
                            .padding(AppTheme.pagePadding)
                        }
                        .refreshable { await viewModel.load() }
                    }
                }

                if viewModel.isLoading && viewModel.orders.isEmpty {
                    LoadingOverlay()
                }
            }
            .navigationTitle("进货")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {} label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                    .opacity(0.35)
                    .disabled(true)
                }
            }
            .task { await viewModel.load() }
        }
    }
}

struct PurchaseRow: View {
    let order: PurchaseOrder

    var body: some View {
        ListRowCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(order.number)
                        .font(AppTheme.mono(13))
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    StatusChip(status: order.status)
                }

                Text(order.supplierName)
                    .font(AppTheme.body(16).weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                HStack {
                    Label("\(order.totalQuantity) 件", systemImage: "cube.box")
                    Spacer()
                    Text(Formatters.money(order.totalAmount))
                        .font(AppTheme.title(17))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .font(AppTheme.caption())
                .foregroundStyle(AppTheme.textSecondary)

                Text(Formatters.compactDate.string(from: order.createdAt))
                    .font(AppTheme.caption(12))
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
    }
}

struct PurchaseDetailView: View {
    let order: PurchaseOrder

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        StatusChip(status: order.status)
                        Text(order.number)
                            .font(AppTheme.display(26))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(order.supplierName)
                            .font(AppTheme.body(15))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .appearAnimation(index: 0)

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(order.lines.enumerated()), id: \.element.id) { index, line in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(line.productName)
                                        .font(AppTheme.body(15).weight(.medium))
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Text("\(line.quantity) × \(Formatters.money(line.unitPrice))")
                                        .font(AppTheme.caption())
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                Spacer()
                                Text(Formatters.money(line.lineTotal))
                                    .font(AppTheme.mono(14))
                                    .foregroundStyle(AppTheme.textPrimary)
                            }
                            .padding(.vertical, 12)
                            if index < order.lines.count - 1 {
                                Divider().overlay(AppTheme.separator)
                            }
                        }
                    }
                    .surfaceCard()
                    .appearAnimation(index: 1)

                    HStack {
                        Text("合计")
                            .font(AppTheme.body(15))
                            .foregroundStyle(AppTheme.textSecondary)
                        Spacer()
                        Text(Formatters.money(order.totalAmount))
                            .font(AppTheme.title(22))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    .surfaceCard()
                    .appearAnimation(index: 2)
                }
                .padding(AppTheme.pagePadding)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
