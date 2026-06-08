import SwiftUI

struct AIQuoteItem {
    let beschreibung: String
    let menge: Double
    let einheit: String
    let einzelpreis: Double
}

struct AIQuoteAssistantView: View {
    var onResult: (String, [AIQuoteItem]) -> Void

    @State private var jobDescription = ""
    @State private var loading = false
    @State private var errorMsg: String?
    @Environment(\.dismiss) private var dismiss
    private let ai = AIService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerTile

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Aufgabe beschreiben")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.appTextSecondary)
                            .kerning(0.4)

                        TextEditor(text: $jobDescription)
                            .font(.system(size: 15))
                            .frame(minHeight: 110)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.appBlue.opacity(0.25), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
                    }

                    if let err = errorMsg {
                        Text(err)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }

                    examplesSection
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle("KI-Angebotshilfe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(.appTextSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if loading {
                        ProgressView().tint(.appBlue)
                    } else {
                        Button("Erstellen", action: generate)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(jobDescription.trimmingCharacters(in: .whitespaces).isEmpty
                                             ? .appBlue.opacity(0.3) : .appBlue)
                            .disabled(jobDescription.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var headerTile: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.appBlue.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.appBlue)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Positionen per KI erstellen")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                Text("Beschreibe die Arbeit kurz – KI generiert alle Positionen")
                    .font(.system(size: 12))
                    .foregroundColor(.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    // MARK: - Examples

    private var examplesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BEISPIELE")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.appTextSecondary)
                .kerning(0.6)

            ForEach(examples, id: \.self) { ex in
                Button(action: { jobDescription = ex }) {
                    Text(ex)
                        .font(.system(size: 13))
                        .foregroundColor(.appBlue)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.appBlue.opacity(0.07))
                        .cornerRadius(8)
                }
            }
        }
    }

    private let examples = [
        "Dachrinne reinigen, 20 Meter, inkl. Fallrohre",
        "Dachziegel austauschen, ca. 10 Stück, Schieferdeckung",
        "Flachdach abdichten, 80 m², inkl. Material und Entsorgung",
        "Sturm­schäden beheben, Firstziegel neu verlegen"
    ]

    // MARK: - Generate

    private func generate() {
        loading = true
        errorMsg = nil
        Task {
            do {
                let raw = try await ai.send(jobDescription, system: AIPrompts.quoteAssistant)

                // Strip markdown code fences if present
                let cleaned = raw
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "```json", with: "")
                    .replacingOccurrences(of: "```", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard
                    let data = cleaned.data(using: .utf8),
                    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let title = json["title"] as? String,
                    let rawItems = json["items"] as? [[String: Any]]
                else {
                    errorMsg = "KI-Antwort konnte nicht gelesen werden. Bitte erneut versuchen."
                    loading = false
                    return
                }

                let items = rawItems.compactMap { d -> AIQuoteItem? in
                    guard let desc = d["beschreibung"] as? String else { return nil }
                    return AIQuoteItem(
                        beschreibung: desc,
                        menge:         d["menge"]         as? Double ?? 1.0,
                        einheit:       d["einheit"]        as? String ?? "Std.",
                        einzelpreis:   d["einzelpreis"]    as? Double ?? 85.0
                    )
                }

                dismiss()
                onResult(title, items)
            } catch {
                errorMsg = error.localizedDescription
            }
            loading = false
        }
    }
}

#Preview { AIQuoteAssistantView { _, _ in } }
