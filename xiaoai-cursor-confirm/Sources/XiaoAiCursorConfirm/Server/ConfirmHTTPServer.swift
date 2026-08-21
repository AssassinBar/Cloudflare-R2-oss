import Foundation
import Network

final class ConfirmHTTPServer: @unchecked Sendable {
    weak var center: ConfirmCenter?
    private var listener: NWListener?
    private let queue = DispatchQueue(label: "cn.xiaoai.cursor.http")

    func start(port: UInt16) throws {
        stop()
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true
        params.requiredInterfaceType = .loopback
        let listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!)
        listener.newConnectionHandler = { [weak self] connection in
            self?.handle(connection)
        }
        listener.start(queue: queue)
        self.listener = listener
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }

    private func handle(_ connection: NWConnection) {
        connection.start(queue: queue)
        receive(on: connection, buffer: Data())
    }

    private func receive(on connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            if let error {
                connection.cancel()
                NSLog("http receive: \(error.localizedDescription)")
                return
            }
            var buffer = buffer
            if let data { buffer.append(data) }
            if let request = HTTPMessage.parse(buffer) {
                self.dispatch(request, on: connection)
                return
            }
            if isComplete {
                connection.cancel()
                return
            }
            self.receive(on: connection, buffer: buffer)
        }
    }

    private func dispatch(_ message: HTTPMessage, on connection: NWConnection) {
        let cors = [
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type"
        ]
        if message.method == "OPTIONS" {
            reply(on: connection, status: 204, headers: cors, body: Data())
            return
        }

        Task { @MainActor in
            let response: HTTPMessage
            switch (message.method, message.path) {
            case ("GET", "/"), ("GET", "/v1/health"):
                response = HTTPMessage.json(self.center?.health() ?? HealthPayload(
                    ok: false, app: "XiaoAiCursorConfirm", version: "1.0.0", port: 0,
                    phase: .idle, pending: 0, cursorRunning: false,
                    microphone: "unknown", speech: "unknown", voices: []
                ), extra: cors)
            case ("GET", "/v1/status"):
                let payload: [String: String] = [
                    "phase": self.center?.phase.rawValue ?? "idle",
                    "pending": String(self.center?.pendingCount ?? 0),
                    "transcript": self.center?.transcript ?? ""
                ]
                response = HTTPMessage.json(payload, extra: cors)
            case ("POST", "/v1/confirm"):
                do {
                    var request = try message.decode(ConfirmRequest.self)
                    if request.id.isEmpty { request.id = UUID().uuidString }
                    let result = await self.center?.submit(request) ?? ConfirmResponse(
                        id: request.id, decision: .timeout, via: .system,
                        transcript: "", durationMs: 0, spoken: false
                    )
                    response = HTTPMessage.json(result, extra: cors)
                } catch {
                    response = HTTPMessage.error(400, error.localizedDescription, extra: cors)
                }
            case ("POST", "/v1/speak"):
                do {
                    let body = try message.decode(SpeakBody.self)
                    self.center?.phase = .speaking
                    ConfirmHUDController.shared.show(center: self.center ?? .shared)
                    await self.center?.announce(body.text)
                    self.center?.phase = .idle
                    ConfirmHUDController.shared.hide()
                    response = HTTPMessage.json(OkFlag(ok: true), extra: cors)
                } catch {
                    response = HTTPMessage.error(400, error.localizedDescription, extra: cors)
                }
            case ("POST", "/v1/test/scenario"):
                do {
                    let body = try message.decode(ScenarioBody.self)
                    guard let scenario = TestScenario(rawValue: body.scenario) else {
                        response = HTTPMessage.error(400, "unknown scenario", extra: cors)
                        break
                    }
                    await self.center?.runScenario(scenario)
                    response = HTTPMessage.json(ScenarioResult(ok: true, scenario: scenario.rawValue), extra: cors)
                } catch {
                    response = HTTPMessage.error(400, error.localizedDescription, extra: cors)
                }
            case ("POST", "/v1/decision"):
                do {
                    let body = try message.decode(DecisionBody.self)
                    self.center?.decide(body.decision, via: .test, transcript: body.transcript ?? "")
                    response = HTTPMessage.json(OkFlag(ok: true), extra: cors)
                } catch {
                    response = HTTPMessage.error(400, error.localizedDescription, extra: cors)
                }
            case ("GET", "/v1/xiaomi/status"):
                response = HTTPMessage.json(XiaomiCloud.shared.snapshot(), extra: cors)
            case ("POST", "/v1/xiaomi/qr/start"):
                XiaomiCloud.shared.startQRLogin()
                response = HTTPMessage.json(OkFlag(ok: true), extra: cors)
            case ("POST", "/v1/xiaomi/qr/cancel"):
                XiaomiCloud.shared.cancelQR()
                response = HTTPMessage.json(OkFlag(ok: true), extra: cors)
            case ("POST", "/v1/xiaomi/login"):
                do {
                    let body = try message.decode(XiaomiLoginBody.self)
                    await XiaomiCloud.shared.login(user: body.user, password: body.password, otp: body.otp)
                    response = HTTPMessage.json(XiaomiCloud.shared.snapshot(), extra: cors)
                } catch {
                    response = HTTPMessage.error(400, error.localizedDescription, extra: cors)
                }
            case ("POST", "/v1/xiaomi/logout"):
                XiaomiCloud.shared.logout()
                response = HTTPMessage.json(OkFlag(ok: true), extra: cors)
            case ("GET", "/v1/xiaomi/speakers"):
                await XiaomiCloud.shared.refreshSpeakers()
                response = HTTPMessage.json(XiaomiCloud.shared.snapshot(), extra: cors)
            case ("POST", "/v1/xiaomi/speaker"):
                do {
                    let body = try message.decode(SpeakerPickBody.self)
                    AppSettings.shared.selectedSpeakerId = body.deviceId
                    response = HTTPMessage.json(XiaomiCloud.shared.snapshot(), extra: cors)
                } catch {
                    response = HTTPMessage.error(400, error.localizedDescription, extra: cors)
                }
            case ("POST", "/v1/xiaomi/tts"):
                do {
                    let body = try message.decode(SpeakBody.self)
                    try await XiaomiCloud.shared.announce(body.text)
                    response = HTTPMessage.json(OkFlag(ok: true), extra: cors)
                } catch {
                    response = HTTPMessage.error(400, error.localizedDescription, extra: cors)
                }
            default:
                response = HTTPMessage.error(404, "not found", extra: cors)
            }
            self.reply(on: connection, status: response.status, headers: response.headers, body: response.body)
        }
    }

    private func reply(on connection: NWConnection, status: Int, headers: [String: String], body: Data) {
        var headerLines = [
            "HTTP/1.1 \(status) \(HTTPMessage.statusText(status))",
            "Content-Length: \(body.count)",
            "Connection: close"
        ]
        for (key, value) in headers {
            headerLines.append("\(key): \(value)")
        }
        var data = (headerLines.joined(separator: "\r\n") + "\r\n\r\n").data(using: .utf8) ?? Data()
        data.append(body)
        connection.send(content: data, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}

struct HTTPMessage {
    var method: String
    var path: String
    var headers: [String: String]
    var body: Data
    var status: Int = 200

    static func parse(_ data: Data) -> HTTPMessage? {
        guard let range = data.range(of: Data("\r\n\r\n".utf8)) else { return nil }
        let head = data.subdata(in: data.startIndex..<range.lowerBound)
        guard let headText = String(data: head, encoding: .utf8) else { return nil }
        let lines = headText.split(separator: "\r\n", omittingEmptySubsequences: false)
        guard let requestLine = lines.first else { return nil }
        let parts = requestLine.split(separator: " ")
        guard parts.count >= 2 else { return nil }
        var headers: [String: String] = [:]
        for line in lines.dropFirst() {
            guard let idx = line.firstIndex(of: ":") else { continue }
            let key = line[..<idx].trimmingCharacters(in: .whitespaces)
            let value = line[line.index(after: idx)...].trimmingCharacters(in: .whitespaces)
            headers[key.lowercased()] = value
        }
        let bodyStart = range.upperBound
        let length = Int(headers["content-length"] ?? "0") ?? 0
        let available = data.count - bodyStart
        guard available >= length else { return nil }
        let body = data.subdata(in: bodyStart..<(bodyStart + length))
        let path = String(parts[1]).split(separator: "?").first.map(String.init) ?? String(parts[1])
        return HTTPMessage(method: String(parts[0]), path: path, headers: headers, body: body)
    }

    static func json<T: Encodable>(_ value: T, extra: [String: String] = [:], status: Int = 200) -> HTTPMessage {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let body = (try? encoder.encode(value)) ?? Data("{}".utf8)
        var headers = extra
        headers["Content-Type"] = "application/json; charset=utf-8"
        return HTTPMessage(method: "HTTP", path: "", headers: headers, body: body, status: status)
    }

    static func error(_ status: Int, _ message: String, extra: [String: String] = [:]) -> HTTPMessage {
        json(["error": message], extra: extra, status: status)
    }

    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: body)
    }

    static func statusText(_ status: Int) -> String {
        switch status {
        case 200: return "OK"
        case 204: return "No Content"
        case 400: return "Bad Request"
        case 404: return "Not Found"
        default: return "Error"
        }
    }
}

private struct SpeakBody: Codable { var text: String }
private struct OkFlag: Codable { var ok: Bool }
private struct ScenarioBody: Codable { var scenario: String }
private struct ScenarioResult: Codable { var ok: Bool; var scenario: String }
private struct DecisionBody: Codable {
    var decision: ConfirmDecision
    var transcript: String?
}
private struct XiaomiLoginBody: Codable {
    var user: String
    var password: String
    var otp: String?
}
private struct SpeakerPickBody: Codable {
    var deviceId: String
}
