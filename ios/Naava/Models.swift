import Foundation
import CoreLocation
import SwiftUI

// MARK: - Appointment Status
enum AppointmentStatus: String, CaseIterable {
    case inProgress = "In Arbeit"
    case planned    = "Geplant"
    case open       = "Offen"

    var color: Color {
        switch self {
        case .inProgress: return .appGreen
        case .planned:    return .appBlue
        case .open:       return .appOrange
        }
    }

    var icon: String {
        switch self {
        case .inProgress: return "hammer.fill"
        case .planned:    return "calendar"
        case .open:       return "clock"
        }
    }
}

// MARK: - Appointment
struct Appointment: Identifiable {
    let id = UUID()
    let title: String
    let customer: String
    let address: String
    let time: String
    let status: AppointmentStatus
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Stat Item
struct StatItem: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
    let color: Color
}

// MARK: - Customer
struct Customer: Identifiable {
    let id = UUID()
    let firstName: String
    let lastName: String
    var company: String?
    let phone: String
    let email: String
    let street: String
    let city: String
    let avatarColor: Color

    var fullName: String { "\(firstName) \(lastName)" }
    var initials: String { "\(firstName.prefix(1))\(lastName.prefix(1))" }
    var displaySubtitle: String { company ?? "\(street), \(city)" }
}

// MARK: - Order Status
enum OrderStatus: String, CaseIterable {
    case open       = "Offen"
    case inProgress = "In Arbeit"
    case done       = "Abgeschlossen"
    case invoiced   = "Abgerechnet"

    var color: Color {
        switch self {
        case .open:       return .appOrange
        case .inProgress: return .appGreen
        case .done:       return .appBlue
        case .invoiced:   return .appPurple
        }
    }
    var icon: String {
        switch self {
        case .open:       return "clock"
        case .inProgress: return "hammer.fill"
        case .done:       return "checkmark.circle.fill"
        case .invoiced:   return "eurosign.circle.fill"
        }
    }
}

// MARK: - Order
struct Order: Identifiable {
    var id = UUID()
    var number: String
    var title: String
    var customerName: String
    var address: String
    var description: String
    var status: OrderStatus
    var date: Date
    var estimatedHours: Double?
    var notes: String = ""
}

// MARK: - Invoice
struct LineItem: Identifiable {
    var id = UUID()
    var description: String
    var quantity: Double
    var unit: String
    var unitPrice: Double
    var total: Double { quantity * unitPrice }
}

enum InvoiceStatus: String, CaseIterable {
    case open    = "Offen"
    case paid    = "Bezahlt"
    case overdue = "Überfällig"

    var color: Color {
        switch self {
        case .open:    return .appOrange
        case .paid:    return .appGreen
        case .overdue: return .red
        }
    }
    var icon: String {
        switch self {
        case .open:    return "clock.fill"
        case .paid:    return "checkmark.seal.fill"
        case .overdue: return "exclamationmark.circle.fill"
        }
    }
}

struct Invoice: Identifiable {
    var id = UUID()
    var number: String
    var customerName: String
    var customerAddress: String
    var orderTitle: String
    var lineItems: [LineItem]
    var status: InvoiceStatus
    var issueDate: Date
    var dueDate: Date
    var taxRate: Double = 0.19

    var netTotal: Double   { lineItems.reduce(0) { $0 + $1.total } }
    var taxAmount: Double  { netTotal * taxRate }
    var grossTotal: Double { netTotal + taxAmount }

    static func format(_ v: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .currency; f.locale = Locale(identifier: "de_DE")
        return f.string(from: NSNumber(value: v)) ?? "\(v) €"
    }
    var formattedGross: String { Invoice.format(grossTotal) }
    var formattedNet: String   { Invoice.format(netTotal) }
    var formattedTax: String   { Invoice.format(taxAmount) }
}

// MARK: - Calendar Event
struct CalendarEvent: Identifiable {
    let id = UUID()
    let title: String
    let customer: String
    let date: Date
    let durationMinutes: Int
    let status: AppointmentStatus
}

// MARK: - Dummy Data
enum DummyData {
    private static func d(_ day: Int, h: Int = 8, m: Int = 0) -> Date {
        var c = DateComponents(); c.year = 2026; c.month = 6; c.day = day; c.hour = h; c.minute = m
        return Calendar.current.date(from: c) ?? Date()
    }
    private static func ago(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
    }
    private static func from(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
    }

