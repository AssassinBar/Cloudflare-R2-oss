import Foundation
import UserNotifications
import Combine

struct AppNotification: Identifiable, Codable {
    let id: UUID
    var title: String
    var body: String
    var createdAt: Date
    var isRead: Bool
    var type: NotificationType

    enum NotificationType: String, Codable {
        case pnlAlert
        case tradeReminder
        case system
    }

    init(
        id: UUID = UUID(),
        title: String,
        body: String,
        createdAt: Date = Date(),
        isRead: Bool = false,
        type: NotificationType = .system
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.createdAt = createdAt
        self.isRead = isRead
        self.type = type
    }
}

@MainActor
final class NotificationManager: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var isAuthorized = false

    private let storageKey = "crypto_ledger_notifications"

    init() {
        loadNotifications()
        if notifications.isEmpty {
            seedWelcomeNotification()
        }
    }

    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            Task { @MainActor in
                self.isAuthorized = granted
            }
        }
    }

    func addNotification(_ notification: AppNotification) {
        notifications.insert(notification, at: 0)
        persist()
        scheduleLocalNotification(notification)
    }

    func markAsRead(_ notification: AppNotification) {
        guard let index = notifications.firstIndex(where: { $0.id == notification.id }) else { return }
        notifications[index].isRead = true
        persist()
    }

    func markAllAsRead() {
        for i in notifications.indices {
            notifications[i].isRead = true
        }
        persist()
    }

    func notifyPnLAlert(symbol: String, pnl: Double) {
        let isProfit = pnl >= 0
        let notification = AppNotification(
            title: isProfit ? "盈利提醒" : "亏损提醒",
            body: "\(symbol) 交易已平仓，\(isProfit ? "盈利" : "亏损") \(String(format: "%.2f", abs(pnl))) USDT",
            type: .pnlAlert
        )
        addNotification(notification)
    }

    func notifyTradeReminder(symbol: String) {
        let notification = AppNotification(
            title: "持仓提醒",
            body: "\(symbol) 合约持仓尚未平仓，记得关注行情变化",
            type: .tradeReminder
        )
        addNotification(notification)
    }

    private func scheduleLocalNotification(_ notification: AppNotification) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: notification.id.uuidString,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func seedWelcomeNotification() {
        notifications = [
            AppNotification(
                title: "欢迎使用 CryptoLedger",
                body: "开始记录您的合约与现货盈亏，掌握每一笔交易",
                type: .system
            )
        ]
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(notifications) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadNotifications() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let loaded = try? JSONDecoder().decode([AppNotification].self, from: data) else { return }
        notifications = loaded
    }
}
