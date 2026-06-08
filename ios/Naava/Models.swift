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

    static let stats: [StatItem] = [
        StatItem(title: "Aufträge",   value: "12", icon: "briefcase.fill",       color: .appBlue),
        StatItem(title: "Angebote",   value: "5",  icon: "doc.text.fill",         color: .appOrange),
        StatItem(title: "Rechnungen", value: "8",  icon: "eurosign.circle.fill",  color: .appGreen),
        StatItem(title: "Mitarbeiter",value: "4",  icon: "person.2.fill",         color: .appPurple),
    ]
}
