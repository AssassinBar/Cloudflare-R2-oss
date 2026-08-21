import Foundation

/// Local mock backend so the UI framework runs without a server.
@MainActor
final class MockInventoryService: InventoryServicing, @unchecked Sendable {
    private let products: [Product]
    private let purchases: [PurchaseOrder]
    private let sales: [SalesOrder]
    private let movements: [StockMovement]
    private let partners: [Partner]

    init() {
        let now = Date()
        let calendar = Calendar.current

        products = [
            Product(
                id: "p1", sku: "SKU-1001", name: "无线降噪耳机 Pro", category: "电子产品",
                unit: "台", costPrice: 680, salePrice: 1299, stockQuantity: 42,
                lowStockThreshold: 10, barcode: "6901001001", note: nil, updatedAt: now
            ),
            Product(
                id: "p2", sku: "SKU-2048", name: "不锈钢保温杯 500ml", category: "日用百货",
                unit: "个", costPrice: 28, salePrice: 79, stockQuantity: 8,
                lowStockThreshold: 20, barcode: "6901002048", note: "畅销款", updatedAt: now
            ),
            Product(
                id: "p3", sku: "SKU-3301", name: "有机燕麦片 1kg", category: "食品",
                unit: "袋", costPrice: 18, salePrice: Decimal(string: "39.9") ?? 40, stockQuantity: 120,
                lowStockThreshold: 30, barcode: "6901003301", note: nil, updatedAt: now
            ),
            Product(
                id: "p4", sku: "SKU-4410", name: "亚麻衬衫 · 米白", category: "服饰",
                unit: "件", costPrice: 95, salePrice: 259, stockQuantity: 5,
                lowStockThreshold: 8, barcode: "6901004410", note: nil, updatedAt: now
            ),
            Product(
                id: "p5", sku: "SKU-5502", name: "桌面支架 铝合金", category: "电子配件",
                unit: "个", costPrice: 45, salePrice: 129, stockQuantity: 67,
                lowStockThreshold: 15, barcode: nil, note: nil, updatedAt: now
            )
        ]

        partners = [
            Partner(id: "s1", type: .supplier, name: "华南供应链有限公司", contact: "陈经理", phone: "13800001111", email: "chen@example.com", address: "深圳南山"),
            Partner(id: "s2", type: .supplier, name: "绿源食品批发", contact: "王总", phone: "13900002222", email: nil, address: "广州白云"),
            Partner(id: "c1", type: .customer, name: "星选生活馆", contact: "李小姐", phone: "13600003333", email: "li@example.com", address: "上海静安"),
            Partner(id: "c2", type: .customer, name: "城北便利店", contact: "赵先生", phone: "13700004444", email: nil, address: "杭州余杭")
        ]

        purchases = [
            PurchaseOrder(
                id: "po1", number: "PO-20260820-001", supplierId: "s1", supplierName: "华南供应链有限公司",
                status: .confirmed,
                lines: [
                    DocumentLine(id: "l1", productId: "p1", productName: "无线降噪耳机 Pro", quantity: 20, unitPrice: 680),
                    DocumentLine(id: "l2", productId: "p5", productName: "桌面支架 铝合金", quantity: 40, unitPrice: 45)
                ],
                createdAt: calendar.date(byAdding: .hour, value: -5, to: now) ?? now,
                expectedAt: calendar.date(byAdding: .day, value: 2, to: now)
            ),
            PurchaseOrder(
                id: "po2", number: "PO-20260819-014", supplierId: "s2", supplierName: "绿源食品批发",
                status: .completed,
                lines: [
                    DocumentLine(id: "l3", productId: "p3", productName: "有机燕麦片 1kg", quantity: 80, unitPrice: 18)
                ],
                createdAt: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                expectedAt: nil
            )
        ]

        sales = [
            SalesOrder(
                id: "so1", number: "SO-20260820-008", customerId: "c1", customerName: "星选生活馆",
                status: .completed,
                lines: [
                    DocumentLine(id: "sl1", productId: "p1", productName: "无线降噪耳机 Pro", quantity: 3, unitPrice: 1299),
                    DocumentLine(id: "sl2", productId: "p2", productName: "不锈钢保温杯 500ml", quantity: 12, unitPrice: 79)
                ],
                createdAt: calendar.date(byAdding: .hour, value: -2, to: now) ?? now
            ),
            SalesOrder(
                id: "so2", number: "SO-20260820-003", customerId: "c2", customerName: "城北便利店",
                status: .confirmed,
                lines: [
                    DocumentLine(id: "sl3", productId: "p3", productName: "有机燕麦片 1kg", quantity: 24, unitPrice: Decimal(string: "39.9") ?? 40)
                ],
                createdAt: calendar.date(byAdding: .hour, value: -6, to: now) ?? now
            )
        ]

        movements = [
            StockMovement(id: "m1", productId: "p1", productName: "无线降噪耳机 Pro", type: .outbound, quantity: 3, balanceAfter: 42, reference: "SO-20260820-008", createdAt: calendar.date(byAdding: .hour, value: -2, to: now) ?? now),
            StockMovement(id: "m2", productId: "p2", productName: "不锈钢保温杯 500ml", type: .outbound, quantity: 12, balanceAfter: 8, reference: "SO-20260820-008", createdAt: calendar.date(byAdding: .hour, value: -2, to: now) ?? now),
            StockMovement(id: "m3", productId: "p3", productName: "有机燕麦片 1kg", type: .inbound, quantity: 80, balanceAfter: 120, reference: "PO-20260819-014", createdAt: calendar.date(byAdding: .day, value: -1, to: now) ?? now),
            StockMovement(id: "m4", productId: "p4", productName: "亚麻衬衫 · 米白", type: .adjust, quantity: -2, balanceAfter: 5, reference: "盘点差异", createdAt: calendar.date(byAdding: .day, value: -2, to: now) ?? now)
        ]
    }

