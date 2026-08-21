import Foundation

final class XiaomiClient: @unchecked Sendable {
    private let session: URLSession
    private var deviceId: String

    init(deviceId: String = XiaomiCrypto.randomDeviceId()) {
        self.deviceId = deviceId
        let config = URLSessionConfiguration.ephemeral
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.timeoutIntervalForRequest = 75
        session = URLSession(configuration: config)
    }

    func startQRLogin() async throws -> QRSession {
        deviceId = XiaomiCrypto.randomDeviceId()
        var comps = URLComponents(string: "\(XiaomiAPI.accountBase)/longPolling/loginUrl")!
        comps.queryItems = XiaomiAPI.qrLoginQuery(deviceId: deviceId).map { URLQueryItem(name: $0.key, value: $0.value) }
        let json = try await getJSON(comps.url!, headers: ["User-Agent": XiaomiAPI.uaLogin])
        guard let lp = json["lp"] as? String, let qr = json["qr"] as? String else {
            throw XiaomiError.loginFailed("无法获取小米账号登录二维码")
        }
        return QRSession(
            qrURL: qr,
            loginURL: json["loginUrl"] as? String ?? qr,
            pollURL: lp,
            timeout: json["timeout"] as? Int ?? 300,
            deviceId: deviceId
        )
    }

    func waitForQRScan(_ qr: QRSession) async throws -> XiaomiToken {
        let deadline = Date().addingTimeInterval(TimeInterval(qr.timeout))
        while Date() < deadline {
            do {
                var request = URLRequest(url: URL(string: qr.pollURL)!)
                request.timeoutInterval = 20
                request.setValue(XiaomiAPI.uaLogin, forHTTPHeaderField: "User-Agent")
                let (data, response) = try await session.data(for: request)
                if let http = response as? HTTPURLResponse, http.statusCode == 200, !data.isEmpty {
                    let json = try XiaomiJSON.parse(data)
                    return try await finishLogin(json, deviceId: qr.deviceId)
                }
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                try await Task.sleep(nanoseconds: 1_200_000_000)
            }
        }
        throw XiaomiError.loginFailed("扫码超时，请刷新二维码后重试")
    }

    func login(user: String, password: String, otp: String?) async throws -> XiaomiToken {
        deviceId = XiaomiCrypto.randomDeviceId()
        let first = try await serviceLogin(sid: XiaomiAPI.sidHome)
        if (first["code"] as? Int) == 0 {
            return try await finishLogin(first, deviceId: deviceId)
        }
        let form: [String: String] = [
            "_json": "true",
            "qs": first["qs"] as? String ?? "",
            "sid": first["sid"] as? String ?? XiaomiAPI.sidHome,
            "_sign": first["_sign"] as? String ?? "",
            "callback": first["callback"] as? String ?? XiaomiAPI.ioCallback,
            "user": user,
            "hash": XiaomiCrypto.md5Upper(password)
        ]
        var auth = try await postForm("\(XiaomiAPI.accountBase)/pass/serviceLoginAuth2", form: form)
        if let notice = auth["notificationUrl"] as? String {
            guard let otp, !otp.isEmpty else {
                throw XiaomiError.loginFailed("账号开启了二次验证，请输入短信或邮箱验证码")
            }
            auth = try await verifyOTP(notice, otp: otp, sid: XiaomiAPI.sidHome)
        }
        if (auth["code"] as? Int).flatMap({ $0 != 0 }) == true {
            throw XiaomiError.loginFailed(auth["desc"] as? String ?? auth["description"] as? String ?? "小米账号登录失败")
        }
        return try await finishLogin(auth, deviceId: deviceId)
    }

    func speakers(token: XiaomiToken) async throws -> [XiaoAiSpeakerDevice] {
        guard let mina = token.services[XiaomiAPI.sidMina] else { throw XiaomiError.notAuthorized }
        let requestId = "app_ios_" + XiaomiCrypto.randomDeviceId() + XiaomiCrypto.randomDeviceId()
        let url = URL(string: "\(XiaomiAPI.minaBase)/admin/v2/device_list?master=0&requestId=\(requestId)")!
        let json = try await getJSON(url, headers: minaHeaders(), cookies: minaCookies(token, mina))
        let code = json["code"] as? Int ?? -1
        guard code == 0 else {
            throw XiaomiError.speakerFailed(json["message"] as? String ?? "获取小爱音箱列表失败")
        }
        let rows = json["data"] as? [[String: Any]] ?? []
        return rows.map(XiaoAiSpeakerDevice.init(dict:)).filter { !$0.deviceID.isEmpty }
    }

