import Foundation

enum TradeType: String, Codable, CaseIterable, Identifiable {
    case spot = "现货"
    case futures = "合约"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .spot: return "bitcoinsign.circle.fill"
        case .futures: return "chart.line.uptrend.xyaxis.circle.fill"
        }
    }
}

enum TradeDirection: String, Codable, CaseIterable, Identifiable {
    case long = "做多"
    case short = "做空"

    var id: String { rawValue }
}

struct TradeRecord: Codable, Identifiable, Equatable {
    let id: UUID
    var cryptoSymbol: String
    var tradeType: TradeType
    var direction: TradeDirection?
    var entryPrice: Double
    var exitPrice: Double?
    var quantity: Double
    var leverage: Int?
    var fee: Double
    var note: String
    var createdAt: Date
    var closedAt: Date?

    init(
        id: UUID = UUID(),
        cryptoSymbol: String,
        tradeType: TradeType,
        direction: TradeDirection? = nil,
        entryPrice: Double,
        exitPrice: Double? = nil,
        quantity: Double,
        leverage: Int? = nil,
        fee: Double = 0,
        note: String = "",
        createdAt: Date = Date(),
        closedAt: Date? = nil
    ) {
        self.id = id
        self.cryptoSymbol = cryptoSymbol
        self.tradeType = tradeType
        self.direction = direction
        self.entryPrice = entryPrice
        self.exitPrice = exitPrice
        self.quantity = quantity
        self.leverage = leverage
        self.fee = fee
        self.note = note
        self.createdAt = createdAt
        self.closedAt = closedAt
    }

    var isClosed: Bool { exitPrice != nil }

    var pnl: Double? {
        guard let exit = exitPrice else { return nil }
        let priceDiff: Double
        switch (tradeType, direction) {
        case (.spot, _):
            priceDiff = exit - entryPrice
        case (.futures, .long), (.futures, .none):
            priceDiff = exit - entryPrice
        case (.futures, .short):
            priceDiff = entryPrice - exit
        }
        var result = priceDiff * quantity
        if tradeType == .futures, let lev = leverage {
            result *= Double(lev)
        }
        return result - fee
    }

    var unrealizedPnL: Double? {
        guard !isClosed else { return nil }
        return nil
    }

    var pnlPercent: Double? {
        guard let pnl, entryPrice > 0 else { return nil }
        let invested = entryPrice * quantity
        guard invested > 0 else { return nil }
        return (pnl / invested) * 100
    }
}

struct PortfolioSummary {
    let totalPnL: Double
    let spotPnL: Double
    let futuresPnL: Double
    let winCount: Int
    let lossCount: Int
    let winRate: Double
    let totalTrades: Int

    static let empty = PortfolioSummary(
        totalPnL: 0, spotPnL: 0, futuresPnL: 0,
        winCount: 0, lossCount: 0, winRate: 0, totalTrades: 0
    )
}
