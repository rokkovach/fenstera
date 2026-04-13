import SwiftUI

@Observable
final class SettingsViewModel {
    var serverURL = ""
    var username = ""
    var password = ""

    @MainActor
    func load() async {
        serverURL = (await KeychainService.shared.get(.serverURL)) ?? "http://localhost:4096"
        username = (await KeychainService.shared.get(.username)) ?? ""
        password = ""
    }

    @MainActor
    func save() async -> String? {
        guard !serverURL.isEmpty else {
            return "Server URL is required"
        }

        guard let url = URL(string: serverURL) else {
            return "Invalid URL"
        }

        await KeychainService.shared.set(url.absoluteString, for: .serverURL)

        if !username.isEmpty {
            await KeychainService.shared.set(username, for: .username)
        } else {
            await KeychainService.shared.delete(.username)
        }

        if !password.isEmpty {
            await KeychainService.shared.set(password, for: .password)
        } else {
            await KeychainService.shared.delete(.password)
        }

        return nil
    }

    @MainActor
    func clearAll() async {
        await KeychainService.shared.deleteAll()
        serverURL = "http://localhost:4096"
        username = ""
        password = ""
    }
}
