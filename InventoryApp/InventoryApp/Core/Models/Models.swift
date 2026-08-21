import Foundation

// MARK: - Product

struct Product: Identifiable, Codable, Hashable {
    let id: String
    var sku: String
    var name: String
    var category: String
    var unit: String
    var costPrice: Decimal
    var salePrice: Decimal
    var stockQuantity: Int
    var lowStockThreshold: Int
    var barcode: String?
    var note: String?
    var updatedAt: Date

    var isLowStock: Bool { stockQuantity <= lowStockThreshold }
    var stockValue: Decimal { costPrice * Decimal(stockQuantity) }
}

// MARK: - Partner

enum PartnerType: String, Codable, CaseIterable, Identifiable {
    case supplier
    case customer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .supplier: return "供应商"
        case .customer: return "客户"
        }
    }
}

struct Partner: Identifiable, Codable, Hashable {
    let id: String
    var type: PartnerType
    var name: String
    var contact: String?
    var phone: String?
    var email: String?
    var address: String?
}

// MARK: - Documents

enum DocumentStatus: String, Codable, CaseIterable, Identifiable {
    case draft
    case confirmed
    case completed
    case cancelled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .draft: return "草稿"
        case .confirmed: return "已确认"
        case .completed: return "已完成"
        case .cancelled: return "已取消"
        }
    }
}

struct DocumentLine: Identifiable, Codable, Hashable {
    let id: String
    var productId: String
    var productName: String
    var quantity: Int
    var unitPrice: Decimal

    var lineTotal: Decimal { unitPrice * Decimal(quantity) }
}

struct PurchaseOrder: Identifiable, Codable, Hashable {
    let id: String
    var number: String
    var supplierId: String
    var supplierName: String
    var status: DocumentStatus
    var lines: [DocumentLine]
    var createdAt: Date
    var expectedAt: Date?

    var totalAmount: Decimal {
        lines.reduce(0) { $0 + $1.lineTotal }
    }

    var totalQuantity: Int {
        lines.reduce(0) { $0 + $1.quantity }
    }
}

struct SalesOrder: Identifiable, Codable, Hashable {
    let id: String
    var number: String
    var customerId: String
    var customerName: String
    var status: DocumentStatus
    var lines: [DocumentLine]
    var createdAt: Date

    var totalAmount: Decimal {
        lines.reduce(0) { $0 + $1.lineTotal }
    }

    var totalQuantity: Int {
        lines.reduce(0) { $0 + $1.quantity }
    }
}

// MARK: - Inventory

enum StockMovementType: String, Codable {
    case inbound
    case outbound
    case adjust

    var title: String {
        switch self {
        case .inbound: return "入库"
        case .outbound: return "出库"
        case .adjust: return "调整"
        }
    }
}

struct StockMovement: Identifiable, Codable, Hashable {
    let id: String
    var productId: String
    var productName: String
    var type: StockMovementType
    var quantity: Int
    var balanceAfter: Int
    var reference: String?
    var createdAt: Date
}

struct InventorySummary: Codable, Hashable {
    var skuCount: Int
    var totalUnits: Int
    var totalValue: Decimal
    var lowStockCount: Int
}

struct DashboardSnapshot: Codable, Hashable {
    var inventory: InventorySummary
    var todaySalesAmount: Decimal
    var todayPurchaseAmount: Decimal
    var pendingOrders: Int
    var recentMovements: [StockMovement]
    var lowStockProducts: [Product]
}

// MARK: - API envelope

struct APIListResponse<T: Codable>: Codable {
    let items: [T]
    let total: Int
    let page: Int
    let pageSize: Int
}

struct APIErrorResponse: Codable {
    let code: String
    let message: String
}
