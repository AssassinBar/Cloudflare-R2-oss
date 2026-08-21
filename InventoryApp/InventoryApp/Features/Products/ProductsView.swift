import SwiftUI

struct ProductsView: View {
    @State private var viewModel = ProductsViewModel()
    @State private var showCreatePlaceholder = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 16) {
                    SearchField(text: $viewModel.searchText, placeholder: "搜索商品名称、SKU、分类")
                        .padding(.horizontal, AppTheme.pagePadding)
                        .padding(.top, 8)
                        .appearAnimation(index: 0)
                        .onChange(of: viewModel.searchText) { _, _ in
                            Task { await viewModel.load() }
                        }

                    if let error = viewModel.errorMessage {
                        ErrorBanner(message: error) {
                            Task { await viewModel.load() }
                        }
                        .padding(.horizontal, AppTheme.pagePadding)
                    }

                    if viewModel.products.isEmpty && !viewModel.isLoading {
                        EmptyStateView(
                            icon: "cube",
                            title: "暂无商品",
                            message: "对接商品接口后，列表将在此展示"
                        )
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(viewModel.products.enumerated()), id: \.element.id) { index, product in
                                    NavigationLink {
                                        ProductDetailView(product: product)
                                    } label: {
                                        ProductRow(product: product)
                                    }
                                    .buttonStyle(PressableButtonStyle())
                                    .appearAnimation(index: index)
                                }
                            }
                            .padding(.horizontal, AppTheme.pagePadding)
                            .padding(.bottom, 28)
                        }
                        .refreshable { await viewModel.load() }
                    }
                }

                if viewModel.isLoading && viewModel.products.isEmpty {
                    LoadingOverlay()
                }
            }
            .navigationTitle("商品")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreatePlaceholder = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .alert("待对接", isPresented: $showCreatePlaceholder) {
                Button("好的", role: .cancel) {}
            } message: {
                Text("新建商品将在接入 API 后启用。当前为 UI 框架。")
            }
            .task { await viewModel.load() }
        }
    }
}

struct ProductRow: View {
    let product: Product

    var body: some View {
        ListRowCard {
            HStack(alignment: .top, spacing: 14) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.surfaceSecondary, AppTheme.accentSoft],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .overlay {
                        Text(String(product.name.prefix(1)))
                            .font(AppTheme.title(20))
                            .foregroundStyle(AppTheme.accent)
                    }

                VStack(alignment: .leading, spacing: 6) {
                    Text(product.name)
                        .font(AppTheme.body(16).weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)

                    Text("\(product.sku) · \(product.category)")
                        .font(AppTheme.caption(12))
                        .foregroundStyle(AppTheme.textSecondary)

                    HStack(spacing: 10) {
                        Text(Formatters.money(product.salePrice))
                            .font(AppTheme.mono(13))
                            .foregroundStyle(AppTheme.textPrimary)

                        Text("库存 \(product.stockQuantity)")
                            .font(AppTheme.caption(12))
                            .foregroundStyle(product.isLowStock ? AppTheme.danger : AppTheme.textSecondary)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textTertiary)
                    .padding(.top, 4)
            }
        }
    }
}

struct ProductDetailView: View {
    let product: Product
    @State private var appeared = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(product.category.uppercased())
                            .font(AppTheme.caption(12))
                            .foregroundStyle(AppTheme.accent)
                            .tracking(1)

                        Text(product.name)
                            .font(AppTheme.display(28))
                            .foregroundStyle(AppTheme.textPrimary)

                        Text(product.sku)
                            .font(AppTheme.mono(14))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)

                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 12
                    ) {
                        detailMetric("售价", Formatters.money(product.salePrice))
                        detailMetric("成本", Formatters.money(product.costPrice))
                        detailMetric("库存", "\(product.stockQuantity) \(product.unit)")
                        detailMetric("预警", "\(product.lowStockThreshold) \(product.unit)")
                    }
                    .appearAnimation(index: 1)

                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "基础信息")
                        infoRow("条码", product.barcode ?? "—")
                        infoRow("单位", product.unit)
                        infoRow("更新时间", Formatters.dayDate.string(from: product.updatedAt))
                        if let note = product.note {
                            infoRow("备注", note)
                        }
                    }
                    .surfaceCard()
                    .appearAnimation(index: 2)

                    PrimaryButton(title: "编辑商品", icon: "pencil") {}
                        .opacity(0.45)
                        .disabled(true)
                        .appearAnimation(index: 3)

                    Text("编辑能力将在接口对接后开放")
                        .font(AppTheme.caption())
                        .foregroundStyle(AppTheme.textTertiary)
                        .frame(maxWidth: .infinity)
                }
                .padding(AppTheme.pagePadding)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(AppAnimation.softSpring) { appeared = true }
        }
    }

    private func detailMetric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTheme.caption())
                .foregroundStyle(AppTheme.textSecondary)
            Text(value)
                .font(AppTheme.title(18))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceCard()
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(AppTheme.body(14))
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(AppTheme.body(14).weight(.medium))
                .foregroundStyle(AppTheme.textPrimary)
        }
    }
}
