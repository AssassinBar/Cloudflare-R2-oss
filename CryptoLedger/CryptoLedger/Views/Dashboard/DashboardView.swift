import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var tradeStore: TradeStore
    @EnvironmentObject private var authService: AuthService

    @State private var selectedSegment: TradeType? = nil
    @State private var headerScale: CGFloat = 0.95

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                headerSection
                    .scaleEffect(headerScale)
                    .onAppear {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                            headerScale = 1.0
                        }
                    }

                totalPnLCard
                    .staggeredAppear(index: 1)

                statsRow
                    .staggeredAppear(index: 2)

                typeFilter
                    .staggeredAppear(index: 3)

                PnLChartView(trades: filteredTrades)
                    .staggeredAppear(index: 4)

                recentTradesSection
                    .staggeredAppear(index: 5)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("你好，\(authService.displayName)")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.45))
            }
            Spacer()
            CryptoIconView(symbol: "BTC", size: 44)
                .liquidGlass(cornerRadius: 22, opacity: 0.1)
        }
    }

    private var totalPnLCard: some View {
        GlassCard {
            VStack(spacing: 12) {
                Text("总盈亏")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))

                AnimatedNumber(
                    value: tradeStore.summary.totalPnL,
                    suffix: " USDT",
                    color: tradeStore.summary.totalPnL >= 0
                        ? LiquidGlassTheme.profitGreen
                        : LiquidGlassTheme.lossRed
                )

                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("胜率")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                        Text(String(format: "%.1f%%", tradeStore.summary.winRate))
                            .font(.headline)
                            .foregroundStyle(LiquidGlassTheme.accentGold)
                    }

                    Divider().frame(height: 30).opacity(0.2)

                    VStack(spacing: 4) {
                        Text("总交易")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                        Text("\(tradeStore.summary.totalTrades)")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }

                    Divider().frame(height: 30).opacity(0.2)

                    VStack(spacing: 4) {
                        Text("胜/负")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                        HStack(spacing: 2) {
                            Text("\(tradeStore.summary.winCount)")
                                .foregroundStyle(LiquidGlassTheme.profitGreen)
                            Text("/")
                                .foregroundStyle(.white.opacity(0.3))
                            Text("\(tradeStore.summary.lossCount)")
                                .foregroundStyle(LiquidGlassTheme.lossRed)
                        }
                        .font(.headline)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatPill(
                title: "现货盈亏",
                value: String(format: "%+.2f", tradeStore.summary.spotPnL),
                color: tradeStore.summary.spotPnL >= 0 ? LiquidGlassTheme.profitGreen : LiquidGlassTheme.lossRed
            )
            StatPill(
                title: "合约盈亏",
                value: String(format: "%+.2f", tradeStore.summary.futuresPnL),
                color: tradeStore.summary.futuresPnL >= 0 ? LiquidGlassTheme.profitGreen : LiquidGlassTheme.lossRed
            )
        }
    }

    private var typeFilter: some View {
        HStack(spacing: 10) {
            filterChip(title: "全部", type: nil)
            filterChip(title: "现货", type: .spot)
            filterChip(title: "合约", type: .futures)
        }
    }

    private func filterChip(title: String, type: TradeType?) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedSegment = type
            }
        } label: {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(selectedSegment == type ? .white : .white.opacity(0.45))
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background {
                    if selectedSegment == type {
                        Capsule()
                            .fill(LiquidGlassTheme.accentCyan.opacity(0.25))
                            .overlay {
                                Capsule()
                                    .stroke(LiquidGlassTheme.accentCyan.opacity(0.4), lineWidth: 0.5)
                            }
                    } else {
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                    }
                }
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var recentTradesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("最近交易")
                .font(.headline)
                .foregroundStyle(.white)

            if tradeStore.recentTrades().isEmpty {
                EmptyStateView(
                    icon: "tray",
                    title: "暂无交易记录",
                    subtitle: "点击底部「添加」开始记录您的第一笔交易"
                )
            } else {
                ForEach(Array(tradeStore.recentTrades().enumerated()), id: \.element.id) { index, trade in
                    TradeRowView(trade: trade)
                        .staggeredAppear(index: index)
                }
            }
        }
    }

    private var filteredTrades: [TradeRecord] {
        if let type = selectedSegment {
            return tradeStore.trades(for: type)
        }
        return tradeStore.trades
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: Date())
    }
}

struct TradeRowView: View {
    let trade: TradeRecord
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 14) {
            CryptoIconView(symbol: trade.cryptoSymbol, size: 42)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(trade.cryptoSymbol.uppercased())
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)

                    Text(trade.tradeType.rawValue)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(LiquidGlassTheme.accentCyan)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(LiquidGlassTheme.accentCyan.opacity(0.15)))

                    if trade.tradeType == .futures, let dir = trade.direction {
                        Text(dir.rawValue)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Text(trade.isClosed ? "已平仓" : "持仓中")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }

            Spacer()

            if let pnl = trade.pnl {
                PnLBadge(pnl: pnl, compact: true)
            } else {
                Text("—")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .padding(14)
        .liquidGlass(cornerRadius: 16, opacity: 0.08)
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}
