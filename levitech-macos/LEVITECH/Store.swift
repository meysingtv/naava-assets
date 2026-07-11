//
//  Store.swift
//  Datenmodelle, Beispieldaten, App-Zustand & Navigation
//

import SwiftUI

// MARK: - Navigation

enum AppScreen: Hashable {
    case dashboard, tickets, ticketDetail, ticketEdit, customer, timecard, zeiterfassung
    case notifications, passwords, ki, checklists, documents, profile, more
}

enum AppTab: Hashable {
    case dashboard, tickets, timecard, customer, more
}

// MARK: - Modelle

enum Priority: String {
    case dringend = "Dringend", hoch = "Hoch", mittel = "Mittel", niedrig = "Niedrig"
    var color: Color {
        switch self {
        case .dringend: return Theme.red
        case .hoch:     return Theme.amber
        case .mittel:   return Theme.yellow
        case .niedrig:  return Theme.gray
        }
    }
}

struct Ticket: Identifiable {
    let id: String
    let title: String
    let customer: String
    let priority: Priority
    let status: String
    var statusColor: Color {
        status.contains("Bearbeitung") ? Theme.amber : (status == "Neu" ? Theme.green : Theme.blue)
    }
}

struct AppNotification: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
    let title: String
    let sub: String
    let when: String
}

struct PasswordEntry: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let sub: String
    let starred: Bool
    var revealed: Bool = false
}

struct ChecklistItem: Identifiable {
    let id = UUID()
    let label: String
    var done: Bool
}

struct DocItem: Identifiable {
    let id = UUID()
    let type: String   // pdf / xls / doc
    let name: String
    let meta: String
    var color: Color {
        switch type {
        case "xls": return Theme.green
        case "doc": return Theme.blue
        default:    return Theme.red
        }
    }
}

struct TimelineItem: Identifiable {
    let id = UUID()
    let time: String
    let label: String
    let color: Color
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    var isTyping: Bool = false
}

struct MenuItem: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let sub: String?
}

struct Feature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let sub: String
}

// MARK: - Store

final class Store: ObservableObject {
    @Published var screen: AppScreen = .dashboard
    @Published var clockedIn: Bool = true
    @Published var onBreak: Bool = false
    @Published var ticketFilter: String = "Meine Tickets"
    @Published var chat: [ChatMessage] = []
    @Published var toast: String? = nil

    @Published var checklist: [ChecklistItem] = [
        .init(label: "Backup prüfen", done: true),
        .init(label: "Windows Updates", done: false),
        .init(label: "SMART prüfen", done: true),
        .init(label: "Eventlogs prüfen", done: false),
        .init(label: "Dienste prüfen", done: false),
        .init(label: "Virenscanner prüfen", done: false),
        .init(label: "Firewall prüfen", done: true),
        .init(label: "Dokumentation prüfen", done: false),
    ]

    @Published var passwords: [PasswordEntry] = [
        .init(icon: "shield.lefthalf.filled", title: "Firewall Hauptstandort", sub: "admin · Firewall", starred: false),
        .init(icon: "cloud.fill", title: "Microsoft 365", sub: "admin@muster-gmbh.de", starred: true),
        .init(icon: "lock.shield.fill", title: "VPN Zugang", sub: "m.muster", starred: false),
        .init(icon: "server.rack", title: "Server FS01", sub: "administrator", starred: false),
        .init(icon: "wifi", title: "WLAN Office", sub: "levitech@2024", starred: false),
    ]

    // Navigation
    func go(_ s: AppScreen) { withAnimation(.easeOut(duration: 0.22)) { screen = s } }

    func selectTab(_ t: AppTab) {
        switch t {
        case .dashboard: go(.dashboard)
        case .tickets:   go(.tickets)
        case .timecard:  go(.timecard)
        case .customer:  go(.customer)
        case .more:      go(.more)
        }
    }

