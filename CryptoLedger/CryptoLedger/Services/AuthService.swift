import Foundation
import Combine
import CryptoKit

@MainActor
final class AuthService: ObservableObject {
    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticated = false
    @Published var authError: AuthError?

    private let credentialsKey = "crypto_ledger_credentials"
    private let sessionKey = "crypto_ledger_session"

    init() {
        restoreSession()
    }

    var displayName: String {
        currentUser?.displayName ?? "用户"
    }

    func register(email: String, password: String, displayName: String) throws {
        guard isValidEmail(email) else { throw AuthError.invalidEmail }
        guard password.count >= 6 else { throw AuthError.passwordTooShort }
        guard !displayName.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AuthError.invalidEmail
        }

        var credentials = loadAllCredentials()
        if credentials.contains(where: { $0.email.lowercased() == email.lowercased() }) {
            throw AuthError.emailAlreadyExists
        }

        let user = User(email: email.lowercased(), displayName: displayName.trimmingCharacters(in: .whitespaces))
        let cred = AuthCredentials(
            email: email.lowercased(),
            passwordHash: hashPassword(password),
            user: user
        )
        credentials.append(cred)
        saveAllCredentials(credentials)
        signIn(user: user)
    }

    func login(email: String, password: String) throws {
        let credentials = loadAllCredentials()
        guard let match = credentials.first(where: { $0.email.lowercased() == email.lowercased() }),
              match.passwordHash == hashPassword(password) else {
            throw AuthError.invalidCredentials
        }
        signIn(user: match.user)
    }

    func logout() {
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }

    private func signIn(user: User) {
        currentUser = user
        isAuthenticated = true
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: sessionKey)
        }
    }

    private func restoreSession() {
        guard let data = UserDefaults.standard.data(forKey: sessionKey),
              let user = try? JSONDecoder().decode(User.self, from: data) else { return }
        currentUser = user
        isAuthenticated = true
    }

    private func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    private func loadAllCredentials() -> [AuthCredentials] {
        guard let data = UserDefaults.standard.data(forKey: credentialsKey),
              let creds = try? JSONDecoder().decode([AuthCredentials].self, from: data) else {
            return []
        }
        return creds
    }

    private func saveAllCredentials(_ credentials: [AuthCredentials]) {
        if let data = try? JSONEncoder().encode(credentials) {
            UserDefaults.standard.set(data, forKey: credentialsKey)
        }
    }
}
