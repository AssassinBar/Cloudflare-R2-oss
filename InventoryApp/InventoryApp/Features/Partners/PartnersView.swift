import SwiftUI

struct PartnersView: View {
    @State private var viewModel = PartnersViewModel()
    @State private var selectedSegment = 0

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 16) {
                    Picker("类型", selection: $selectedSegment) {
                        Text("全部").tag(0)
                        Text("供应商").tag(1)
                        Text("客户").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, AppTheme.pagePadding)
                    .padding(.top, 8)
                    .onChange(of: selectedSegment) { _, value in
                        switch value {
                        case 1: viewModel.filter = .supplier
                        case 2: viewModel.filter = .customer
                        default: viewModel.filter = nil
                        }
                        Task { await viewModel.load() }
                    }
                    .appearAnimation(index: 0)

                    if viewModel.partners.isEmpty && !viewModel.isLoading {
                        EmptyStateView(
                            icon: "person.2",
                            title: "暂无往来单位",
                            message: "供应商与客户资料对接后显示在此"
                        )
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(viewModel.partners.enumerated()), id: \.element.id) { index, partner in
                                    PartnerRow(partner: partner)
                                        .appearAnimation(index: index + 1)
                                }
                            }
                            .padding(.horizontal, AppTheme.pagePadding)
                            .padding(.bottom, 28)
                        }
                        .refreshable { await viewModel.load() }
                    }
                }

                if viewModel.isLoading && viewModel.partners.isEmpty {
                    LoadingOverlay()
                }
            }
            .navigationTitle("往来")
            .task { await viewModel.load() }
        }
    }
}

struct PartnerRow: View {
    let partner: Partner

    var body: some View {
        ListRowCard {
            HStack(spacing: 14) {
                Circle()
                    .fill(partner.type == .supplier ? AppTheme.accentSoft : AppTheme.success.opacity(0.12))
                    .frame(width: 46, height: 46)
                    .overlay {
                        Image(systemName: partner.type == .supplier ? "building.2" : "person")
                            .foregroundStyle(partner.type == .supplier ? AppTheme.accent : AppTheme.success)
                    }

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(partner.name)
                            .font(AppTheme.body(16).weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        Text(partner.type.title)
                            .font(AppTheme.caption(11))
                            .foregroundStyle(AppTheme.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.surfaceSecondary)
                            .clipShape(Capsule())
                    }

                    if let contact = partner.contact {
                        Text(contact)
                            .font(AppTheme.caption())
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    if let phone = partner.phone {
                        Text(phone)
                            .font(AppTheme.mono(12))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                }
            }
        }
    }
}