    private func latency() async {
        try? await Task.sleep(nanoseconds: 280_000_000)
    }

    func fetchDashboard() async throws -> DashboardSnapshot {
        await latency()
        let summary = try await fetchInventorySummary()
        let todaySales = sales
            .filter { Calendar.current.isDateInToday($0.createdAt) }
            .reduce(Decimal(0)) { $0 + $1.totalAmount }
        let todayPurchase = purchases
            .filter { Calendar.current.isDateInToday($0.createdAt) }
            .reduce(Decimal(0)) { $0 + $1.totalAmount }
        let pending = purchases.filter { $0.status == .confirmed || $0.status == .draft }.count
            + sales.filter { $0.status == .confirmed || $0.status == .draft }.count

        return DashboardSnapshot(
            inventory: summary,
            todaySalesAmount: todaySales,
            todayPurchaseAmount: todayPurchase,
            pendingOrders: pending,
            recentMovements: Array(movements.prefix(5)),
            lowStockProducts: products.filter(\.isLowStock)
        )
    }

    func fetchProducts(query: String?, page: Int, pageSize: Int) async throws -> APIListResponse<Product> {
        await latency()
        var items = products
        if let query, !query.isEmpty {
            let q = query.lowercased()
            items = items.filter {
                $0.name.lowercased().contains(q)
                    || $0.sku.lowercased().contains(q)
                    || $0.category.lowercased().contains(q)
            }
        }
        return paginate(items, page: page, pageSize: pageSize)
    }

    func fetchProduct(id: String) async throws -> Product {
        await latency()
        guard let product = products.first(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        return product
    }

    func fetchPurchases(page: Int, pageSize: Int) async throws -> APIListResponse<PurchaseOrder> {
        await latency()
        return paginate(purchases, page: page, pageSize: pageSize)
    }

    func fetchSales(page: Int, pageSize: Int) async throws -> APIListResponse<SalesOrder> {
        await latency()
        return paginate(sales, page: page, pageSize: pageSize)
    }

    func fetchMovements(page: Int, pageSize: Int) async throws -> APIListResponse<StockMovement> {
        await latency()
        return paginate(movements, page: page, pageSize: pageSize)
    }

    func fetchPartners(type: PartnerType?, page: Int, pageSize: Int) async throws -> APIListResponse<Partner> {
        await latency()
        let items = type.map { t in partners.filter { $0.type == t } } ?? partners
        return paginate(items, page: page, pageSize: pageSize)
    }

    func fetchInventorySummary() async throws -> InventorySummary {
        InventorySummary(
            skuCount: products.count,
            totalUnits: products.reduce(0) { $0 + $1.stockQuantity },
            totalValue: products.reduce(0) { $0 + $1.stockValue },
            lowStockCount: products.filter(\.isLowStock).count
        )
    }

    private func paginate<T>(_ items: [T], page: Int, pageSize: Int) -> APIListResponse<T> {
        let safePage = max(page, 1)
        let start = (safePage - 1) * pageSize
        let slice: [T]
        if start >= items.count {
            slice = []
        } else {
            let end = min(start + pageSize, items.count)
            slice = Array(items[start..<end])
        }
        return APIListResponse(items: slice, total: items.count, page: safePage, pageSize: pageSize)
    }
}