    var activeTab: AppTab {
        switch screen {
        case .dashboard: return .dashboard
        case .tickets, .ticketDetail, .ticketEdit: return .tickets
        case .timecard, .zeiterfassung: return .timecard
        case .customer: return .customer
        default: return .more
        }
    }

    // Aktionen
    func showToast(_ msg: String) {
        toast = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) { [weak self] in
            if self?.toast == msg { self?.toast = nil }
        }
    }

    func toggleCheck(_ item: ChecklistItem) {
        if let i = checklist.firstIndex(where: { $0.id == item.id }) {
            checklist[i].done.toggle()
        }
    }

    var checkDone: Int { checklist.filter { $0.done }.count }

    // KI
    func kiSend(_ q: String) {
        let text = q.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        chat.append(ChatMessage(text: text, isUser: true))
        let typing = ChatMessage(text: "", isUser: false, isTyping: true)
        chat.append(typing)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { [weak self] in
            guard let self else { return }
            if let i = self.chat.firstIndex(where: { $0.id == typing.id }) {
                self.chat[i] = ChatMessage(text: Self.kiAnswer(text), isUser: false)
            }
        }
    }

    static func kiAnswer(_ q: String) -> String {
        let s = q.lowercased()
        if s.contains("vpn") {
            return "Für die VPN-Einrichtung bei einem Kunden:\n1. Öffne die Firewall-Konfiguration\n2. Erstelle ein neues VPN-Profil (IKEv2 empfohlen)\n3. Trage das Kunden-Subnetz ein\n4. Exportiere die .ovpn-Datei und teste die Verbindung\n\nDie Zugangsdaten findest du im Passwortmanager unter »VPN Zugang«."
        }
        if s.contains("firewall") || s.contains("dokumentation") {
            return "Die Firewall-Dokumentation liegt unter Dokumente → »Firewall Regeln.xlsx«. Dort sind alle Portfreigaben und Regelwerke pro Standort hinterlegt."
        }
        if s.contains("backup") || s.contains("server") {
            return "Server-Backup Schritt für Schritt:\n1. Prüfe den letzten Backup-Status im Monitoring\n2. Starte ein manuelles Voll-Backup\n3. Verifiziere die Integrität\n4. Dokumentiere es in der Checkliste »Serverwartung«"
        }
        if s.contains("passwort") || s.contains("switch") {
            return "Passwörter findest du sicher verschlüsselt im Passwortmanager (Reiter »Mehr«). Aus Sicherheitsgründen zeige ich sie hier nicht im Klartext – tippe im Passwortmanager auf das Augen-Symbol."
        }
        return "Gute Frage! Ich durchsuche die Wissensdatenbank und Kundendokumentation für dich. Die meisten Anleitungen findest du unter Dokumente. Soll ich ein Ticket dazu erstellen oder die passende Checkliste öffnen?"
    }
}

// MARK: - Statische Beispieldaten

enum Sample {
    static let userName = "Max Mustermann"
    static let userFirst = "Max"
    static let userRole = "Servicetechniker"

    static let tickets: [Ticket] = [
        .init(id: "#2024-1001", title: "Server ausgefallen", customer: "Muster GmbH", priority: .dringend, status: "In Bearbeitung"),
        .init(id: "#2024-1002", title: "VPN funktioniert nicht", customer: "Schmidt & Partner", priority: .hoch, status: "In Bearbeitung"),
        .init(id: "#2024-1003", title: "Backup überprüfen", customer: "Beispiel KG", priority: .mittel, status: "Offen"),
        .init(id: "#2024-1004", title: "PC Einrichtung neuer MA", customer: "Muster GmbH", priority: .niedrig, status: "Offen"),
        .init(id: "#2024-1005", title: "Drucker Probleme", customer: "ABC GmbH", priority: .mittel, status: "Offen"),
    ]