    static let appointments: [Appointment] = [
        Appointment(
            title: "Dachsanierung",
            customer: "Familie Müller",
            address: "Hauptstr. 12, München",
            time: "08:00",
            status: .inProgress,
            coordinate: CLLocationCoordinate2D(latitude: 48.1351, longitude: 11.5820)
        ),
        Appointment(
            title: "Dachrinne erneuern",
            customer: "Fa. Schmidt GmbH",
            address: "Industriestr. 45, München",
            time: "11:00",
            status: .planned,
            coordinate: CLLocationCoordinate2D(latitude: 48.1451, longitude: 11.5650)
        ),
        Appointment(
            title: "Angebot vor Ort",
            customer: "Bauer, Thomas",
            address: "Gartenweg 3, Pasing",
            time: "14:30",
            status: .open,
            coordinate: CLLocationCoordinate2D(latitude: 48.1520, longitude: 11.4620)
        ),
    ]

    static var customers: [Customer] = [
        Customer(firstName: "Thomas",  lastName: "Bauer",
                 company: nil,
                 phone: "+49 89 123456",  email: "t.bauer@gmail.com",
                 street: "Gartenweg 3",   city: "München-Pasing",
                 avatarColor: .appBlue),
        Customer(firstName: "Klaus",   lastName: "Müller",
                 company: "Familie Müller",
                 phone: "+49 89 654321",  email: "mueller@web.de",
                 street: "Hauptstr. 12",  city: "München",
                 avatarColor: .appGreen),
        Customer(firstName: "Andrea",  lastName: "Schmidt",
                 company: "Schmidt GmbH",
                 phone: "+49 89 112233",  email: "info@schmidt-gmbh.de",
                 street: "Industriestr. 45", city: "München",
                 avatarColor: .appOrange),
        Customer(firstName: "Claudia", lastName: "Weber",
                 company: nil,
                 phone: "+49 89 778899",  email: "c.weber@icloud.com",
                 street: "Rosenstr. 7",   city: "München-Pasing",
                 avatarColor: .appPurple),
        Customer(firstName: "Peter",   lastName: "Maier",
                 company: "Maier & Söhne",
                 phone: "+49 89 334455",  email: "p.maier@maier-soehne.de",
                 street: "Bergweg 22",    city: "München-Schwabing",
                 avatarColor: .appBlue),
        Customer(firstName: "Julia",   lastName: "Hofmann",
                 company: nil,
                 phone: "+49 89 556677",  email: "julia.hofmann@gmx.de",
                 street: "Wiesenweg 5",   city: "Dachau",
                 avatarColor: .appGreen),
    ]

    static let stats: [StatItem] = [
        StatItem(title: "Aufträge",   value: "12", icon: "briefcase.fill",       color: .appBlue),
        StatItem(title: "Angebote",   value: "5",  icon: "doc.text.fill",         color: .appOrange),
        StatItem(title: "Rechnungen", value: "8",  icon: "eurosign.circle.fill",  color: .appGreen),
        StatItem(title: "Mitarbeiter",value: "4",  icon: "person.2.fill",         color: .appPurple),
    ]

    static var orders: [Order] = [
        Order(number: "AU-2026-012", title: "Dachsanierung",
              customerName: "Familie Müller", address: "Hauptstr. 12, München",
              description: "Komplette Neueindeckung mit Biberschwanzziegeln inkl. Dachlattung und Unterspannbahn.",
              status: .inProgress, date: ago(5), estimatedHours: 24),
        Order(number: "AU-2026-011", title: "Dachrinne erneuern",
              customerName: "Fa. Schmidt GmbH", address: "Industriestr. 45, München",
              description: "Austausch der kompletten Dachrinne und Fallrohre. Material: Aluminium anthrazit.",
              status: .done, date: ago(15), estimatedHours: 6),
        Order(number: "AU-2026-010", title: "Neueindeckung Anbau",
              customerName: "Claudia Weber", address: "Rosenstr. 7, München-Pasing",
              description: "Neueindeckung des Dachgeschoss-Anbaus. Flachdach mit Bitumenbahnen 2-lagig.",
              status: .open, date: from(7), estimatedHours: 8),
        Order(number: "AU-2026-009", title: "Gaubenanbau",
              customerName: "Maier & Söhne", address: "Bergweg 22, München-Schwabing",
              description: "Anbau einer Schleppgaube mit Fenster. Eindeckung mit Ziegeln passend zum Bestand.",
              status: .open, date: from(3), estimatedHours: 32),
        Order(number: "AU-2026-008", title: "Flachdach Sanierung",
              customerName: "Thomas Bauer", address: "Gartenweg 3, München-Pasing",
              description: "Erneuerung der Abdichtung auf dem Garagenflachdach. EPDM-Folie.",
              status: .invoiced, date: ago(30), estimatedHours: 10),
    ]

