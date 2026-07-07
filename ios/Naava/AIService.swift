import Foundation
import SwiftUI

// MARK: - Chat Message

struct ChatMessage: Identifiable, Equatable {
    var id = UUID()
    let role: String
    let content: String
    var isLoading: Bool = false
}

// MARK: - AI Service

@MainActor
class AIService: ObservableObject {
    static let shared = AIService()
    private init() {}

    @AppStorage("anthropicAPIKey") var apiKey: String = ""
    private let model = "claude-haiku-4-5-20251001"

    func analyzeImage(_ imageData: Data, prompt: String) async throws -> String {
        let key = apiKey.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { throw AIError.noKey }

        let base64 = imageData.base64EncodedString()
        let content: [[String: Any]] = [
            ["type": "image", "source": ["type": "base64", "media_type": "image/jpeg", "data": base64]],
            ["type": "text", "text": prompt]
        ]
        let body: [String: Any] = [
            "model":      model,
            "max_tokens": 1024,
            "messages":   [["role": "user", "content": content]]
        ]

        var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        req.httpMethod = "POST"
        req.setValue(key,               forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01",       forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        req.timeoutInterval = 60

        let (data, res) = try await URLSession.shared.data(for: req)
        guard let http = res as? HTTPURLResponse, http.statusCode == 200 else {
            throw AIError.apiError
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return (json?["content"] as? [[String: Any]])?.first?["text"] as? String ?? "Keine Antwort."
    }

    func send(_ text: String, history: [ChatMessage] = [], system: String) async throws -> String {
        let key = apiKey.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { throw AIError.noKey }

        let msgs: [[String: Any]] = history
            .filter { !$0.isLoading }
            .map { ["role": $0.role, "content": $0.content] }
            + [["role": "user", "content": text]]

        let body: [String: Any] = [
            "model":      model,
            "max_tokens": 1024,
            "system":     system,
            "messages":   msgs
        ]

        var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        req.httpMethod = "POST"
        req.setValue(key,               forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01",       forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        req.timeoutInterval = 30

        let (data, res) = try await URLSession.shared.data(for: req)
        guard let http = res as? HTTPURLResponse, http.statusCode == 200 else {
            throw AIError.apiError
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return (json?["content"] as? [[String: Any]])?.first?["text"] as? String ?? "Keine Antwort."
    }
}

// MARK: - Errors

enum AIError: LocalizedError {
    case noKey, apiError
    var errorDescription: String? {
        switch self {
        case .noKey:    return "Kein API-Key. Bitte unter Einstellungen → KI eintragen."
        case .apiError: return "Verbindungsfehler. Bitte prüfe deinen API-Key und versuche es erneut."
        }
    }
}

// MARK: - System Prompts

enum AIPrompts {
    static let support = """
    Du bist der KI-Assistent der Naava App – einer Handwerker-App für deutsche Dachdeckerbetriebe.

    App-Funktionen:
    • Dashboard: Umsatz-Überblick, offene Aufträge & Rechnungen
    • Aufträge: anlegen, Status verfolgen (Offen / In Arbeit / Abgeschlossen / Abgerechnet)
    • Angebote: erstellen, als PDF exportieren, in Auftrag umwandeln
    • Rechnungen: ausstellen und als PDF teilen
    • Kunden & Mitarbeiter verwalten
    • Karte mit allen Baustellen
    • Auswertungen: Umsatz-Charts, Top-Kunden
    • Einstellungen: MwSt., Zahlungsziel, Firmenprofil

    Antworte IMMER auf Deutsch. Sei kurz, freundlich und konkret.
    Bei App-Fragen: klare Schritt-für-Schritt-Anleitung geben.
    Bei Dachdecker-Fachfragen: praxisnahe Antwort auf Basis deutscher Normen und Preise.
    """

    static let quoteAssistant = """
    Du erstellst Angebotspositionen für einen deutschen Dachdeckerbetrieb.
    Der Nutzer beschreibt eine Aufgabe kurz. Du antwortest NUR mit validem JSON (kein Text davor/danach):
    {"title":"Kurzer Angebotstitel","items":[{"beschreibung":"Positionsbeschreibung","menge":2.0,"einheit":"Std.","einzelpreis":85.0}]}
    Typische Einheiten: Std., m², lfm, Stk., Pauschal
    Typischer Stundenlohn Dachdecker: 75–95 €/Std.
    Erstelle 2–5 sinnvolle Positionen passend zur Beschreibung.
    """

    static let damageAnalysis = """
    Du bist Experte für Dachschäden und Dachdecker-Handwerk in Deutschland.
    Analysiere das Foto des Dachs oder Dachschadens präzise.
    Antworte NUR mit validem JSON (kein Text davor/danach):
    {
      "schadenstyp": "Kurze Bezeichnung z.B. Lose Dachziegel",
      "beschreibung": "3-4 präzise Sätze auf Deutsch",
      "massnahmen": ["Maßnahme 1", "Maßnahme 2", "Maßnahme 3"],
      "kostenSchaetzung": "500–800 €",
      "dringlichkeit": "Hoch",
      "zeitrahmen": "Innerhalb von 1 Woche"
    }
    Dringlichkeit: Hoch (sofortiger Handlungsbedarf), Mittel (innerhalb 1 Monat), Niedrig (nächste Wartung).
    Typische Kosten: Kleinreparatur 200–500€, Teilreparatur 500–2000€, Großreparatur 2000–10000€.
    """

    static let emailAssistant = """
    Du schreibst professionelle deutsche Geschäftsmails für einen Dachdeckerbetrieb.
    Antworte NUR mit validem JSON (kein Text davor/danach):
    {"betreff":"...","text":"Sehr geehrte/r ...,\\n\\n[Inhalt]\\n\\nMit freundlichen Grüßen\\n[Firmenname]"}
    Sei professionell, freundlich und knapp.
    """
}
