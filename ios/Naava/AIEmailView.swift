import SwiftUI

struct AIEmailView: View {
    let context: String
    let details: String

    @State private var betreff  = ""
    @State private var bodyText = ""
    @State private var loading  = true
    @State private var errorMsg: String?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var toast: ToastManager
    private let ai = AIService.shared

    var body: some View {
        NavigationStack {
            Group {
                if loading      { loadingView  }
                else if errorMsg != nil { errorView }
                else            { contentView  }
            }
            .background(Color.appBackground)
            .navigationTitle("Email erstellen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }.foregroundColor(.appBlue)
                }
            }
        }
        .onAppear { generate() }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - States

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView().scaleEffect(1.4).tint(.appBlue)
            Text("Email wird verfasst…")
                .font(.system(size: 14))
                .foregroundColor(.appTextSecondary)
            Spacer()
        }
    }

    private var errorView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 36))
                .foregroundColor(.appTextSecondary.opacity(0.4))
            Text(errorMsg ?? "Unbekannter Fehler")
                .font(.system(size: 14))
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Erneut versuchen", action: generate)
                .foregroundColor(.appBlue)
            Spacer()
        }
    }

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 14) {

                // Subject field
                VStack(alignment: .leading, spacing: 6) {
                    Label("Betreff", systemImage: "envelope.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.appTextSecondary)
                        .kerning(0.4)
                    Text(betreff)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.appTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(14)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)

                // Body field
                VStack(alignment: .leading, spacing: 6) {
                    Label("Email-Text", systemImage: "doc.text")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.appTextSecondary)
                        .kerning(0.4)
                    Text(bodyText)
                        .font(.system(size: 14))
                        .foregroundColor(.appTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(14)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)

                // Action buttons
                HStack(spacing: 10) {
                    Button(action: copyAll) {
                        Label("Kopieren", systemImage: "doc.on.doc")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.appBlue)
                            .cornerRadius(12)
                    }

                    Button(action: generate) {
                        Label("Neu", systemImage: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.appBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.appBlue.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
            }
            .padding(16)
        }
    }

    // MARK: - Logic

    private func generate() {
        loading  = true
        errorMsg = nil
        Task {
            do {
                let prompt = "Erstelle eine professionelle \(context)-Email. Details: \(details)"
                let raw = try await ai.send(prompt, system: AIPrompts.emailAssistant)

                let cleaned = raw
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "```json", with: "")
                    .replacingOccurrences(of: "```", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if let data = cleaned.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    betreff  = json["betreff"]  as? String ?? ""
                    bodyText = json["text"]     as? String ?? raw
                } else {
                    bodyText = raw
                    betreff  = "\(context) – Naava"
                }
            } catch {
                errorMsg = error.localizedDescription
            }
            loading = false
        }
    }

    private func copyAll() {
        UIPasteboard.general.string = "Betreff: \(betreff)\n\n\(bodyText)"
        toast.show("In Zwischenablage kopiert", style: .success, icon: "doc.on.doc.fill")
    }
}

#Preview {
    AIEmailView(context: "Angebot", details: "AN-2026-001, Dachrinne reinigen, 850 €, Kunde: Familie Müller")
        .environmentObject(ToastManager())
}
