import SwiftUI

@Observable
final class AppViewModel {
    var client: OpenCodeClient?
    var eventManager: EventStreamManager?
    var isConnected = false
    var serverVersion = ""
    var error: String?

    private(set) var sessions: [Session] = []
    private(set) var sessionStatuses: [String: SessionStatus] = [:]
    private(set) var agents: [Agent] = []

    init() {
        Task {
            if await KeychainService.shared.get(.serverURL) != nil {
                await connect()
            }
        }
    }

    @MainActor
    func connect() async {
        guard let urlString = await KeychainService.shared.get(.serverURL),
              let url = URL(string: urlString) else {
            error = "No server URL configured"
            return
        }

        let username = await KeychainService.shared.get(.username)
        let password = await KeychainService.shared.get(.password)

        client = OpenCodeClient(baseURL: url, username: username, password: password)

        do {
            let health = try await client!.health()
            serverVersion = health.version
            isConnected = true
            error = nil

            eventManager = EventStreamManager { [weak self] event in
                Task { @MainActor in
                    self?.handleEvent(event)
                }
            }
            eventManager?.connect(baseURL: url, username: username, password: password)

            await refreshSessions()
            agents = (try? await client!.listAgents()) ?? []
        } catch {
            isConnected = false
            self.error = error.localizedDescription
        }
    }

    @MainActor
    func disconnect() {
        client = nil
        eventManager?.stop()
        eventManager = nil
        isConnected = false
        sessions = []
        sessionStatuses = [:]
        agents = []
        serverVersion = ""
    }

    @MainActor
    private func handleEvent(_ event: SSEEvent) {
        switch event.type {
        case "session.created", "session.updated", "session.deleted", "session.idle", "session.status":
            Task {
                await refreshSessions()
            }
        case "message.updated", "message.part.updated":
            break
        default:
            break
        }
    }

    @MainActor
    func refreshSessions() async {
        guard let client else { return }
        do {
            sessions = try await client.listSessions()
            let statuses = try await client.getSessionStatuses()
            sessionStatuses = statuses.values
        } catch {
        }
    }

    func status(for sessionID: String) -> String? {
        sessionStatuses[sessionID]?.status
    }

    func agentName(for sessionID: String) -> String? {
        sessionStatuses[sessionID]?.agent
    }
}