    static let notifications: [AppNotification] = [
        .init(icon: "plus.circle.fill", color: Theme.green, title: "Neues Ticket", sub: "#2024-1006 wurde erstellt", when: "Jetzt"),
        .init(icon: "pencil.circle.fill", color: Theme.blue, title: "Ticket geändert", sub: "#2024-1002 wurde aktualisiert", when: "5 Min."),
        .init(icon: "bubble.left.fill", color: Theme.red2, title: "Kunde antwortet", sub: "Muster GmbH hat geantwortet", when: "15 Min."),
        .init(icon: "exclamationmark.triangle.fill", color: Theme.amber, title: "SLA Warnung", sub: "SLA für Ticket #2024-0999 läuft in 1 Stunde ab", when: "30 Min."),
        .init(icon: "wrench.and.screwdriver.fill", color: Theme.amber, title: "Wartungsfenster", sub: "Wartung bei Kunde ABC GmbH morgen 22:00 Uhr", when: "1 Std."),
    ]

    static let documents: [DocItem] = [
        .init(type: "pdf", name: "Netzwerkplan.pdf", meta: "PDF · 2.4 MB"),
        .init(type: "xls", name: "Firewall Regeln.xlsx", meta: "XLSX · 1.1 MB"),
        .init(type: "pdf", name: "Backup Konzept.pdf", meta: "PDF · 1.2 MB"),
        .init(type: "pdf", name: "Wartungsvertrag.pdf", meta: "PDF · 1.2 MB"),
        .init(type: "doc", name: "Übergabeprotokoll.docx", meta: "DOCX · 708 KB"),
        .init(type: "pdf", name: "Anleitung VPN.pdf", meta: "PDF · 1.5 MB"),
    ]

    static let timeline: [TimelineItem] = [
        .init(time: "07:18", label: "Eingestempelt", color: Theme.green),
        .init(time: "12:00 – 12:30", label: "Pause", color: Theme.amber),
        .init(time: "12:30", label: "Weitergearbeitet", color: Theme.green),
        .init(time: "17:03", label: "Ausgestempelt", color: Theme.red),
    ]

    static let profileMenu: [MenuItem] = [
        .init(icon: "person.fill", label: "Persönliche Daten", sub: nil),
        .init(icon: "clock.fill", label: "Arbeitszeiten", sub: nil),
        .init(icon: "sun.max.fill", label: "Urlaub", sub: "12 Tage verfügbar"),
        .init(icon: "bolt.fill", label: "Überstundenkonto", sub: "+08:15 h"),
        .init(icon: "rosette", label: "Zertifikate", sub: "5 Zertifikate"),
        .init(icon: "gearshape.fill", label: "Einstellungen", sub: nil),
    ]

    static let features: [Feature] = [
        .init(icon: "wifi.slash", title: "Offline Modus", sub: "Arbeiten auch ohne Internet. Daten werden automatisch synchronisiert."),
        .init(icon: "camera.fill", title: "Kamera & Scanner", sub: "Fotos aufnehmen, QR-Codes scannen und direkt zum Ticket hinzufügen."),
        .init(icon: "shippingbox.fill", title: "Material & Lager", sub: "Verbrauchtes Material erfassen und Lagerbestände prüfen."),
        .init(icon: "location.fill", title: "Navigation", sub: "Direkt zum Kunden navigieren mit Google Maps oder Apple Karten."),
        .init(icon: "person.2.fill", title: "Team & Kommunikation", sub: "Kollegen anrufen, chatten und Verfügbarkeit sehen."),
        .init(icon: "lock.shield.fill", title: "Sicherheit", sub: "Alles verschlüsselt. Zugriff nur für autorisierte Mitarbeiter."),
    ]

    static let kiSuggestions = [
        "Wie richte ich VPN bei Kunde X ein?",
        "Wo finde ich die Firewall Dokumentation?",
        "Wie mache ich ein Backup vom Server?",
        "Passwort für Switch im Büro?",
    ]
}
