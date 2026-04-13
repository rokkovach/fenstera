import Foundation

final class OpenCodeClient: Sendable {
    let baseURL: URL
    private let session: URLSession
    private let credentials: (username: String, password: String)?

    init(baseURL: URL, username: String? = nil, password: String? = nil) {
        self.baseURL = baseURL
        self.session = URLSession.shared
        if let username, let password {
            self.credentials = (username, password)
        } else {
            self.credentials = nil
        }
    }

    private func request(
        _ path: String,
        method: String = "GET",
        body: Encodable? = nil,
        query: [String: String]? = nil
    ) async throws -> Data {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        if let query {
            components?.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components?.url else {
            throw OpenCodeError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        if let credentials {
            let auth = Data("\(credentials.username):\(credentials.password)".utf8).base64EncodedString()
            request.setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenCodeError.connectionFailed("Invalid response")
        }

        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 401:
            throw OpenCodeError.unauthorized
        case 404:
            throw OpenCodeError.notFound
        default:
            if let message = String(data: data, encoding: .utf8) {
                throw OpenCodeError.serverError(message)
            }
            throw OpenCodeError.serverError("HTTP \(httpResponse.statusCode)")
        }
    }

    private func decode<T: Decodable>(_ path: String, method: String = "GET", body: Encodable? = nil, query: [String: String]? = nil) async throws -> T {
        let data = try await request(path, method: method, body: body, query: query)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw OpenCodeError.decodingError
        }
    }

    private func post(_ path: String, body: Encodable? = nil) async throws -> Data {
        try await request(path, method: "POST", body: body)
    }

    func health() async throws -> HealthResponse {
        try await decode("/global/health")
    }

    func listSessions() async throws -> [Session] {
        try await decode("/session")
    }

    func createSession(_ body: SessionCreateBody = SessionCreateBody()) async throws -> Session {
        try await decode("/session", method: "POST", body: body)
    }

    func getSession(_ id: String) async throws -> Session {
        try await decode("/session/\(id)")
    }

    func deleteSession(_ id: String) async throws -> Bool {
        let data = try await request("/session/\(id)", method: "DELETE")
        return (try? JSONDecoder().decode(Bool.self, from: data)) ?? true
    }

    func updateSession(_ id: String, body: SessionUpdateBody) async throws -> Session {
        try await decode("/session/\(id)", method: "PATCH", body: body)
    }

    func getSessionStatuses() async throws -> SessionStatusMap {
        try await decode("/session/status")
    }

    func getMessages(sessionID: String, limit: Int? = nil) async throws -> [MessagePart] {
        var query: [String: String]? = nil
        if let limit {
            query = ["limit": "\(limit)"]
        }
        return try await decode("/session/\(sessionID)/message", query: query)
    }

    func sendPrompt(sessionID: String, body: PromptRequestBody) async throws -> MessagePart {
        try await decode("/session/\(sessionID)/message", method: "POST", body: body)
    }

    func sendPromptAsync(sessionID: String, body: PromptRequestBody) async throws {
        _ = try await post("/session/\(sessionID)/prompt_async", body: body)
    }

    func abortSession(_ id: String) async throws -> Bool {
        let data = try await post("/session/\(id)/abort")
        return (try? JSONDecoder().decode(Bool.self, from: data)) ?? true
    }

    func listAgents() async throws -> [Agent] {
        try await decode("/agent")
    }

    func getConfig() async throws -> Config {
        try await decode("/config")
    }

    func listCommands() async throws -> [Command] {
        try await decode("/command")
    }
}
