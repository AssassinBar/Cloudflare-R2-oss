import Foundation

/// Central place to switch between mock and real backends.
enum AppEnvironment {
    case mock
    case remote(baseURL: URL)

    static var current: AppEnvironment = .mock
}

enum APIError: LocalizedError, Equatable {
    case invalidURL
    case unauthorized
    case notFound
    case server(status: Int, message: String)
    case decoding(String)
    case network(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的请求地址"
        case .unauthorized:
            return "未授权，请重新登录"
        case .notFound:
            return "资源不存在"
        case .server(_, let message):
            return message
        case .decoding(let message):
            return "数据解析失败：\(message)"
        case .network(let message):
            return message
        case .cancelled:
            return "请求已取消"
        }
    }
}

protocol APIRequest {
    associatedtype Response: Decodable
    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem] { get }
    var body: Encodable? { get }
}

extension APIRequest {
    var method: HTTPMethod { .get }
    var queryItems: [URLQueryItem] { [] }
    var body: Encodable? { nil }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// Thin HTTP client. Replace auth header injection when integrating real APIs.
final class APIClient: @unchecked Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let lock = NSLock()
    private var authToken: String?

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder = encoder
    }

    func setAuthToken(_ token: String?) {
        lock.lock()
        authToken = token
        lock.unlock()
    }

    func send<R: APIRequest>(_ request: R) async throws -> R.Response {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(request.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw APIError.invalidURL
        }

        if !request.queryItems.isEmpty {
            components.queryItems = request.queryItems
        }

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        lock.lock()
        let token = authToken
        lock.unlock()

        if let token {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = request.body {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                urlRequest.httpBody = try encoder.encode(AnyEncodable(body))
            } catch {
                throw APIError.decoding(error.localizedDescription)
            }
        }

        do {
            let (data, response) = try await session.data(for: urlRequest)
            guard let http = response as? HTTPURLResponse else {
                throw APIError.network("无效的服务器响应")
            }

            switch http.statusCode {
            case 200...299:
                do {
                    return try decoder.decode(R.Response.self, from: data)
                } catch {
                    throw APIError.decoding(error.localizedDescription)
                }
            case 401:
                throw APIError.unauthorized
            case 404:
                throw APIError.notFound
            default:
                if let apiError = try? decoder.decode(APIErrorResponse.self, from: data) {
                    throw APIError.server(status: http.statusCode, message: apiError.message)
                }
                throw APIError.server(status: http.statusCode, message: "服务器错误 (\(http.statusCode))")
            }
        } catch let error as APIError {
            throw error
        } catch is CancellationError {
            throw APIError.cancelled
        } catch {
            throw APIError.network(error.localizedDescription)
        }
    }
}

private struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void

    init(_ value: Encodable) {
        encodeFunc = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeFunc(encoder)
    }
}
