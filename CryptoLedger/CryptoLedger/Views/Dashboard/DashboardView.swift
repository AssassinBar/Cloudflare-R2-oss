import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var tradeStore: TradeStore
    @EnvironmentObject private var authService: AuthService

    @State private var selectedSegment: TradeType? = nil

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                headerSection
                    .staggeredAppear(index: 0)

                totalPnLSection
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
            .padding(.horizontal, 22)
            .padding(.top, 20)
            .padding(.bottom, 110)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(formattedDate.uppercased())
                .font(.system(size: 11, weight: .medium))
                .tracking(1.2)
                .foregroundStyle(LiquidGlassTheme.textTertiary)

            Text(authService.displayName)
                .font(.system(size: 26, weight: .semibold))
                .tracking(-0.4)
                .foregroundStyle(LiquidGlassTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var totalPnLSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("总盈亏")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(LiquidGlassTheme.textSecondary)

            AnimatedNumber(
                value: tradeStore.summary.totalPnL,
                suffix: " USDT",
                color: tradeStore.summary.totalPnL >= 0
                    ? LiquidGlassTheme.profitGreen
                    : LiquidGlassTheme.lossRed
            )

            HStack(spacing: 24) {
                metric(label: "胜率", value: String(format: "%.0f%%", tradeStore.summary.winRate))
                metric(label: "交易", value: "\(tradeStore.summary.totalTrades)")
                metric(
                    label: "胜 / 负",
                    value: "\(tradeStore.summary.winCount) / \(tradeStore.summary.lossCount)"
                )
            }
            .padding(.top, 8)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlass(cornerRadius: LiquidGlassTheme.cardCornerRadius)
    }

    private func metric(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(LiquidGlassTheme.textTertiary)
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(LiquidGlassTheme.textPrimary)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            StatPill(
                title: "现货",
                value: String(format: "%+.2f", tradeStore.summary.spotPnL),
                color: tradeStore.summary.spotPnL >= 0 ? LiquidGlassTheme.profitGreen : LiquidGlassTheme.lossRed
            )
            StatPill(
                title: "合约",
                value: String(format: "%+.2f", tradeStore.summary.futuresPnL),
                color: tradeStore.summary.futuresPnL >= 0 ? LiquidGlassTheme.profitGreen : LiquidGlassTheme.lossRed
            )
        }
    }

    private var typeFilter: some View {
        HStack(spacing: 18) {
            filterItem(title: "全部", type: nil)
            filterItem(title: "现货", type: .spot)
            filterItem(title: "合约", type: .futures)
            Spacer()
        }
    }

    private func filterItem(title: String, type: TradeType?) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) {
                selectedSegment = type
            }
        } label: {
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: selectedSegment == type ? .medium : .regular))
                    .foregroundStyle(
                        selectedSegment == type
                            ? LiquidGlassTheme.textPrimary
                            : LiquidGlassTheme.textTertiary
                    )

                Rectangle()
                    .fill(selectedSegment == type ? LiquidGlassTheme.textPrimary.opacity(0.7) : Color.clear)
                    .frame(width: 16, height: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var recentTradesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("最近交易")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(LiquidGlassTheme.textPrimary)

            if tradeStore.recentTrades().isEmpty {
                EmptyStateView(
                    icon: "tray",
                    title: "暂无交易记录",
                    subtitle: "在「添加」中记录第一笔现货或合约交易"
                )
                .frame(maxWidth: .infinity)
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

    var body: some View {
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

                Text(trade.isClosed ? "已平仓" : "持仓中")
                    .font(.system(size: 12))
                    .foregroundStyle(LiquidGlassTheme.textTertiary)
            }

            Spacer()

            if let pnl = trade.pnl {
                PnLBadge(pnl: pnl, compact: true)
            } else {
                Text("—")
                    .font(.system(size: 13))
                    .foregroundStyle(LiquidGlassTheme.textTertiary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .liquidGlass(cornerRadius: 14, opacity: 0.05, borderOpacity: 0.1)
    }
}
