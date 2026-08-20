import SwiftUI

struct TradeListView: View {
    @EnvironmentObject private var tradeStore: TradeStore
    @State private var filterType: TradeType? = nil
    @State private var showClosedOnly = false
    @State private var searchText = ""

    private var filteredTrades: [TradeRecord] {
        var result = tradeStore.trades
        if let type = filterType {
            result = result.filter { $0.tradeType == type }
        }
        if showClosedOnly {
            result = result.filter { $0.isClosed }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.cryptoSymbol.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            if tradeStore.trades.isEmpty {
                Spacer()
                EmptyStateView(
                    icon: "doc.text",
                    title: "还没有交易记录",
                    subtitle: "记录现货与合约交易，追踪每一笔盈亏"
                )
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(Array(filteredTrades.enumerated()), id: \.element.id) { index, trade in
                            TradeDetailCard(trade: trade)
                                .staggeredAppear(index: index)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 110)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("交易记录")
                    .font(.system(size: 26, weight: .semibold))
                    .tracking(-0.4)
                    .foregroundStyle(LiquidGlassTheme.textPrimary)
                Spacer()
                Text("\(filteredTrades.count)")
                    .font(.system(size: 14, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(LiquidGlassTheme.textTertiary)
            }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13))
                    .foregroundStyle(LiquidGlassTheme.textTertiary)
                TextField("搜索币种", text: $searchText)
                    .font(.system(size: 14))
                    .foregroundStyle(LiquidGlassTheme.textPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .liquidGlass(cornerRadius: 12, opacity: 0.05, borderOpacity: 0.1)

            HStack(spacing: 16) {
                filterItem("全部", type: nil)
                filterItem("现货", type: .spot)
                filterItem("合约", type: .futures)

                Spacer()

                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showClosedOnly.toggle()
                    }
                } label: {
                    Text(showClosedOnly ? "已平仓" : "全部状态")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(
                            showClosedOnly
                                ? LiquidGlassTheme.textPrimary
                                : LiquidGlassTheme.textTertiary
                        )
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    private func filterItem(_ title: String, type: TradeType?) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) {
                filterType = type
            }
        } label: {
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 13, weight: filterType == type ? .medium : .regular))
                    .foregroundStyle(
                        filterType == type
                            ? LiquidGlassTheme.textPrimary
                            : LiquidGlassTheme.textTertiary
                    )
                Rectangle()
                    .fill(filterType == type ? LiquidGlassTheme.textPrimary.opacity(0.7) : Color.clear)
                    .frame(width: 14, height: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct TradeDetailCard: View {
    let trade: TradeRecord
    @EnvironmentObject private var tradeStore: TradeStore
    @EnvironmentObject private var notificationManager: NotificationManager

    @State private var showCloseSheet = false
    @State private var exitPriceText = ""
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 14) {
                    CryptoIconView(symbol: trade.cryptoSymbol, size: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(trade.cryptoSymbol.uppercased())
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(LiquidGlassTheme.textPrimary)

                            Text(trade.tradeType.rawValue)
                                .font(.system(size: 11))
                                .foregroundStyle(LiquidGlassTheme.textTertiary)
                        }

                        Text(formatDate(trade.createdAt))
                            .font(.system(size: 11))
                            .foregroundStyle(LiquidGlassTheme.textTertiary)
                    }

                    Spacer()

                    if let pnl = trade.pnl {
                        PnLBadge(pnl: pnl)
                    } else {
                        Text("持仓")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(LiquidGlassTheme.accentSoft)
                    }

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(LiquidGlassTheme.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(14)
            }
            .buttonStyle(PressableButtonStyle())

            if isExpanded {
                VStack(spacing: 10) {
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 0.5)

                    detailRow("入场价格", String(format: "%.4f USDT", trade.entryPrice))
                    if let exit = trade.exitPrice {
                        detailRow("出场价格", String(format: "%.4f USDT", exit))
                    }
                    detailRow("数量", String(format: "%.6f", trade.quantity))
                    if trade.tradeType == .futures, let lev = trade.leverage {
                        detailRow("杠杆", "\(lev)x")
                    }
                    if trade.fee > 0 {
                        detailRow("手续费", String(format: "%.4f USDT", trade.fee))
                    }
                    if !trade.note.isEmpty {
                        detailRow("备注", trade.note)
                    }

                    HStack(spacing: 10) {
                        if !trade.isClosed {
                            Button {
                                showCloseSheet = true
                            } label: {
                                Text("平仓")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(LiquidGlassTheme.profitGreen)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                                    .liquidGlass(cornerRadius: 10, opacity: 0.05, borderOpacity: 0.1)
                            }
                            .buttonStyle(PressableButtonStyle())
                        }

                        Button(role: .destructive) {
                            withAnimation {
                                tradeStore.deleteTrade(trade)
                            }
                        } label: {
                            Text("删除")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(LiquidGlassTheme.lossRed)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .liquidGlass(cornerRadius: 10, opacity: 0.05, borderOpacity: 0.1)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .transition(.opacity)
            }
        }
        .liquidGlass(cornerRadius: 16, opacity: 0.05, borderOpacity: 0.1)
        .sheet(isPresented: $showCloseSheet) {
            closeTradeSheet
        }
    }

    private var closeTradeSheet: some View {
        NavigationStack {
            ZStack {
                LiquidBackground()
                VStack(spacing: 24) {
                    CryptoIconView(symbol: trade.cryptoSymbol, size: 56)

                    Text("平仓 \(trade.cryptoSymbol.uppercased())")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(LiquidGlassTheme.textPrimary)

                    GlassTextField(
                        placeholder: "出场价格 (USDT)",
                        text: $exitPriceText,
                        icon: "dollarsign",
                        keyboardType: .decimalPad
                    )

                    Button {
                        guard let price = Double(exitPriceText), price > 0 else { return }
                        var closed = trade
                        closed.exitPrice = price
                        closed.closedAt = Date()
                        tradeStore.closeTrade(trade, exitPrice: price)
                        if let pnl = closed.pnl {
                            notificationManager.notifyPnLAlert(symbol: trade.cryptoSymbol, pnl: pnl)
                        }
                        showCloseSheet = false
                    } label: {
                        Text("确认平仓")
                            .glassButtonStyle(isEnabled: Double(exitPriceText) != nil)
                    }
                    .buttonStyle(PressableButtonStyle())

                    Spacer()
                }
                .padding(24)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(LiquidGlassTheme.textTertiary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(LiquidGlassTheme.textSecondary)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy/MM/dd HH:mm"
        return f.string(from: date)
    }
}
