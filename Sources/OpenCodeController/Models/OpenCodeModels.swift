import Foundation

struct Session: Identifiable, Codable, Sendable, Hashable {
    let id: String
    var title: String?
    let createdAt: String?
    let updatedAt: String?
    var parentID: String?
    var share: Share?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Session, rhs: Session) -> Bool {
        lhs.id == rhs.id
    }
}

struct Share: Codable, Sendable {
    let id: String?
    let slug: String?
    let error: String?
}

struct SessionStatus: Codable, Sendable {
    let status: String?
    let agent: String?
}

struct SessionStatusMap: Codable, Sendable {
    let values: [String: SessionStatus]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        values = try container.decode([String: SessionStatus].self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(values)
    }
}

struct MessageInfo: Codable, Sendable {
    let id: String
    let sessionID: String?
    let role: String
    let agent: String?
    let model: String?
    let createdAt: String?
    var structuredOutput: [String: JSONValue]?
    var error: SessionError?
}

struct SessionError: Codable, Sendable {
    let name: String?
    let message: String?
    let retries: Int?
}

struct Part: Identifiable, Codable, Sendable {
    let id: String
    let type: String
    var text: String?
    var tool: String?
    var args: [String: JSONValue]?
    var output: JSONValue?
    var error: String?
    var filePath: String?
    var content: String?
    var patch: String?
    var command: String?

    enum CodingKeys: String, CodingKey {
        case id, type, text, tool, args, output, error, content, patch, command
        case filePath = "file_path"
    }
}

enum JSONValue: Codable, Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null
    case array([JSONValue])
    case object([String: JSONValue])

    var stringValue: String? {
        if case .string(let v) = self { return v }
        return nil
    }

    var arrayValue: [JSONValue]? {
        if case .array(let v) = self { return v }
        return nil
    }

    var objectValue: [String: JSONValue]? {
        if case .object(let v) = self { return v }
        return nil
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let v = try? container.decode(String.self) {
            self = .string(v)
        } else if let v = try? container.decode(Int.self) {
            self = .int(v)
        } else if let v = try? container.decode(Double.self) {
            self = .double(v)
        } else if let v = try? container.decode(Bool.self) {
            self = .bool(v)
        } else if let v = try? container.decode([JSONValue].self) {
            self = .array(v)
        } else if let v = try? container.decode([String: JSONValue].self) {
            self = .object(v)
        } else {
            self = .null
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case .string(let v): try container.encode(v)
        case .int(let v): try container.encode(v)
        case .double(let v): try container.encode(v)
        case .bool(let v): try container.encode(v)
        case .array(let v): try container.encode(v)
        case .object(let v): try container.encode(v)
        }
    }
}

struct MessagePart: Identifiable, Codable, Sendable {
    let info: MessageInfo
    let parts: [Part]

    var id: String { info.id }
}

struct Agent: Identifiable, Codable, Sendable {
    let id: String
    let name: String?
    let description: String?
    let tools: [String]?
}

struct Project: Identifiable, Codable, Sendable {
    let id: String
    let path: String?
    let name: String?
}

struct Config: Codable, Sendable {
    let model: String?
    let provider: String?
    let agent: String?
}

struct Provider: Identifiable, Codable, Sendable {
    let id: String
    let name: String?
}

struct ConfigProviders: Codable, Sendable {
    let providers: [Provider]
    let `default`: [String: String]
}

struct HealthResponse: Codable, Sendable {
    let healthy: Bool
    let version: String
}

struct Command: Identifiable, Codable, Sendable {
    let id: String
    let name: String?
    let description: String?
}

struct TodoItem: Identifiable, Codable, Sendable {
    let id: String
    let content: String?
    let status: String?
    let priority: String?
}

struct FileDiff: Identifiable, Codable, Sendable {
    let id: String
    let path: String?
    let old: String?
    let new: String?
}

struct VcsInfo: Codable, Sendable {
    let branch: String?
    let commit: String?
    let remote: String?
    let dirty: Bool?
}

struct PathInfo: Codable, Sendable {
    let path: String?
    let worktree: String?
}

struct PromptRequestBody: Codable, Sendable {
    var messageID: String?
    var model: ModelSelection?
    var agent: String?
    var noReply: Bool?
    var system: String?
    var tools: [String]?
    var parts: [PromptPart]?

    struct ModelSelection: Codable, Sendable {
        let providerID: String
        let modelID: String
    }

    struct PromptPart: Codable, Sendable {
        let type: String
        let text: String?
        let filePath: String?
        let content: String?

        enum CodingKeys: String, CodingKey {
            case type, text, content
            case filePath = "file_path"
        }
    }
}

struct SessionCreateBody: Codable, Sendable {
    var parentID: String?
    var title: String?
}

struct SessionUpdateBody: Codable, Sendable {
    var title: String?
}

struct SSEEvent: Sendable {
    let type: String
    let properties: [String: JSONValue]?
}
