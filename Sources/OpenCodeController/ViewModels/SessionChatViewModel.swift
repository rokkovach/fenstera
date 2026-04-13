import SwiftUI

@Observable
final class SessionChatViewModel {
    let session: Session
    var messages: [MessagePart] = []
    var inputText = ""
    var isLoading = false
    var error: String?
    private(set) var selectedAgent: String?

    private let appVM: AppViewModel

    init(session: Session, appVM: AppViewModel) {
        self.session = session
        self.appVM = appVM
        self.selectedAgent = appVM.agents.first?.id
    }

    @MainActor
    func loadMessages() async {
        guard let client = appVM.client else { return }
        do {
            messages = try await client.getMessages(sessionID: session.id)
        } catch {
            self.error = error.localizedDescription
        }
    }

    @MainActor
    func sendPrompt() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let client = appVM.client else { return }

        inputText = ""
        isLoading = true
        error = nil

        let body = PromptRequestBody(
            parts: [PromptRequestBody.PromptPart(type: "text", text: text)]
        )

        do {
            let response = try await client.sendPrompt(sessionID: session.id, body: body)
            messages.append(response)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    @MainActor
    func abort() async {
        guard let client = appVM.client else { return }
        isLoading = false
        try? await client.abortSession(session.id)
    }

    @MainActor
    func deleteSession() async {
        guard let client = appVM.client else { return }
        try? await client.deleteSession(session.id)
    }
}
