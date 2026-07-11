//
//  CustomerTimeViews.swift  (05 Kunden, 06 TimeCard, 07 Zeiterfassung)
//

import SwiftUI

// MARK: - 05 Kundenübersicht

struct CustomerView: View {
    @EnvironmentObject var store: Store
    @State private var tab = 0

    private let quick: [(String, String)] = [
        ("phone.fill", "Anrufen"), ("envelope.fill", "Mail"),
        ("location.fill", "Navigation"), ("globe", "Website"), ("ellipsis", "Mehr"),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    Image(systemName: "building.2.fill").font(.system(size: 24)).foregroundColor(Theme.text2)
                        .frame(width: 54, height: 54).background(Theme.surface3)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Muster GmbH").font(.system(size: 20, weight: .heavy)).foregroundColor(Theme.text)
                        Text("Kunde seit 2018").font(.system(size: 13)).foregroundColor(Theme.text2)
                    }
                    Spacer()
                    Image(systemName: "star").foregroundColor(Theme.yellow)
                }.padding(.top, 6)

                HStack(spacing: 8) {
                    ForEach(quick, id: \.1) { icon, label in
                        VStack(spacing: 6) {
                            Image(systemName: icon).font(.system(size: 18)).foregroundColor(Theme.red2)
                                .frame(width: 52, height: 52).background(Theme.surface2)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line, lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            Text(label).font(.system(size: 11)).foregroundColor(Theme.text2)
                        }
                        .frame(maxWidth: .infinity)
                        .onTapGesture { store.showToast(label + "…") }
                    }
                }

                SegTabs(items: ["Übersicht", "Systeme", "Verträge", "Historie"], selection: $tab)

                Card {
                    Text("Ansprechpartner").font(.system(size: 12)).foregroundColor(Theme.text2)
                    Text("Herr Max Beispiel").font(.system(size: 15, weight: .bold)).foregroundColor(Theme.text).padding(.vertical, 4)
                    ContactRow(icon: "phone.fill", text: "01234 567890")
                    ContactRow(icon: "envelope.fill", text: "m.beispiel@muster-gmbh.de")
                    Text("Adresse").font(.system(size: 12)).foregroundColor(Theme.text2).padding(.top, 8)
                    ContactRow(icon: "mappin.circle.fill", text: "Hauptstraße 12, 12345 Musterstadt")
                }

                infoCard("desktopcomputer", "Installierte Systeme", "24 Systeme") { store.showToast("Systeme öffnen") }
                infoCard("clock.arrow.circlepath", "Letzter Einsatz", "23.05.2024 – Backup Check") { store.showToast("Einsatz öffnen") }
                infoCard("ticket.fill", "Offene Tickets", "2 Tickets") { store.go(.tickets) }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 100)
        }
    }

    private func infoCard(_ icon: String, _ title: String, _ sub: String, _ action: @escaping () -> Void) -> some View {
        Card {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.system(size: 18)).foregroundColor(Theme.text2).frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 15, weight: .bold)).foregroundColor(Theme.text)
                    Text(sub).font(.system(size: 12)).foregroundColor(Theme.text2)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(Theme.text3)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}

// MARK: - 06 TimeCard