    static var invoices: [Invoice] = [
        Invoice(number: "RE-2026-008", customerName: "Thomas Bauer",
                customerAddress: "Gartenweg 3\n82152 München-Pasing",
                orderTitle: "Flachdach Sanierung",
                lineItems: [
                    LineItem(description: "Arbeitszeit Dachdecker (2 Mann × 5h)", quantity: 10, unit: "Std.", unitPrice: 75),
                    LineItem(description: "EPDM-Folie inkl. Klebesets", quantity: 1, unit: "pauschal", unitPrice: 580),
                    LineItem(description: "Dämmung Perimeter 80mm", quantity: 18, unit: "m²", unitPrice: 14.50),
                ],
                status: .paid,
                issueDate: ago(25), dueDate: ago(11)),
        Invoice(number: "RE-2026-009", customerName: "Fa. Schmidt GmbH",
                customerAddress: "Industriestr. 45\n80339 München",
                orderTitle: "Dachrinne erneuern",
                lineItems: [
                    LineItem(description: "Arbeitszeit Dachdecker", quantity: 6, unit: "Std.", unitPrice: 75),
                    LineItem(description: "Aluminiumrinne anthrazit lfd. m", quantity: 22, unit: "m", unitPrice: 18.90),
                    LineItem(description: "Fallrohr Alu 100mm", quantity: 8, unit: "m", unitPrice: 12.50),
                ],
                status: .open,
                issueDate: ago(10), dueDate: from(4)),
        Invoice(number: "RE-2026-007", customerName: "Klaus Müller",
                customerAddress: "Hauptstr. 12\n80331 München",
                orderTitle: "Dachsanierung (Anzahlung 50%)",
                lineItems: [
                    LineItem(description: "Anzahlung 50% – Dachsanierung Biberschwanz", quantity: 1, unit: "pauschal", unitPrice: 2000),
                ],
                status: .overdue,
                issueDate: ago(45), dueDate: ago(15)),
    ]

    static var calendarEvents: [CalendarEvent] = [
        CalendarEvent(title: "Dachsanierung",      customer: "Familie Müller",   date: d(8, h: 8),  durationMinutes: 180, status: .inProgress),
        CalendarEvent(title: "Dachrinne erneuern", customer: "Fa. Schmidt GmbH", date: d(8, h: 11), durationMinutes: 90,  status: .planned),
        CalendarEvent(title: "Angebot vor Ort",    customer: "Bauer, Thomas",    date: d(8, h: 14, m: 30), durationMinutes: 60, status: .open),
        CalendarEvent(title: "Neueindeckung",      customer: "Claudia Weber",    date: d(15, h: 7), durationMinutes: 480, status: .planned),
        CalendarEvent(title: "Gaubenanbau Abnahme",customer: "Maier & Söhne",   date: d(17, h: 10),durationMinutes: 120, status: .planned),
        CalendarEvent(title: "Regenrinne Wartung", customer: "Julia Hofmann",    date: d(22, h: 9), durationMinutes: 120, status: .open),
        CalendarEvent(title: "Dachinspektion",     customer: "Peter Maier",      date: d(25, h: 13),durationMinutes: 60,  status: .open),
        CalendarEvent(title: "Neuer Kundenbesuch", customer: "Claudia Weber",    date: d(10, h: 15),durationMinutes: 60,  status: .open),
    ]
}

// MARK: - Subscription Plan
enum SubscriptionPlan: String, CaseIterable {
    case basic    = "Basic"
    case pro      = "Pro"
    case business = "Business"

    var monthlyPrice: Int {
        switch self { case .basic: return 29; case .pro: return 59; case .business: return 99 }
    }
    var yearlyMonthlyPrice: Int {
        switch self { case .basic: return 23; case .pro: return 47; case .business: return 79 }
    }
    var color: Color {
        switch self { case .basic: return .appGreen; case .pro: return .appBlue; case .business: return .appPurple }
    }
    var icon: String {
        switch self { case .basic: return "star.fill"; case .pro: return "bolt.fill"; case .business: return "crown.fill" }
    }
    var features: [(label: String, included: Bool)] {
        switch self {
        case .basic: return [
            ("Bis 50 Aufträge/Monat", true),
            ("1 Nutzer", true),
            ("Kundenverwaltung", true),
            ("Rechnungen als PDF", true),
            ("Fotodokumentation", false),
            ("E-Rechnung (ZUGFeRD)", false),
            ("Mehrere Nutzer", false),
        ]
        case .pro: return [
            ("Unbegrenzte Aufträge", true),
            ("Bis 3 Nutzer", true),
            ("Kundenverwaltung", true),
            ("Rechnungen + E-Rechnung", true),
            ("Fotodokumentation", true),
            ("Kalender & Termine", true),
            ("API-Zugang", false),
        ]
        case .business: return [
            ("Unbegrenzte Aufträge", true),
            ("Bis 10 Nutzer", true),
            ("Alles aus Pro", true),
            ("API-Zugang", true),
            ("Priority Support", true),
            ("Individuelle Vorlagen", true),
            ("Datenexport (CSV/JSON)", true),
        ]
        }
    }
}
