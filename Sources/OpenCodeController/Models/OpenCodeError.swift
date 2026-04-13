import Foundation

enum OpenCodeError: LocalizedError, Sendable {
    case connectionFailed(String)
    case unauthorized
    case notFound
    case serverError(String)
    case decodingError
    case invalidURL
    case noServer

    var errorDescription: String? {
        switch self {
        case .connectionFailed(let message):
            "Connection failed: \(message)"
        case .unauthorized:
            "Unauthorized — check your credentials"
        case .notFound:
            "Resource not found"
        case .serverError(let message):
            "Server error: \(message)"
        case .decodingError:
            "Failed to decode server response"
        case .invalidURL:
            "Invalid server URL"
        case .noServer:
            "No server configured. Go to Settings to connect."
        }
    }
}