struct TimeCardView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    PageTitle(text: "TimeCard")
                    IconButton(system: "calendar") { store.showToast("Kalender") }
                }.padding(.top, 6)

                // Hero
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.clockedIn ? "Eingestempelt seit" : "Nicht eingestempelt")
                            .font(.system(size: 13)).foregroundColor(.white.opacity(0.85))
                        Text(store.clockedIn ? "07:18 Uhr" : "—")
                            .font(.system(size: 26, weight: .bold)).foregroundColor(.white)
                    }
                    Spacer()
                    Button {
                        store.clockedIn.toggle()
                        store.showToast(store.clockedIn ? "Eingestempelt ✓" : "Ausgestempelt ✓")
                    } label: {
                        Text(store.clockedIn ? "Ausstempeln" : "Einstempeln")
                            .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                            .padding(.horizontal, 16).padding(.vertical, 12)
                            .background(Color.black.opacity(0.25))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.25), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }.buttonStyle(.plain)
                }
                .padding(20).background(Theme.redGrad)
                .clipShape(RoundedRectangle(cornerRadius: 26))
                .shadow(color: Theme.redGlow, radius: 12, y: 6)

                SectionHead(title: "Heute")
                Card {
                    InfoRow(icon: "clock.fill", label: "Arbeitszeit", value: "07:18 h")
                    Divider().overlay(Theme.line)
                    InfoRow(icon: "pause.fill", label: "Pause", value: "00:45 h")
                    Divider().overlay(Theme.line)
                    InfoRow(icon: "target", label: "Sollzeit", value: "08:00 h")
                }

                Button {
                    store.onBreak.toggle()
                    store.showToast(store.onBreak ? "Pause gestartet" : "Pause beendet")
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: store.onBreak ? "play.fill" : "pause.fill")
                        Text(store.onBreak ? "Pause beenden" : "Pause starten")
                    }
                    .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 15)
                    .background(Theme.redGrad).clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Theme.redGlow, radius: 10, y: 4)
                }.buttonStyle(.plain)

                SectionHead(title: "Diese Woche").padding(.top, 4)
                Card {
                    InfoRow(icon: "clock.fill", label: "Arbeitszeit", value: "39:15 h")
                    Divider().overlay(Theme.line)
                    InfoRow(icon: "target", label: "Sollzeit", value: "40:00 h")
                    Divider().overlay(Theme.line)
                    InfoRow(icon: "bolt.fill", label: "Überstunden", value: "-00:45 h", valueColor: Theme.red2)
                }

                // Zugang zur Zeiterfassung
                Button { store.go(.zeiterfassung) } label: {
                    HStack {
                        Image(systemName: "list.bullet.rectangle").foregroundColor(Theme.red2)
                        Text("Zeiterfassung öffnen").font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text)
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(Theme.text3)
                    }.padding(16).background(Theme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - 07 Zeiterfassung

struct ZeiterfassungView: View {
    @EnvironmentObject var store: Store
    @State private var tab = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    IconButton(system: "chevron.left") { store.go(.timecard) }
                    PageTitle(text: "Zeiterfassung")
                }.padding(.top, 6)

                SegTabs(items: ["Tag", "Woche", "Monat"], selection: $tab)

                HStack {
                    Image(systemName: "chevron.left").foregroundColor(Theme.text2)
                    Spacer()
                    Text("Freitag, 24.05.2024").font(.system(size: 15, weight: .bold)).foregroundColor(Theme.text)
                    Spacer()
                    Image(systemName: "chevron.right").foregroundColor(Theme.text2)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(Theme.surface)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Card {
                    ForEach(Sample.timeline.indices, id: \.self) { i in
                        let item = Sample.timeline[i]
                        HStack(alignment: .top, spacing: 16) {
                            VStack(spacing: 0) {
                                Circle().stroke(item.color, lineWidth: 3).frame(width: 14, height: 14)
                                    .background(Circle().fill(Theme.surface))
                                if i < Sample.timeline.count - 1 {
                                    Rectangle().fill(Theme.lineStrong).frame(width: 2, height: 34)
                                }
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.time).font(.system(size: 15, weight: .bold)).foregroundColor(Theme.text)
                                Text(item.label).font(.system(size: 13)).foregroundColor(Theme.text2)
                            }
                            Spacer()
                        }
                    }
                }

                Card {
                    InfoRow(icon: "clock.fill", label: "Arbeitszeit", value: "07:15 h")
                    Divider().overlay(Theme.line)
                    InfoRow(icon: "pause.fill", label: "Pause", value: "00:30 h")
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 100)
        }
    }
}
