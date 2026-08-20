import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: UUID
    var email: String
    var displayName: String
    var createdAt: Date

    init(id: UUID = UUID(), email: String, displayName: String, createdAt: Date = Date()) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.createdAt = createdAt
    }
}

struct AuthCredentials: Codable {
    let email: String
    let passwordHash: String
    let user: User
}

enum AuthError: LocalizedError {
    case invalidEmail
    case passwordTooShort
    case emailAlreadyExists
    case invalidCredentials
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .invalidEmail: return "请输入有效的邮箱地址"
        case .passwordTooShort: return "密码至少需要 6 位"
        case .emailAlreadyExists: return "该邮箱已注册"
        case .invalidCredentials: return "邮箱或密码错误"
        case .notAuthenticated: return "请先登录"
        }
    }
}
