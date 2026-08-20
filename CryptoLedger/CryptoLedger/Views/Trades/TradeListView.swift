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
                    icon: "doc.text.magnifyingglass",
                    title: "还没有交易记录",
                    subtitle: "记录您的现货和合约交易，追踪每一笔盈亏"
                )
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(filteredTrades.enumerated()), id: \.element.id) { index, trade in
                            TradeDetailCard(trade: trade)
                                .staggeredAppear(index: index)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            HStack {
                Text("交易记录")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(filteredTrades.count) 笔")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.4))
            }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.white.opacity(0.4))
                TextField("搜索币种...", text: $searchText)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .liquidGlass(cornerRadius: 14, opacity: 0.08)

            HStack(spacing: 10) {
                filterChip("全部", type: nil)
                filterChip("现货", type: .spot)
                filterChip("合约", type: .futures)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showClosedOnly.toggle()
                    }
                } label: {
                    Image(systemName: showClosedOnly ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(showClosedOnly ? LiquidGlassTheme.accentCyan : .white.opacity(0.3))
                    Text("已平仓")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private func filterChip(_ title: String, type: TradeType?) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                filterType = type
            }
        } label: {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(filterType == type ? .white : .white.opacity(0.4))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background {
                    Capsule().fill(
                        filterType == type
                            ? LiquidGlassTheme.accentPurple.opacity(0.3)
                            : Color.white.opacity(0.06)
                    )
                }
        }
        .buttonStyle(PressableButtonStyle())
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
                withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 14) {
                    CryptoIconView(symbol: trade.cryptoSymbol, size: 44)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(trade.cryptoSymbol.uppercased())
                                .font(.headline)
                                .foregroundStyle(.white)

                            Label(trade.tradeType.rawValue, systemImage: trade.tradeType.icon)
                                .font(.caption2)
                                .foregroundStyle(LiquidGlassTheme.accentCyan)
                        }

                        Text(formatDate(trade.createdAt))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    }

                    Spacer()

                    if let pnl = trade.pnl {
                        PnLBadge(pnl: pnl)
                    } else {
                        Text("持仓")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(LiquidGlassTheme.accentGold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(LiquidGlassTheme.accentGold.opacity(0.15)))
                    }

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(16)
            }
            .buttonStyle(PressableButtonStyle())

            if isExpanded {
                VStack(spacing: 12) {
                    Divider().opacity(0.15)

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
                                Label("平仓", systemImage: "checkmark.circle")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(LiquidGlassTheme.profitGreen)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .liquidGlass(cornerRadius: 12, opacity: 0.1)
                            }
                            .buttonStyle(PressableButtonStyle())
                        }

                        Button(role: .destructive) {
                            withAnimation {
                                tradeStore.deleteTrade(trade)
                            }
                        } label: {
                            Label("删除", systemImage: "trash")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(LiquidGlassTheme.lossRed)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .liquidGlass(cornerRadius: 12, opacity: 0.1)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .liquidGlass(cornerRadius: 18, opacity: 0.08)
        .sheet(isPresented: $showCloseSheet) {
            closeTradeSheet
        }
    }

    private var closeTradeSheet: some View {
        NavigationStack {
            ZStack {
                LiquidBackground()
                VStack(spacing: 20) {
                    CryptoIconView(symbol: trade.cryptoSymbol, size: 60)

                    Text("平仓 \(trade.cryptoSymbol.uppercased())")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)

                    GlassTextField(
                        placeholder: "出场价格 (USDT)",
                        text: $exitPriceText,
                        icon: "dollarsign.circle",
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
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
            Spacer()
            Text(value)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy/MM/dd HH:mm"
        return f.string(from: date)
    }
}
