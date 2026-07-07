import SwiftUI

struct AIChatView: View {
    var title: String        = "KI-Assistent"
    var systemPrompt: String = AIPrompts.support

    @State private var messages: [ChatMessage] = []
    @State private var input = ""
    @State private var loading = false
    @Environment(\.dismiss) private var dismiss
    private let ai = AIService.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                chatList
                inputBar
            }
            .background(Color.appBackground)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }.foregroundColor(.appBlue)
                }
            }
        }
        .onAppear {
            messages = [ChatMessage(role: "assistant",
                                    content: "Hallo! Ich bin dein Naava Assistent 👋\nWie kann ich dir helfen?")]
        }
    }

    // MARK: - Chat list

    private var chatList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { m in
                        BubbleView(message: m).id(m.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: messages.count) { _, _ in
                withAnimation { proxy.scrollTo(messages.last?.id, anchor: .bottom) }
            }
        }
    }

    // MARK: - Input bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Frage stellen…", text: $input, axis: .vertical)
                .font(.system(size: 15))
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(20)

            Button(action: sendMessage) {
                let ready = !input.trimmingCharacters(in: .whitespaces).isEmpty && !loading
                Circle()
                    .fill(ready ? Color.appBlue : Color.appBlue.opacity(0.3))
                    .frame(width: 38, height: 38)
                    .overlay(
                        Image(systemName: loading ? "ellipsis" : "arrow.up")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
            .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty || loading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: -2))
    }

    // MARK: - Send

    private func sendMessage() {
        let text = input.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        messages.append(ChatMessage(role: "user", content: text))
        input = ""
        loading = true
        messages.append(ChatMessage(role: "assistant", content: "", isLoading: true))

        let history = Array(messages.dropLast(2))
        Task {
            do {
                let reply = try await ai.send(text, history: history, system: systemPrompt)
                messages.removeLast()
                messages.append(ChatMessage(role: "assistant", content: reply))
            } catch {
                messages.removeLast()
                messages.append(ChatMessage(role: "assistant",
                                            content: "⚠️ \(error.localizedDescription)"))
            }
            loading = false
        }
    }
}

// MARK: - Bubble

private struct BubbleView: View {
    let message: ChatMessage
    var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 50) }

            if !isUser {
                Circle()
                    .fill(Color.appBlue.opacity(0.12))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.appBlue)
                    )
            }

            Group {
                if message.isLoading {
                    TypingDots()
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(18)
                } else {
                    Text(message.content)
                        .font(.system(size: 14))
                        .foregroundColor(isUser ? .white : .appTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(isUser ? Color.appBlue : Color.white)
                        .cornerRadius(18)
                }
            }
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)

            if !isUser { Spacer(minLength: 50) }
        }
    }
}

// MARK: - Typing indicator

private struct TypingDots: View {
    @State private var on = false
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.appTextSecondary.opacity(0.4))
                    .frame(width: 7, height: 7)
                    .offset(y: on ? -4 : 0)
                    .animation(
                        .easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15),
                        value: on
                    )
            }
        }
        .onAppear { on = true }
    }
}

#Preview { AIChatView() }
