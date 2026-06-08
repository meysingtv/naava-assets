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

// MARK: - Employee Role
enum EmployeeRole: String, CaseIterable {
    case meister = "Meister"
    case geselle = "Geselle"
    case azubi   = "Azubi"
    case buero   = "Büro"

    var color: Color {
        switch self {
        case .meister: return .appBlue
        case .geselle: return .appGreen
        case .azubi:   return .appOrange
        case .buero:   return .appPurple
        }
    }
    var icon: String {
        switch self {
        case .meister: return "star.fill"
        case .geselle: return "hammer.fill"
        case .azubi:   return "graduationcap.fill"
        case .buero:   return "doc.text.fill"
        }
    }
}

// MARK: - Employee
struct Employee: Identifiable {
    var id = UUID()
    var firstName: String
    var lastName: String
    var role: EmployeeRole
    var phone: String
    var email: String
    var avatarColor: Color
    var hireDate: Date
    var isActive: Bool = true
    var hoursThisMonth: Int

    var fullName: String { "\(firstName) \(lastName)" }
    var initials: String { "\(firstName.prefix(1))\(lastName.prefix(1))" }

    var experienceText: String {
        let months = Calendar.current.dateComponents([.month], from: hireDate, to: Date()).month ?? 0
        if months < 12 { return "\(months) Monate" }
        let years = months / 12
        return years == 1 ? "1 Jahr" : "\(years) Jahre"
    }
}

// MARK: - Absence Type
enum AbsenceType: String, CaseIterable {
    case urlaub      = "Urlaub"
    case krank       = "Krank"
    case fortbildung = "Fortbildung"
    case sonstiges   = "Sonstiges"

    var color: Color {
        switch self {
        case .urlaub:      return .appOrange
        case .krank:       return .red
        case .fortbildung: return .appPurple
        case .sonstiges:   return .appTextSecondary
        }
    }
    var icon: String {
        switch self {
        case .urlaub:      return "sun.max.fill"
        case .krank:       return "cross.case.fill"
        case .fortbildung: return "graduationcap.fill"
        case .sonstiges:   return "ellipsis.circle.fill"
        }
    }
}

// MARK: - Absence
struct Absence: Identifiable {
    var id = UUID()
    var employeeName: String
    var type: AbsenceType
    var startDate: Date
    var endDate: Date
    var note: String = ""

    func covers(_ date: Date) -> Bool {
        let cal = Calendar.current
        let d = cal.startOfDay(for: date)
        return d >= cal.startOfDay(for: startDate) && d <= cal.startOfDay(for: endDate)
    }

    var durationDays: Int {
        let d = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        return d + 1
    }
}

// MARK: - Work Assignment
struct WorkAssignment: Identifiable {
    var id = UUID()
    var employeeName: String
    var orderTitle: String
    var orderNumber: String
    var date: Date
    var color: Color
}

// MARK: - Time Entry
struct TimeEntry: Identifiable {
    var id = UUID()
    var employeeName: String
    var orderTitle: String
    var startTime: Date
    var endTime: Date?
    var breakMinutes: Int = 0

    var isActive: Bool { endTime == nil }

    func netDuration(at now: Date = Date()) -> TimeInterval {
        let end = endTime ?? now
        return max(0, end.timeIntervalSince(startTime) - Double(breakMinutes * 60))
    }

    func formattedNet(at now: Date = Date()) -> String {
        let s = Int(netDuration(at: now))
        let h = s / 3600
        let m = (s % 3600) / 60
        return h == 0 ? "\(m)min" : String(format: "%dh %02dmin", h, m)
    }
}

// MARK: - Calendar Extension
extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        var cal = self
        cal.firstWeekday = 2
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: comps) ?? date
    }
}

// MARK: - Quote Status
enum QuoteStatus: String, CaseIterable {
    case draft    = "Entwurf"
    case sent     = "Gesendet"
    case accepted = "Angenommen"
    case rejected = "Abgelehnt"

    var color: Color {
        switch self {
        case .draft:    return .appTextSecondary
        case .sent:     return .appBlue
        case .accepted: return .appGreen
        case .rejected: return .red
        }
    }
    var icon: String {
        switch self {
        case .draft:    return "pencil.circle.fill"
        case .sent:     return "paperplane.fill"
        case .accepted: return "checkmark.seal.fill"
        case .rejected: return "xmark.circle.fill"
        }
    }
}

// MARK: - Quote
struct Quote: Identifiable {
    var id = UUID()
    var number: String
    var customerName: String
    var customerAddress: String
    var title: String
    var description: String
    var lineItems: [LineItem]
    var status: QuoteStatus
    var issueDate: Date
    var validUntil: Date
    var taxRate: Double = 0.19

