import Foundation

enum Formatters {
    static let currency: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "CNY"
        f.currencySymbol = "¥"
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 0
        return f
    }()

    static let compactDate: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 HH:mm"
        return f
    }()

    static let dayDate: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy年M月d日"
        return f
    }()

    static func money(_ value: Decimal) -> String {
        currency.string(from: value as NSDecimalNumber) ?? "¥0"
    }

    static func quantity(_ value: Int, unit: String? = nil) -> String {
        if let unit {
            return "\(value) \(unit)"
        }
        return "\(value)"
    }
}
