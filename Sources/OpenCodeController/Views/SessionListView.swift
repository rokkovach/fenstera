import SwiftUI

struct SessionListView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var isCreating = false
    @State private var showingSettings = false
    @State private var newSessionTitle = ""

    var body: some View {
        @Bindable var appVM = appVM

        NavigationStack {
            Group {
                if !appVM.isConnected {
                    ConnectionPlaceholder(appVM: appVM)
                } else {
                    sessionList
                }
            }
            .navigationTitle("Fenstera")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if appVM.isConnected {
                        Text("v\(appVM.serverVersion)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            isCreating = true
                        } label: {
                            Label("New Session", systemImage: "plus")
                        }
                        Button {
                            Task { await appVM.refreshSessions() }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        Divider()
                        Button {
                            showingSettings = true
                        } label: {
                            Label("Settings", systemImage: "gear")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    SettingsView()
                }
            }
            .sheet(isPresented: $isCreating) {
                newSessionSheet
            }
        }
    }

    var sessionList: some View {
        List {
            if appVM.sessions.isEmpty {
                ContentUnavailableView(
                    "No Sessions",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Create a new session to get started")
                )
            } else {
                ForEach(appVM.sessions) { session in
                    NavigationLink(destination: SessionChatView(session: session)) {
                        SessionRowView(
                            session: session,
                            status: appVM.status(for: session.id),
                            agentName: appVM.agentName(for: session.id)
                        )
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task {
                                guard let client = appVM.client else { return }
                                try? await client.deleteSession(session.id)
                                await appVM.refreshSessions()
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await appVM.refreshSessions()
        }
    }

    var newSessionSheet: some View {
        NavigationStack {
            Form {
                TextField("Title (optional)", text: $newSessionTitle)
            }
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isCreating = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            guard let client = appVM.client else { return }
                            try? await client.createSession(SessionCreateBody(title: newSessionTitle.isEmpty ? nil : newSessionTitle))
                            newSessionTitle = ""
                            isCreating = false
                            await appVM.refreshSessions()
                        }
                    }
                    .disabled(newSessionTitle.isEmpty && false)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct ConnectionPlaceholder: View {
    var appVM: AppViewModel

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "desktopcomputer")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Not Connected")
                .font(.title2.bold())
            if let error = appVM.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            Text("Go to Settings to configure your OpenCode server")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Open Settings") {
                // Handled by parent sheet
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

struct SessionRowView: View {
    let session: Session
    let status: String?
    let agentName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.title ?? "Untitled Session")
                .font(.body)
                .lineLimit(1)
            HStack(spacing: 8) {
                if let agentName {
                    Label(agentName, systemImage: "cpu")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if let status {
                    StatusBadge(status: status)
                }
                Spacer()
                if let updatedAt = session.updatedAt {
                    Text(timeAgo(updatedAt))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func timeAgo(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "\(Int(interval))s ago" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }
}

struct StatusBadge: View {
    let status: String

    var color: Color {
        switch status.lowercased() {
        case "idle": .green
        case "running", "active": .blue
        case "error": .red
        default: .secondary
        }
    }

    var label: String {
        switch status.lowercased() {
        case "idle": "Idle"
        case "running", "active": "Running"
        case "error": "Error"
        default: status
        }
    }

    var body: some View {
        Text(label)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