    var netTotal: Double   { lineItems.reduce(0) { $0 + $1.total } }
    var taxAmount: Double  { netTotal * taxRate }
    var grossTotal: Double { netTotal + taxAmount }

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
            address: "Hauptstr. 12, Mönchengladbach",
            time: "08:00",
            status: .inProgress,
            coordinate: CLLocationCoordinate2D(latitude: 51.1963, longitude: 6.4428)
        ),
        Appointment(
            title: "Dachrinne erneuern",
            customer: "Fa. Schmidt GmbH",
            address: "Industriestr. 45, Mönchengladbach-Rheydt",
            time: "11:00",
            status: .planned,
            coordinate: CLLocationCoordinate2D(latitude: 51.1695, longitude: 6.4424)
        ),
        Appointment(
            title: "Angebot vor Ort",
            customer: "Bauer, Thomas",
            address: "Gartenweg 3, Mönchengladbach-Wickrath",
            time: "14:30",
            status: .open,
            coordinate: CLLocationCoordinate2D(latitude: 51.1428, longitude: 6.4082)
        ),
    ]

    static var customers: [Customer] = [
        Customer(firstName: "Thomas",  lastName: "Bauer",
                 company: nil,
                 phone: "+49 2161 123456",  email: "t.bauer@gmail.com",
                 street: "Gartenweg 3",   city: "Mönchengladbach",
                 avatarColor: .appBlue),
        Customer(firstName: "Klaus",   lastName: "Müller",
                 company: "Familie Müller",
                 phone: "+49 2161 654321",  email: "mueller@web.de",
                 street: "Hauptstr. 12",  city: "Mönchengladbach",
                 avatarColor: .appGreen),
        Customer(firstName: "Andrea",  lastName: "Schmidt",
                 company: "Schmidt GmbH",
                 phone: "+49 2166 112233",  email: "info@schmidt-gmbh.de",
                 street: "Industriestr. 45", city: "Mönchengladbach-Rheydt",
                 avatarColor: .appOrange),
        Customer(firstName: "Claudia", lastName: "Weber",
                 company: nil,
                 phone: "+49 2161 778899",  email: "c.weber@icloud.com",
                 street: "Rosenstr. 7",   city: "Mönchengladbach",
                 avatarColor: .appPurple),
        Customer(firstName: "Peter",   lastName: "Maier",
                 company: "Maier & Söhne",
                 phone: "+49 2161 334455",  email: "p.maier@maier-soehne.de",
                 street: "Bergweg 22",    city: "Mönchengladbach-Neuwerk",
                 avatarColor: .appBlue),
        Customer(firstName: "Julia",   lastName: "Hofmann",
                 company: nil,
                 phone: "+49 2161 556677",  email: "julia.hofmann@gmx.de",
                 street: "Wiesenweg 5",   city: "Mönchengladbach-Odenkirchen",
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
              customerName: "Familie Müller", address: "Hauptstr. 12, Mönchengladbach",
              description: "Komplette Neueindeckung mit Biberschwanzziegeln inkl. Dachlattung und Unterspannbahn.",
              status: .inProgress, date: ago(5), estimatedHours: 24),
        Order(number: "AU-2026-011", title: "Dachrinne erneuern",
              customerName: "Fa. Schmidt GmbH", address: "Industriestr. 45, Mönchengladbach-Rheydt",
              description: "Austausch der kompletten Dachrinne und Fallrohre. Material: Aluminium anthrazit.",
              status: .done, date: ago(15), estimatedHours: 6),
        Order(number: "AU-2026-010", title: "Neueindeckung Anbau",
              customerName: "Claudia Weber", address: "Rosenstr. 7, Mönchengladbach",
              description: "Neueindeckung des Dachgeschoss-Anbaus. Flachdach mit Bitumenbahnen 2-lagig.",
              status: .open, date: from(7), estimatedHours: 8),
        Order(number: "AU-2026-009", title: "Gaubenanbau",
              customerName: "Maier & Söhne", address: "Bergweg 22, Mönchengladbach-Neuwerk",
              description: "Anbau einer Schleppgaube mit Fenster. Eindeckung mit Ziegeln passend zum Bestand.",
              status: .open, date: from(3), estimatedHours: 32),
        Order(number: "AU-2026-008", title: "Flachdach Sanierung",
              customerName: "Thomas Bauer", address: "Gartenweg 3, Mönchengladbach",
              description: "Erneuerung der Abdichtung auf dem Garagenflachdach. EPDM-Folie.",
              status: .invoiced, date: ago(30), estimatedHours: 10),
    ]

    static var invoices: [Invoice] = [
        Invoice(number: "RE-2026-008", customerName: "Thomas Bauer",
                customerAddress: "Gartenweg 3\n41189 Mönchengladbach",
                orderTitle: "Flachdach Sanierung",
                lineItems: [
                    LineItem(description: "Arbeitszeit Dachdecker (2 Mann × 5h)", quantity: 10, unit: "Std.", unitPrice: 75),
                    LineItem(description: "EPDM-Folie inkl. Klebesets", quantity: 1, unit: "pauschal", unitPrice: 580),
                    LineItem(description: "Dämmung Perimeter 80mm", quantity: 18, unit: "m²", unitPrice: 14.50),
                ],
                status: .paid,
                issueDate: ago(25), dueDate: ago(11)),
        Invoice(number: "RE-2026-009", customerName: "Fa. Schmidt GmbH",
                customerAddress: "Industriestr. 45\n41236 Mönchengladbach-Rheydt",
                orderTitle: "Dachrinne erneuern",
                lineItems: [
                    LineItem(description: "Arbeitszeit Dachdecker", quantity: 6, unit: "Std.", unitPrice: 75),
                    LineItem(description: "Aluminiumrinne anthrazit lfd. m", quantity: 22, unit: "m", unitPrice: 18.90),
                    LineItem(description: "Fallrohr Alu 100mm", quantity: 8, unit: "m", unitPrice: 12.50),
                ],
                status: .open,
                issueDate: ago(10), dueDate: from(4)),
        Invoice(number: "RE-2026-007", customerName: "Klaus Müller",
                customerAddress: "Hauptstr. 12\n41061 Mönchengladbach",
                orderTitle: "Dachsanierung (Anzahlung 50%)",
                lineItems: [
                    LineItem(description: "Anzahlung 50% – Dachsanierung Biberschwanz", quantity: 1, unit: "pauschal", unitPrice: 2000),
                ],
                status: .overdue,
                issueDate: ago(45), dueDate: ago(15)),
    ]

    static var employees: [Employee] = [
        Employee(firstName: "Max",   lastName: "Scheulen",
                 role: .meister, phone: "+49 2161 987654", email: "max.scheulen@betrieb.de",
                 avatarColor: .appBlue,   hireDate: ago(1825), isActive: true, hoursThisMonth: 142),
        Employee(firstName: "Hans",  lastName: "Weber",
                 role: .geselle, phone: "+49 2161 112233", email: "h.weber@betrieb.de",
                 avatarColor: .appGreen,  hireDate: ago(730),  isActive: true, hoursThisMonth: 136),
        Employee(firstName: "Klaus", lastName: "Fischer",
                 role: .geselle, phone: "+49 2161 445566", email: "k.fischer@betrieb.de",
                 avatarColor: .appOrange, hireDate: ago(365),  isActive: true, hoursThisMonth: 118),
        Employee(firstName: "Anna",  lastName: "Becker",
                 role: .buero,   phone: "+49 2161 778899", email: "a.becker@betrieb.de",
                 avatarColor: .appPurple, hireDate: ago(548),  isActive: true, hoursThisMonth: 80),
    ]

    static var quotes: [Quote] = [
        Quote(
            number: "AN-2026-005",
            customerName: "Familie Müller",
            customerAddress: "Hauptstr. 12\n41061 Mönchengladbach",
            title: "Dachsanierung Komplett",
            description: "Komplette Neueindeckung des Satteldaches mit Tonziegeln inkl. neuer Dachlattung, Unterspannbahn und Traufblech.",
            lineItems: [
                LineItem(description: "Abbruch Altbelag",          quantity: 120, unit: "m²",      unitPrice: 8.00),
                LineItem(description: "Tonziegel inkl. Verlegung",  quantity: 120, unit: "m²",      unitPrice: 38.00),
                LineItem(description: "Dachlattung Fichte",         quantity: 120, unit: "m²",      unitPrice: 6.50),
                LineItem(description: "Unterspannbahn",             quantity: 130, unit: "m²",      unitPrice: 3.20),
            ],
            status: .sent,
            issueDate: ago(8), validUntil: from(22)
        ),
        Quote(
            number: "AN-2026-004",
            customerName: "Thomas Bauer",
            customerAddress: "Gartenweg 3\n41189 Mönchengladbach",
            title: "Flachdach Sanierung Garage",
            description: "Erneuerung der Abdichtung auf dem Garagenflachdach. EPDM-Folie, 2-lagig.",
            lineItems: [
                LineItem(description: "Arbeitszeit Dachdecker", quantity: 10, unit: "Std.",     unitPrice: 75.00),
                LineItem(description: "EPDM-Folie inkl. Klebe", quantity: 1,  unit: "pauschal", unitPrice: 580.00),
                LineItem(description: "Dämmung 80mm",           quantity: 18, unit: "m²",       unitPrice: 14.50),
            ],
            status: .accepted,
            issueDate: ago(35), validUntil: ago(5)
        ),
        Quote(
            number: "AN-2026-003",
            customerName: "Maier & Söhne",
            customerAddress: "Bergweg 22\n41066 Mönchengladbach-Neuwerk",
            title: "Gaubenanbau + Eindeckung",
            description: "Anbau einer Schleppgaube mit Holzfenster 80×60 cm. Eindeckung mit Ziegeln passend zum Bestand.",
            lineItems: [
                LineItem(description: "Zimmermannarbeiten Gaube", quantity: 1,  unit: "pauschal", unitPrice: 2800.00),
                LineItem(description: "Eindeckung Gaubenbereich",  quantity: 12, unit: "m²",      unitPrice: 45.00),
                LineItem(description: "Fenster inkl. Einbau",      quantity: 1,  unit: "Stk.",    unitPrice: 680.00),
            ],
            status: .draft,
            issueDate: ago(2), validUntil: from(28)
        ),
    ]

    static var absences: [Absence] = {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        func from(_ n: Int) -> Date { cal.date(byAdding: .day, value: n, to: today)! }
        func ago(_ n: Int) -> Date  { cal.date(byAdding: .day, value: -n, to: today)! }
        return [
            Absence(employeeName: "Hans Weber",    type: .urlaub,
                    startDate: from(3), endDate: from(9),   note: "Sommerurlaub"),
            Absence(employeeName: "Klaus Fischer",  type: .krank,
                    startDate: ago(1),  endDate: from(1)),
            Absence(employeeName: "Anna Becker",   type: .fortbildung,
                    startDate: from(7), endDate: from(7),   note: "Dachdecker-Tagung NRW"),
        ]
    }()

    static var workAssignments: [WorkAssignment] = {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        func d(_ offset: Int) -> Date { cal.date(byAdding: .day, value: offset, to: today)! }
        return [
            WorkAssignment(employeeName: "Max Scheulen",  orderTitle: "Dachsanierung",       orderNumber: "AU-2026-012", date: d(0), color: .appBlue),
            WorkAssignment(employeeName: "Hans Weber",    orderTitle: "Dachsanierung",       orderNumber: "AU-2026-012", date: d(0), color: .appBlue),
            WorkAssignment(employeeName: "Klaus Fischer", orderTitle: "Dachrinne erneuern",  orderNumber: "AU-2026-011", date: d(0), color: .appGreen),
            WorkAssignment(employeeName: "Max Scheulen",  orderTitle: "Neueindeckung Anbau", orderNumber: "AU-2026-010", date: d(1), color: .appOrange),
            WorkAssignment(employeeName: "Klaus Fischer", orderTitle: "Dachsanierung",       orderNumber: "AU-2026-012", date: d(1), color: .appBlue),
            WorkAssignment(employeeName: "Max Scheulen",  orderTitle: "Gaubenanbau",         orderNumber: "AU-2026-009", date: d(2), color: .appPurple),
            WorkAssignment(employeeName: "Klaus Fischer", orderTitle: "Gaubenanbau",         orderNumber: "AU-2026-009", date: d(3), color: .appPurple),
            WorkAssignment(employeeName: "Max Scheulen",  orderTitle: "Dachsanierung",       orderNumber: "AU-2026-012", date: d(4), color: .appBlue),
        ]
    }()

    static var timeEntries: [TimeEntry] = {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        func at(h: Int, m: Int = 0, daysAgo: Int = 0) -> Date {
            let d = cal.date(byAdding: .day, value: -daysAgo, to: today)!
            return cal.date(bySettingHour: h, minute: m, second: 0, of: d)!
        }
        return [
            TimeEntry(employeeName: "Max Scheulen",  orderTitle: "Dachsanierung",
                      startTime: at(h: 7, m: 30), endTime: at(h: 16),           breakMinutes: 30),
            TimeEntry(employeeName: "Hans Weber",    orderTitle: "Dachsanierung",
                      startTime: at(h: 8),         endTime: at(h: 16, m: 30),   breakMinutes: 30),
            TimeEntry(employeeName: "Klaus Fischer", orderTitle: "Dachrinne erneuern",
                      startTime: at(h: 7),         endTime: at(h: 13),           breakMinutes: 0),
            TimeEntry(employeeName: "Max Scheulen",  orderTitle: "Neueindeckung Anbau",
                      startTime: at(h: 7, m: 30, daysAgo: 1), endTime: at(h: 17, daysAgo: 1),      breakMinutes: 45),
            TimeEntry(employeeName: "Hans Weber",    orderTitle: "Gaubenanbau",
                      startTime: at(h: 8, daysAgo: 1),        endTime: at(h: 15, m: 30, daysAgo: 1), breakMinutes: 30),
            TimeEntry(employeeName: "Klaus Fischer", orderTitle: "Flachdach Sanierung",
                      startTime: at(h: 7, daysAgo: 2),        endTime: at(h: 12, m: 30, daysAgo: 2), breakMinutes: 0),
        ]
    }()

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
