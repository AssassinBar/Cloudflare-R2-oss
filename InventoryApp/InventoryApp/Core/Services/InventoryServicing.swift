import Foundation

/// Domain service contracts. Swap MockInventoryService ↔ RemoteInventoryService
/// without touching ViewModels or UI.
protocol InventoryServicing: Sendable {
    func fetchDashboard() async throws -> DashboardSnapshot
    func fetchProducts(query: String?, page: Int, pageSize: Int) async throws -> APIListResponse<Product>
    func fetchProduct(id: String) async throws -> Product
    func fetchPurchases(page: Int, pageSize: Int) async throws -> APIListResponse<PurchaseOrder>
    func fetchSales(page: Int, pageSize: Int) async throws -> APIListResponse<SalesOrder>
    func fetchMovements(page: Int, pageSize: Int) async throws -> APIListResponse<StockMovement>
    func fetchPartners(type: PartnerType?, page: Int, pageSize: Int) async throws -> APIListResponse<Partner>
    func fetchInventorySummary() async throws -> InventorySummary
}

enum ServiceFactory {
    static func makeInventoryService() -> any InventoryServicing {
        switch AppEnvironment.current {
        case .mock:
            return MockInventoryService()
        case .remote(let baseURL):
            return RemoteInventoryService(client: APIClient(baseURL: baseURL))
        }
    }
}
