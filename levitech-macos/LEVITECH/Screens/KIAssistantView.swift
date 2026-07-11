//
//  KIAssistantView.swift  (10 KI Assistent)
//

import SwiftUI

struct KIAssistantView: View {
    @EnvironmentObject var store: Store
    @State private var input = ""

    var body: some View {
        VStack(spacing: 0) {
            // Titel
            HStack(spacing: 8) {
                Text("LEVITECH KI").font(.system(size: 24, weight: .heavy)).tracking(1).foregroundColor(Theme.text)
                Text("Beta").font(.system(size: 11, weight: .bold)).foregroundColor(Theme.red2)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Theme.surface3).clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 20).padding(.bottom, 8)

            if store.chat.isEmpty {
                intro
            } else {
                chatList
            }

            inputBar
        }
        .padding(.bottom, 78)
    }

    // Startzustand mit Bot + Vorschlägen
    private var intro: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                BotView(size: 140).padding(.vertical, 6)

                (Text("Hallo ") + Text(Sample.userFirst).foregroundColor(Theme.red2) + Text(",\nwie kann ich dir heute helfen?"))
                    .font(.system(size: 18, weight: .bold)).foregroundColor(Theme.text)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 18)

                VStack(spacing: 10) {
                    ForEach(Sample.kiSuggestions, id: \.self) { q in
                        Button { store.kiSend(q) } label: {
                            HStack {
                                Text(q).font(.system(size: 14, weight: .semibold)).foregroundColor(Theme.text)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Image(systemName: "chevron.right").font(.system(size: 13)).foregroundColor(Theme.red2)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 14)
                            .background(Theme.surface)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }.buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
    }

    // Chatverlauf
    private var chatList: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(store.chat) { m in
                        MessageBubble(message: m).id(m.id)
                    }
                }
                .padding(.horizontal, 18).padding(.vertical, 8)
            }
            .onChange(of: store.chat.count) { _ in
                if let last = store.chat.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
            }
        }
    }

    // Eingabezeile
    private var inputBar: some View {
        HStack(spacing: 10) {
            HStack {
                TextField("Frage stellen…", text: $input)
                    .textFieldStyle(.plain).foregroundColor(Theme.text)
                    .onSubmit(send)
                    .padding(.vertical, 12).padding(.leading, 18)
            }
            .background(Theme.surface)
            .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
            .clipShape(Capsule())

            Button(action: send) {
                Image(systemName: "paperplane.fill").font(.system(size: 17)).foregroundColor(.white)
                    .frame(width: 42, height: 42).background(Theme.redGrad).clipShape(Circle())
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 18).padding(.top, 8)
    }

    private func send() {
        store.kiSend(input)
        input = ""
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 40) }
            VStack(alignment: .leading, spacing: 4) {
                if !message.isUser {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles").font(.system(size: 11))
                        Text("LEVITECH KI").font(.system(size: 11, weight: .bold))
                    }.foregroundColor(Theme.red2)
                }
                if message.isTyping {
                    TypingDots()
                } else {
                    Text(message.text)
                        .font(.system(size: 14)).foregroundColor(message.isUser ? .white : Theme.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 15).padding(.vertical, 12)
            .background(message.isUser ? AnyView(Theme.redGrad) : AnyView(Theme.surface2))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                message.isUser ? nil :
                RoundedRectangle(cornerRadius: 18).stroke(Theme.line, lineWidth: 1)
            )
            if !message.isUser { Spacer(minLength: 40) }
        }
    }
}

struct TypingDots: View {
    @State private var phase = 0
    private let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle().fill(Theme.text3)
                    .frame(width: 7, height: 7)
                    .opacity(phase == i ? 1 : 0.3)
            }
        }
        .onReceive(timer) { _ in phase = (phase + 1) % 3 }
    }
}
