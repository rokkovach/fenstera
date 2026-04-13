import SwiftUI

struct SessionChatView: View {
    let session: Session
    @Environment(AppViewModel.self) private var appVM
    @State private var viewModel: SessionChatViewModel?
    @FocusState private var isInputFocused: Bool

    var body: some View {
        Group {
            if let viewModel {
                chatContent(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .task {
            let vm = SessionChatViewModel(session: session, appVM: appVM)
            viewModel = vm
            await vm.loadMessages()
        }
        .navigationTitle(session.title ?? "Session")
        .navigationBarTitleDisplayMode(.inline)
    }

    func chatContent(viewModel: SessionChatViewModel) -> some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { messagePart in
                            MessageBubbleView(message: messagePart)
                                .id(messagePart.id)
                        }

                        if viewModel.isLoading {
                            HStack {
                                ProgressView()
                                    .padding(.leading, 4)
                                Text("Thinking...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) {
                    if let lastID = viewModel.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastID, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            inputBar(viewModel: viewModel)
        }
    }

    func inputBar(viewModel: SessionChatViewModel) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Send a prompt...", text: $viewModel.inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .lineLimit(1...6)
                .focused($isInputFocused)

            Button {
                Task { await viewModel.sendPrompt() }
            } label: {
                Image(systemName: viewModel.isLoading ? "stop.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .accentColor)
            }
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isLoading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

struct MessageBubbleView: View {
    let message: MessagePart

    var isUser: Bool {
        message.info.role == "user"
    }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 48) }

            VStack(alignment: .leading, spacing: 4) {
                header
                ForEach(message.parts) { part in
                    PartView(part: part)
                }
            }
            .padding(12)
            .background(isUser ? Color.accentColor.opacity(0.1) : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if !isUser { Spacer(minLength: 48) }
        }
    }

    var header: some View {
        HStack(spacing: 6) {
            if isUser {
                Image(systemName: "person.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "cpu")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(message.info.agent ?? message.info.role.capitalized)
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
            if let model = message.info.model {
                Text(model)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

struct PartView: View {
    let part: Part

    var body: some View {
        switch part.type {
        case "text":
            if let text = part.text {
                Text(text)
                    .font(.body)
                    .textSelection(.enabled)
            }
        case "tool-invocation":
            ToolInvocationView(part: part)
        case "tool-result":
            ToolResultView(part: part)
        case "thinking":
            if let text = part.text, !text.isEmpty {
                HStack {
                    Image(systemName: "brain")
                        .foregroundStyle(.secondary)
                    Text(text)
                        .font(.caption)
                        .italic()
                        .foregroundStyle(.secondary)
                }
            }
        default:
            if let text = part.text {
                Text(text)
                    .font(.body)
            }
        }
    }
}

struct ToolInvocationView: View {
    let part: Part

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(part.tool ?? "tool")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            if let filePath = part.filePath {
                Label(filePath, systemImage: "doc")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let command = part.command {
                Text(command)
                    .font(.system(.caption, design: .monospaced))
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ToolResultView: View {
    let part: Part

    private var isError: Bool {
        part.error != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let error = part.error {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.red)
            } else if let text = part.output?.stringValue {
                Text(text)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(20)
            }
        }
        .padding(6)
        .background(isError ? Color.red.opacity(0.08) : Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
