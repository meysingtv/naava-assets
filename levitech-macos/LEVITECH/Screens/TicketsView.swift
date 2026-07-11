//
//  TicketsView.swift  (02 Tickets, 03 Details, 04 Bearbeiten)
//

import SwiftUI

struct TicketsView: View {
    @EnvironmentObject var store: Store
    @State private var query = ""
    private let filters = ["Meine Tickets", "Offen", "Neu", "Dringend"]

    private var filtered: [Ticket] {
        Sample.tickets.filter {
            query.isEmpty ||
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.customer.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    PageTitle(text: "Tickets").padding(.top, 6)
                    SearchBar(text: $query)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(filters, id: \.self) { f in
                                let active = store.ticketFilter == f
                                Text(f)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(active ? .white : Theme.text2)
                                    .padding(.horizontal, 16).padding(.vertical, 9)
                                    .background(active ? AnyView(Theme.redGrad) : AnyView(Theme.surface2))
                                    .clipShape(Capsule())
                                    .onTapGesture { store.ticketFilter = f }
                            }
                        }
                    }

                    ForEach(filtered) { t in
                        TicketRow(ticket: t).onTapGesture { store.go(.ticketDetail) }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 100)
            }

            Button { store.showToast("Neues Ticket erstellen") } label: {
                Image(systemName: "plus").font(.system(size: 24, weight: .bold)).foregroundColor(.white)
                    .frame(width: 58, height: 58).background(Theme.redGrad).clipShape(Circle())
                    .shadow(color: Theme.redGlow, radius: 12, y: 6)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 18).padding(.bottom, 92)
        }
    }
}

struct TicketRow: View {
    let ticket: Ticket
    var body: some View {
        HStack(spacing: 0) {
            Rectangle().fill(ticket.priority.color).frame(width: 3)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(ticket.id).font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.text3)
                    Spacer()
                    Pill(text: ticket.priority.rawValue, color: ticket.priority.color)
                }
                Text(ticket.title).font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                HStack {
                    Text(ticket.customer).font(.system(size: 13)).foregroundColor(Theme.text2)
                    Spacer()
                    Pill(text: ticket.status, color: ticket.statusColor)
                }
            }
            .padding(15)
        }
        .background(Theme.surface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - 03 Ticket Details

struct TicketDetailView: View {
    @EnvironmentObject var store: Store
    @State private var tab = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Button { store.go(.tickets) } label: {
                        HStack(spacing: 6) { Image(systemName: "chevron.left"); Text("Zurück") }
                            .font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text)
                    }.buttonStyle(.plain)
                    Spacer()
                    Pill(text: "Dringend", color: Theme.red)
                }
                .padding(.top, 6)

                Text("#2024-1001").font(.system(size: 12)).foregroundColor(Theme.text3)
                Text("Server ausgefallen").font(.system(size: 26, weight: .heavy)).foregroundColor(Theme.text)
                Text("Muster GmbH").font(.system(size: 14)).foregroundColor(Theme.text2)

                SegTabs(items: ["Details", "Verlauf", "Anhänge", "Zeiten"], selection: $tab)

                Card {
                    Text("Kunde").font(.system(size: 12)).foregroundColor(Theme.text2)
                    Text("Muster GmbH").font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                        .padding(.bottom, 8)
                    Text("Ansprechpartner").font(.system(size: 12)).foregroundColor(Theme.text2)
                    ContactRow(icon: "person.fill", text: "Herr Max Beispiel")
                    ContactRow(icon: "phone.fill", text: "01234 567890")
                    ContactRow(icon: "envelope.fill", text: "m.beispiel@muster-gmbh.de")
                    Text("Adresse").font(.system(size: 12)).foregroundColor(Theme.text2).padding(.top, 6)
                    ContactRow(icon: "mappin.circle.fill", text: "Hauptstraße 12, 12345 Musterstadt")
                    HStack(spacing: 10) {
                        GhostButton(title: "Anrufen", systemImage: "phone.fill") { store.showToast("Anruf…") }
                        GhostButton(title: "Navigation", systemImage: "location.fill") { store.showToast("Navigation…") }
                    }.padding(.top, 12)
                }

                Card {
                    Text("Beschreibung").font(.system(size: 12)).foregroundColor(Theme.text2).padding(.bottom, 4)
                    Text("Der FileServer FS01 ist seit heute Morgen ausgefallen. Zugriff für alle Mitarbeiter nicht möglich.")
                        .font(.system(size: 14)).foregroundColor(Theme.text).fixedSize(horizontal: false, vertical: true)
                    VStack(spacing: 0) {
                        kv("Priorität", "Dringend", Theme.red2)
                        Divider().overlay(Theme.line)
                        kv("SLA", "24.05.2024 12:00")
                        Divider().overlay(Theme.line)
                        kv("Erstellt am", "24.05.2024 08:15")
                        Divider().overlay(Theme.line)
                        kv("Status", "In Bearbeitung", Theme.red2)
                    }.padding(.top, 10)
                }

                RedButton(title: "Arbeitsbeginn") { store.go(.ticketEdit) }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 100)
        }
    }

    private func kv(_ k: String, _ v: String, _ c: Color = Theme.text) -> some View {
        HStack {
            Text(k).font(.system(size: 13)).foregroundColor(Theme.text2).frame(width: 92, alignment: .leading)
            Text(v).font(.system(size: 14, weight: .semibold)).foregroundColor(c)
            Spacer()
        }.padding(.vertical, 11)
    }
}

