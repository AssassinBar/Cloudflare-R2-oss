import CryptoKit
import Foundation

enum XiaomiJSON {
    static let prefix = "&&&START&&&"

    static func parse(_ data: Data) throws -> [String: Any] {
        var payload = data
        if let prefix = prefix.data(using: .utf8), payload.starts(with: prefix) {
            payload = payload.dropFirst(prefix.count)
        }
        let object = try JSONSerialization.jsonObject(with: payload)
        guard let dict = object as? [String: Any] else {
            throw XiaomiError.badResponse("账号接口返回不是 JSON 对象")
        }
        return dict
    }

    static func parse(_ text: String) throws -> [String: Any] {
        try parse(Data(text.utf8))
    }
}

enum XiaomiError: LocalizedError {
    case badResponse(String)
    case loginFailed(String)
    case notAuthorized
    case noSpeaker
    case speakerFailed(String)

    var errorDescription: String? {
        switch self {
        case .badResponse(let text), .loginFailed(let text), .speakerFailed(let text):
            return text
        case .notAuthorized:
            return "尚未登录小米账号，请先扫码或登录授权小爱音箱"
        case .noSpeaker:
            return "账号下没有可用的小爱音箱，请在米家里确认音箱在线"
        }
    }
}

struct XiaoAiSpeakerDevice: Identifiable, Codable, Equatable, Hashable {
    var deviceID: String
    var name: String
    var hardware: String
    var presence: String
    var miotDID: String

    var id: String { deviceID }
    var isOnline: Bool {
        presence.isEmpty || presence.lowercased() == "online" || presence == "1"
    }

    init(deviceID: String, name: String, hardware: String = "", presence: String = "", miotDID: String = "") {
        self.deviceID = deviceID
        self.name = name
        self.hardware = hardware
        self.presence = presence
        self.miotDID = miotDID
    }

    init(dict: [String: Any]) {
        deviceID = (dict["deviceID"] as? String) ?? (dict["deviceId"] as? String) ?? ""
        name = (dict["name"] as? String) ?? "小爱音箱"
        hardware = (dict["hardware"] as? String) ?? (dict["miotDID"] as? String) ?? ""
        presence = (dict["presence"] as? String) ?? ""
        miotDID = "\(dict["miotDID"] ?? "")"
    }
}

struct XiaomiToken: Codable {
    var deviceId: String
    var userId: String
    var passToken: String
    var services: [String: XiaomiServiceToken]
    var savedAt: Date

    var isAuthorized: Bool {
        !userId.isEmpty && services["micoapi"] != nil
    }
}

struct XiaomiServiceToken: Codable {
    var ssecurity: String
    var serviceToken: String
}

enum XiaomiCrypto {
    static func md5Upper(_ text: String) -> String {
        Insecure.MD5.hash(data: Data(text.utf8)).map { String(format: "%02X", $0) }.joined()
    }

    static func clientSign(nonce: String, ssecurity: String) -> String {
        let nsec = "nonce=\(nonce)&\(ssecurity)"
        let digest = Insecure.SHA1.hash(data: Data(nsec.utf8))
        return Data(digest).base64EncodedString()
    }

    static func randomDeviceId() -> String {
        let chars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        return String((0..<16).map { _ in chars.randomElement()! })
    }
}

enum XiaomiAPI {
    static let accountBase = "https://account.xiaomi.com"
    static let minaBase = "https://api2.mina.mi.com"
    static let ioCallback = "https://sts.api.io.mi.com/sts"
    static let sidHome = "xiaomiio"
    static let sidMina = "micoapi"
    static let uaLogin = "APP/com.xiaomi.mihome APPV/10.3.203 iosPassportSDK/4.2.50 iOS/17.0"
    static let uaMina = "MiHome/6.0.103 (com.xiaomi.mihome; build:6.0.103.1; iOS 14.4.0) Alamofire/6.0.103 MICO/iOSApp/appStore/6.0.103"

    static func qrLoginQuery(deviceId: String, now: Int = Int(Date().timeIntervalSince1970 * 1000)) -> [String: String] {
        [
            "_qrsize": "240",
            "qs": "%3Fsid%3Dxiaomiio%26_json%3Dtrue",
            "callback": ioCallback,
            "_hasLogo": "false",
            "sid": sidHome,
            "serviceParam": "",
            "_locale": "zh_CN",
            "_dc": String(now),
            "deviceId": deviceId
        ]
    }
}

enum XiaomiKeychain {
    static let service = "cn.xiaoai.cursor.confirm.xiaomi"

    static func save(_ token: XiaomiToken) {
        guard let data = try? JSONEncoder().encode(token) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "token"
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        SecItemAdd(add as CFDictionary, nil)
    }

    static func load() -> XiaomiToken? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "token",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return try? JSONDecoder().decode(XiaomiToken.self, from: data)
    }

    static func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        SecItemDelete(query as CFDictionary)
    }
}
