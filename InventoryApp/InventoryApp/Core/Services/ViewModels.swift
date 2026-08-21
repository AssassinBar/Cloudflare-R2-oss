import Foundation
import Observation

@Observable
final class DashboardViewModel {
    private let service: any InventoryServicing

    var snapshot: DashboardSnapshot?
    var isLoading = false
    var errorMessage: String?

    init(service: any InventoryServicing = ServiceFactory.makeInventoryService()) {
        self.service = service
    }

    @MainActor
    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            snapshot = try await service.fetchDashboard()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@Observable
final class ProductsViewModel {
    private let service: any InventoryServicing

    var products: [Product] = []
    var searchText = ""
    var isLoading = false
    var errorMessage: String?

    init(service: any InventoryServicing = ServiceFactory.makeInventoryService()) {
        self.service = service
    }

    @MainActor
    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await service.fetchProducts(query: searchText, page: 1, pageSize: 50)
            products = response.items
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@Observable
final class PurchasesViewModel {
    private let service: any InventoryServicing

    var orders: [PurchaseOrder] = []
    var isLoading = false
    var errorMessage: String?

    init(service: any InventoryServicing = ServiceFactory.makeInventoryService()) {
        self.service = service
    }

    @MainActor
    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await service.fetchPurchases(page: 1, pageSize: 50)
            orders = response.items
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@Observable
final class SalesViewModel {
    private let service: any InventoryServicing

    var orders: [SalesOrder] = []
    var isLoading = false
    var errorMessage: String?

    init(service: any InventoryServicing = ServiceFactory.makeInventoryService()) {
        self.service = service
    }

    @MainActor
    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await service.fetchSales(page: 1, pageSize: 50)
            orders = response.items
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@Observable
final class InventoryViewModel {
    private let service: any InventoryServicing

    var summary: InventorySummary?
    var movements: [StockMovement] = []
    var isLoading = false
    var errorMessage: String?

    init(service: any InventoryServicing = ServiceFactory.makeInventoryService()) {
        self.service = service
    }

    @MainActor
    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let summaryTask = service.fetchInventorySummary()
            async let movementsTask = service.fetchMovements(page: 1, pageSize: 50)
            summary = try await summaryTask
            movements = try await movementsTask.items
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@Observable
final class PartnersViewModel {
    private let service: any InventoryServicing

    var partners: [Partner] = []
    var filter: PartnerType?
    var isLoading = false
    var errorMessage: String?

    init(service: any InventoryServicing = ServiceFactory.makeInventoryService()) {
        self.service = service
    }

    @MainActor
    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await service.fetchPartners(type: filter, page: 1, pageSize: 50)
            partners = response.items
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
