import Foundation
import Combine

@MainActor
final class TradeStore: ObservableObject {
    @Published private(set) var trades: [TradeRecord] = []

    private var storageKey: String {
        "crypto_ledger_trades_\(userId)"
    }

    private var userId: String = "guest"

    func setUserId(_ id: UUID) {
        userId = id.uuidString
        loadTrades()
    }

    func clearUserData() {
        trades = []
        userId = "guest"
    }

    // MARK: - CRUD

    func addTrade(_ trade: TradeRecord) {
        trades.insert(trade, at: 0)
        persist()
    }

    func updateTrade(_ trade: TradeRecord) {
        guard let index = trades.firstIndex(where: { $0.id == trade.id }) else { return }
        trades[index] = trade
        persist()
    }

    func deleteTrade(_ trade: TradeRecord) {
        trades.removeAll { $0.id == trade.id }
        persist()
    }

    func closeTrade(_ trade: TradeRecord, exitPrice: Double) {
        var updated = trade
        updated.exitPrice = exitPrice
        updated.closedAt = Date()
        updateTrade(updated)
    }

    // MARK: - Analytics

    var summary: PortfolioSummary {
        let closedTrades = trades.filter { $0.isClosed }
        let pnls = closedTrades.compactMap { $0.pnl }

        let totalPnL = pnls.reduce(0, +)
        let spotPnL = closedTrades.filter { $0.tradeType == .spot }.compactMap { $0.pnl }.reduce(0, +)
        let futuresPnL = closedTrades.filter { $0.tradeType == .futures }.compactMap { $0.pnl }.reduce(0, +)
        let wins = pnls.filter { $0 > 0 }.count
        let losses = pnls.filter { $0 < 0 }.count
        let total = wins + losses
        let winRate = total > 0 ? Double(wins) / Double(total) * 100 : 0

        return PortfolioSummary(
            totalPnL: totalPnL,
            spotPnL: spotPnL,
            futuresPnL: futuresPnL,
            winCount: wins,
            lossCount: losses,
            winRate: winRate,
            totalTrades: closedTrades.count
        )
    }

    var openTrades: [TradeRecord] {
        trades.filter { !$0.isClosed }
    }

    var closedTrades: [TradeRecord] {
        trades.filter { $0.isClosed }
    }

    func trades(for type: TradeType) -> [TradeRecord] {
        trades.filter { $0.tradeType == type }
    }

    func recentTrades(limit: Int = 5) -> [TradeRecord] {
        Array(trades.prefix(limit))
    }

    // MARK: - Persistence

    private func persist() {
        if let data = try? JSONEncoder().encode(trades) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadTrades() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let loaded = try? JSONDecoder().decode([TradeRecord].self, from: data) else {
            trades = []
            return
        }
        trades = loaded.sorted { $0.createdAt > $1.createdAt }
    }
}
