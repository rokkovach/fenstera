import Foundation

actor EventStream: AsyncSequence {
    typealias AsyncIterator = Stream

    let baseURL: URL
    private let credentials: (username: String, password: String)?
    private let streamContinuation: AsyncStream<StreamEvent>.Continuation

    init(baseURL: URL, username: String? = nil, password: String? = nil) {
        self.baseURL = baseURL
        self.credentials = username != nil && password != nil ? (username!, password!) : nil
        var continuation: AsyncStream<StreamEvent>.Continuation?
        self.streamContinuation = UnsafeContinuation { _ in }
        _ = AsyncStream<StreamEvent> { continuation = $0 }
        self.streamContinuation = continuation!
    }

    struct StreamEvent: Sendable {
        let type: String
        let data: String?
    }

    struct StreamIterator: AsyncIteratorProtocol {
        let urlRequest: URLRequest
        let continuation: AsyncStream<StreamEvent>.Continuation
        private var task: Task<Void, Never>?

        mutating func next() async -> StreamEvent? {
            await withTaskCancellationHandler {
                await withCheckedContinuation { continuation in
                    let stream = AsyncStream<StreamEvent> { streamContinuation in
                        let task = Task {
                            do {
                                let (bytes, response) = try await URLSession.shared.bytes(for: self.urlRequest)
                                guard let httpResponse = response as? HTTPURLResponse,
                                      httpResponse.statusCode == 200 else {
                                    streamContinuation.finish()
                                    return
                                }

                                var eventType = ""
                                var eventData = ""
                                let colonSpace = ": ".data(using: .utf8)!
                                let newline = "\n".data(using: .utf8)!

                                for try await line in bytes.lines {
                                    if line.hasPrefix("event:") {
                                        eventType = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                                    } else if line.hasPrefix("data:") {
                                        let remaining = String(line.dropFirst(5))
                                        if remaining.hasPrefix(" ") {
                                            eventData += remaining.dropFirst(1)
                                        } else {
                                            eventData += remaining
                                        }
                                    } else if line.isEmpty && !eventType.isEmpty {
                                        streamContinuation.yield(StreamEvent(type: eventType, data: eventData.isEmpty ? nil : eventData))
                                        eventType = ""
                                        eventData = ""
                                    }
                                }

                                streamContinuation.finish()
                            } catch {
                                streamContinuation.finish()
                            }
                        }
                        self.task = task
                    }

                    var iterator = stream.makeAsyncIterator()
                    Task {
                        if let next = await iterator.next() {
                            continuation.resume(returning: next)
                        } else {
                            continuation.resume(returning: nil)
                        }
                    }
                }
            } onCancel: {
                task?.cancel()
            }
        }
    }

    func makeAsyncIterator() -> StreamIterator {
        var request = URLRequest(url: baseURL.appendingPathComponent("/event"))
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.timeoutInterval = .infinity

        if let credentials {
            let auth = Data("\(credentials.username):\(credentials.password)".utf8).base64EncodedString()
            request.setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")
        }

        let (stream, continuation) = AsyncStream<StreamEvent>.makeStream()
        return StreamIterator(urlRequest: request, continuation: continuation)
    }
}

final class EventStreamManager: ObservableObject, Sendable {
    @MainActor @Published private(set) var latestEvent: SSEEvent?
    @MainActor @Published private(set) var isConnected = false
    @MainActor @Published private(set) var sessionStatuses: [String: SessionStatus] = [:]

    private var streamTask: Task<Void, Never>?
    let onEvent: @Sendable (SSEEvent) -> Void

    init(onEvent: @escaping @Sendable (SSEEvent) -> Void) {
        self.onEvent = onEvent
    }

    func connect(baseURL: URL, username: String? = nil, password: String? = nil) {
        stop()

        streamTask = Task { [onEvent] in
            await MainActor.run { self.isConnected = true }

            do {
                let url = baseURL.appendingPathComponent("/event")
                var request = URLRequest(url: url)
                request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                request.timeoutInterval = .infinity

                if let username, let password {
                    let auth = Data("\(username):\(password)".utf8).base64EncodedString()
                    request.setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")
                }

                let (bytes, response) = try await URLSession.shared.bytes(for: request)

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    await MainActor.run { self.isConnected = false }
                    return
                }

                var eventType = ""
                var eventData = ""

                for try await line in bytes.lines {
                    if Task.isCancelled { break }

                    if line.hasPrefix("event:") {
                        eventType = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                    } else if line.hasPrefix("data:") {
                        let remaining = String(line.dropFirst(5))
                        eventData += remaining.hasPrefix(" ") ? String(remaining.dropFirst(1)) : remaining
                    } else if line.isEmpty && !eventType.isEmpty {
                        let event = SSEEvent(type: eventType, data: eventData.isEmpty ? nil : eventData)
                        onEvent(event)

                        await MainActor.run {
                            self.latestEvent = event
                            if event.type == "session.status", let data = event.data,
                               let jsonData = data.data(using: .utf8) {
                                if let decoded = try? JSONDecoder().decode([String: SessionStatus].self, from: jsonData) {
                                    self.sessionStatuses = decoded
                                }
                            }
                        }

                        eventType = ""
                        eventData = ""
                    }
                }
            } catch {
                await MainActor.run { self.isConnected = false }
            }

            await MainActor.run { self.isConnected = false }
        }
    }

    func stop() {
        streamTask?.cancel()
        streamTask = nil
        Task { @MainActor in
            isConnected = false
        }
    }

    deinit {
        stop()
    }
}
