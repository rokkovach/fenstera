import SwiftUI

@main
struct OpenCodeControllerApp: App {
    @State private var appViewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            SessionListView()
                .environment(appViewModel)
        }
    }
}
