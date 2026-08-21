import Foundation

/// Example remote implementation. Wire real endpoints when backend is ready.
@MainActor
final class RemoteInventoryService: InventoryServicing, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchDashboard() async throws -> DashboardSnapshot {
        try await client.send(DashboardRequest())
    }

    func fetchProducts(query: String?, page: Int, pageSize: Int) async throws -> APIListResponse<Product> {
        try await client.send(ProductsRequest(query: query, page: page, pageSize: pageSize))
    }

    func fetchProduct(id: String) async throws -> Product {
        try await client.send(ProductDetailRequest(id: id))
    }

    func fetchPurchases(page: Int, pageSize: Int) async throws -> APIListResponse<PurchaseOrder> {
        try await client.send(PurchasesRequest(page: page, pageSize: pageSize))
    }

    func fetchSales(page: Int, pageSize: Int) async throws -> APIListResponse<SalesOrder> {
        try await client.send(SalesRequest(page: page, pageSize: pageSize))
    }

    func fetchMovements(page: Int, pageSize: Int) async throws -> APIListResponse<StockMovement> {
        try await client.send(MovementsRequest(page: page, pageSize: pageSize))
    }

    func fetchPartners(type: PartnerType?, page: Int, pageSize: Int) async throws -> APIListResponse<Partner> {
        try await client.send(PartnersRequest(type: type, page: page, pageSize: pageSize))
    }

    func fetchInventorySummary() async throws -> InventorySummary {
        try await client.send(InventorySummaryRequest())
    }
}

// MARK: - Request definitions (adjust paths to match your API)

struct DashboardRequest: APIRequest {
    typealias Response = DashboardSnapshot
    var path: String { "/api/v1/dashboard" }
}

struct ProductsRequest: APIRequest {
    typealias Response = APIListResponse<Product>
    let query: String?
    let page: Int
    let pageSize: Int

    var path: String { "/api/v1/products" }
    var queryItems: [URLQueryItem] {
        var items = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
        if let query, !query.isEmpty {
            items.append(URLQueryItem(name: "q", value: query))
        }
        return items
    }
}

struct ProductDetailRequest: APIRequest {
    typealias Response = Product
    let id: String
    var path: String { "/api/v1/products/\(id)" }
}

struct PurchasesRequest: APIRequest {
    typealias Response = APIListResponse<PurchaseOrder>
    let page: Int
    let pageSize: Int
    var path: String { "/api/v1/purchases" }
    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
    }
}

struct SalesRequest: APIRequest {
    typealias Response = APIListResponse<SalesOrder>
    let page: Int
    let pageSize: Int
    var path: String { "/api/v1/sales" }
    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
    }
}

struct MovementsRequest: APIRequest {
    typealias Response = APIListResponse<StockMovement>
    let page: Int
    let pageSize: Int
    var path: String { "/api/v1/inventory/movements" }
    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
    }
}

struct PartnersRequest: APIRequest {
    typealias Response = APIListResponse<Partner>
    let type: PartnerType?
    let page: Int
    let pageSize: Int
    var path: String { "/api/v1/partners" }
    var queryItems: [URLQueryItem] {
        var items = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
        if let type {
            items.append(URLQueryItem(name: "type", value: type.rawValue))
        }
        return items
    }
}

struct InventorySummaryRequest: APIRequest {
    typealias Response = InventorySummary
    var path: String { "/api/v1/inventory/summary" }
}