    func announce(token: XiaomiToken, deviceID: String, text: String, playChime: Bool) async throws {
        if playChime {
            _ = try? await ubus(token: token, deviceID: deviceID, method: "wakeup", path: "mibrain", message: [:])
            try await Task.sleep(nanoseconds: 350_000_000)
        }
        let result = try await ubus(
            token: token,
            deviceID: deviceID,
            method: "text_to_speech",
            path: "mibrain",
            message: ["text": text]
        )
        let code = result["code"] as? Int ?? -1
        if code != 0 {
            throw XiaomiError.speakerFailed(result["message"] as? String ?? "小爱音箱播报失败")
        }
    }

    private func ubus(token: XiaomiToken, deviceID: String, method: String, path: String, message: [String: Any]) async throws -> [String: Any] {
        guard let mina = token.services[XiaomiAPI.sidMina] else { throw XiaomiError.notAuthorized }
        let requestId = "app_ios_" + XiaomiCrypto.randomDeviceId() + XiaomiCrypto.randomDeviceId()
        let payload: [String: String] = [
            "deviceId": deviceID,
            "message": jsonString(message),
            "method": method,
            "path": path,
            "requestId": requestId
        ]
        return try await postForm(
            "\(XiaomiAPI.minaBase)/remote/ubus",
            form: payload,
            headers: minaHeaders(),
            cookies: minaCookies(token, mina)
        )
    }

    private func finishLogin(_ json: [String: Any], deviceId: String) async throws -> XiaomiToken {
        let userId = "\(json["userId"] ?? "")"
        let passToken = json["passToken"] as? String ?? ""
        guard !userId.isEmpty else {
            throw XiaomiError.loginFailed("扫码成功但未返回账号，请重试")
        }
        var token = XiaomiToken(deviceId: deviceId, userId: userId, passToken: passToken, services: [:], savedAt: Date())
        if let location = json["location"] as? String {
            let sid = XiaomiAPI.sidHome
            let ssecurity = json["ssecurity"] as? String ?? ""
            let nonce = "\(json["nonce"] ?? "")"
            let serviceToken = try await securityToken(location: location, nonce: nonce, ssecurity: ssecurity)
            token.services[sid] = XiaomiServiceToken(ssecurity: ssecurity, serviceToken: serviceToken)
        }
        token.passToken = passToken.isEmpty ? token.passToken : passToken
        token.services[XiaomiAPI.sidMina] = try await loginService(sid: XiaomiAPI.sidMina, token: token)
        if token.services[XiaomiAPI.sidHome] == nil {
            token.services[XiaomiAPI.sidHome] = try? await loginService(sid: XiaomiAPI.sidHome, token: token)
        }
        guard token.services[XiaomiAPI.sidMina] != nil else {
            throw XiaomiError.loginFailed("已登录小米账号，但未能授权小爱音箱服务（micoapi）")
        }
        return token
    }

    private func loginService(sid: String, token: XiaomiToken) async throws -> XiaomiServiceToken {
        let json = try await serviceLogin(sid: sid, userId: token.userId, passToken: token.passToken, deviceId: token.deviceId)
        if (json["code"] as? Int).flatMap({ $0 != 0 }) == true {
            throw XiaomiError.loginFailed(json["desc"] as? String ?? "授权 \(sid) 失败")
        }
        let location = json["location"] as? String ?? ""
        let ssecurity = json["ssecurity"] as? String ?? ""
        let nonce = "\(json["nonce"] ?? "")"
        let serviceToken = try await securityToken(location: location, nonce: nonce, ssecurity: ssecurity)
        return XiaomiServiceToken(ssecurity: ssecurity, serviceToken: serviceToken)
    }

    private func serviceLogin(sid: String, userId: String? = nil, passToken: String? = nil, deviceId: String? = nil) async throws -> [String: Any] {
        let url = URL(string: "\(XiaomiAPI.accountBase)/pass/serviceLogin?sid=\(sid)&_json=true")!
        var cookie = "sdkVersion=3.9; deviceId=\(deviceId ?? self.deviceId)"
        if let userId, let passToken, !userId.isEmpty, !passToken.isEmpty {
            cookie += "; userId=\(userId); passToken=\(passToken)"
        }
        return try await getJSON(url, headers: ["User-Agent": XiaomiAPI.uaLogin, "Cookie": cookie])
    }