// MARK: - 04 Ticket bearbeiten

struct TicketEditView: View {
    @EnvironmentObject var store: Store
    @State private var seconds = 35 * 60 + 42
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private struct Action { let icon: String; let label: String; let badge: String? }
    private let actions: [Action] = [
        .init(icon: "text.bubble", label: "Kommentar hinzufügen", badge: nil),
        .init(icon: "photo.on.rectangle", label: "Fotos & Dateien", badge: "3"),
        .init(icon: "clock", label: "Zeit buchen", badge: nil),
        .init(icon: "shippingbox", label: "Material hinzufügen", badge: "2"),
        .init(icon: "checklist", label: "Checkliste", badge: "2/6"),
        .init(icon: "signature", label: "Kundenunterschrift", badge: nil),
        .init(icon: "flag.checkered", label: "Ticket abschließen", badge: nil),
    ]

    private var clock: String {
        String(format: "%02d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                HStack {
                    IconButton(system: "chevron.left") { store.go(.ticketDetail) }
                    Spacer()
                    VStack(spacing: 1) {
                        Text("Ticket bearbeiten").font(.system(size: 17, weight: .bold)).foregroundColor(Theme.text)
                        Text("#2024-1001").font(.system(size: 12)).foregroundColor(Theme.text2)
                    }
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }.padding(.top, 6)

                // Timer
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill"); Text("Arbeitszeit läuft")
                    }.font(.system(size: 13)).foregroundColor(Theme.text2)
                    Text(clock).font(.system(size: 46, weight: .bold)).monospacedDigit().foregroundColor(Theme.text)
                    Text("— Arbeitszeit läuft").font(.system(size: 13)).foregroundColor(Theme.red2)
                }
                .frame(maxWidth: .infinity).padding(22)
                .background(LinearGradient(colors: [Color(hex: 0x1c1013), Color(hex: 0x141419)], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 26).stroke(Theme.red.opacity(0.25), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 26))
                .onReceive(timer) { _ in seconds += 1 }

                Card(padding: 4) {
                    ForEach(actions.indices, id: \.self) { i in
                        let a = actions[i]
                        HStack(spacing: 14) {
                            Image(systemName: a.icon).font(.system(size: 18)).foregroundColor(Theme.text2).frame(width: 26)
                            Text(a.label).font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text)
                            Spacer()
                            if let b = a.badge {
                                Text(b).font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                                    .padding(.horizontal, 7).padding(.vertical, 3)
                                    .background(Theme.red).clipShape(Capsule())
                            }
                            Image(systemName: "chevron.right").font(.system(size: 13)).foregroundColor(Theme.text3)
                        }
                        .padding(.vertical, 15).padding(.horizontal, 12)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if a.label == "Checkliste" { store.go(.checklists) }
                            else if a.label == "Ticket abschließen" { store.showToast("Ticket abgeschlossen ✓") }
                            else { store.showToast(a.label + "…") }
                        }
                        if i < actions.count - 1 { Divider().overlay(Theme.line).padding(.leading, 12) }
                    }
                }

                RedButton(title: "Speichern") {
                    store.showToast("Gespeichert ✓")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { store.go(.ticketDetail) }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 100)
        }
    }
}
