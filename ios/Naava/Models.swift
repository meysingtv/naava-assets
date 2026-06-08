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

// MARK: - Dummy Data
enum DummyData {
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
}