    private func securityToken(location: String, nonce: String, ssecurity: String) async throws -> String {
        var urlString = location
        if !nonce.isEmpty, !ssecurity.isEmpty {
            let sign = XiaomiCrypto.clientSign(nonce: nonce, ssecurity: ssecurity)
            let join = location.contains("?") ? "&" : "?"
            urlString += "\(join)clientSign=\(sign.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? sign)"
        }
        guard let url = URL(string: urlString) else {
            throw XiaomiError.loginFailed("登录跳转地址无效")
        }
        var request = URLRequest(url: url)
        request.setValue(XiaomiAPI.uaLogin, forHTTPHeaderField: "User-Agent")
        let (_, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse,
           let fields = http.allHeaderFields as? [String: String],
           let responseURL = http.url {
            let found = HTTPCookie.cookies(withResponseHeaderFields: fields, for: responseURL)
            if let token = found.first(where: { $0.name == "serviceToken" })?.value {
                return token
            }
        }
        if let http = response as? HTTPURLResponse {
            let headers = headerStrings(http.allHeaderFields)
            if let setCookie = headers["Set-Cookie"] ?? headers["set-cookie"],
               let token = cookieValue(setCookie, name: "serviceToken") {
                return token
            }
        }
        throw XiaomiError.loginFailed("未能获取小米服务令牌")
    }

    private func verifyOTP(_ notice: String, otp: String, sid: String) async throws -> [String: Any] {
        var noticeURL = notice
        if !noticeURL.hasPrefix("http") { noticeURL = XiaomiAPI.accountBase + noticeURL }
        _ = try await getJSON(URL(string: noticeURL)!, headers: ["User-Agent": XiaomiAPI.uaLogin])
        let form = ["_flag": "4", "ticket": otp, "trust": "false", "_json": "true"]
        let verified = try await postForm("\(XiaomiAPI.accountBase)/identity/auth/verifyPhone", form: form)
        if let location = verified["location"] as? String {
            _ = try await session.data(from: URL(string: location.hasPrefix("http") ? location : XiaomiAPI.accountBase + location)!)
        }
        return try await serviceLogin(sid: sid)
    }

    private func getJSON(_ url: URL, headers: [String: String] = [:], cookies: String? = nil) async throws -> [String: Any] {
        var request = URLRequest(url: url)
        for (key, value) in headers { request.setValue(value, forHTTPHeaderField: key) }
        if let cookies { request.setValue(cookies, forHTTPHeaderField: "Cookie") }
        let (data, _) = try await session.data(for: request)
        if data.isEmpty { return [:] }
        return try XiaomiJSON.parse(data)
    }

    private func postForm(_ url: String, form: [String: String], headers: [String: String] = [:], cookies: String? = nil) async throws -> [String: Any] {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue(XiaomiAPI.uaLogin, forHTTPHeaderField: "User-Agent")
        for (key, value) in headers { request.setValue(value, forHTTPHeaderField: key) }
        if let cookies { request.setValue(cookies, forHTTPHeaderField: "Cookie") }
        let body = form.map { key, value in
            "\(key)=\(value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value)"
        }.joined(separator: "&")
        request.httpBody = Data(body.utf8)
        let (data, _) = try await session.data(for: request)
        if data.isEmpty { return [:] }
        if let object = try? XiaomiJSON.parse(data) { return object }
        return ["raw": String(data: data, encoding: .utf8) ?? ""]
    }

    private func minaHeaders() -> [String: String] {
        ["User-Agent": XiaomiAPI.uaMina]
    }

    private func minaCookies(_ token: XiaomiToken, _ mina: XiaomiServiceToken) -> String {
        "userId=\(token.userId); serviceToken=\(mina.serviceToken); deviceId=\(token.deviceId)"
    }

    private func jsonString(_ object: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: object),
              let text = String(data: data, encoding: .utf8) else { return "{}" }
        return text
    }

    private func headerStrings(_ fields: [AnyHashable: Any]) -> [String: String] {
        var out: [String: String] = [:]
        for (key, value) in fields {
            out[String(describing: key)] = String(describing: value)
        }
        return out
    }

    private func cookieValue(_ setCookie: String, name: String) -> String? {
        for part in setCookie.components(separatedBy: ",") {
            for piece in part.components(separatedBy: ";") {
                let kv = piece.split(separator: "=", maxSplits: 1).map(String.init)
                if kv.count == 2, kv[0].trimmingCharacters(in: .whitespaces) == name {
                    return kv[1].trimmingCharacters(in: .whitespaces)
                }
            }
        }
        return nil
    }
}

struct QRSession {
    var qrURL: String
    var loginURL: String
    var pollURL: String
    var timeout: Int
    var deviceId: String
}
