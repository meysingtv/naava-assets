//
//  DashboardView.swift  (01 Dashboard)
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                BrandHeader(badge: 3).padding(.top, 6)

                // Begrüßungs-Karte
                VStack(alignment: .leading, spacing: 0) {
                    Text("Guten Morgen,").font(.system(size: 15)).foregroundColor(Theme.text2)
                    Text("\(Sample.userName)! 👋").font(.system(size: 24, weight: .bold)).foregroundColor(Theme.text)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Eingestempelt seit").font(.system(size: 12)).foregroundColor(Theme.text2)
                            HStack(spacing: 8) {
                                if store.clockedIn {
                                    Circle().fill(Theme.green).frame(width: 8, height: 8)
                                        .shadow(color: Theme.green, radius: 4)
                                }
                                Text(store.clockedIn ? "07:18 Uhr" : "—")
                                    .font(.system(size: 22, weight: .bold)).foregroundColor(Theme.text)
                            }
                        }
                        Spacer()
                        Button {
                            store.clockedIn.toggle()
                            store.showToast(store.clockedIn ? "Eingestempelt ✓" : "Ausgestempelt ✓")
                        } label: {
                            Text(store.clockedIn ? "Ausstempeln" : "Einstempeln")
                                .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                                .padding(.horizontal, 18).padding(.vertical, 12)
                                .background(Theme.redGrad).clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: Theme.redGlow, radius: 10, y: 4)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(14)
                    .background(Color.black.opacity(0.28))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.top, 16)
                }
                .padding(18)
                .background(
                    LinearGradient(colors: [Color(hex: 0x1a1013), Color(hex: 0x141419)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .overlay(RoundedRectangle(cornerRadius: 26).stroke(Theme.red.opacity(0.18), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 26))

                // Statistiken
                HStack(spacing: 10) {
                    StatTile(n: "8", label: "Offene Tickets")
                    StatTile(n: "2", label: "Dringend", color: Theme.red2)
                    StatTile(n: "1", label: "Termine heute", color: Theme.amber)
                    StatTile(n: "1", label: "Bereitschaft", color: Theme.blue)
                }

                // Nächster Termin
                SectionHead(title: "Nächster Termin")
                Card {
                    HStack(spacing: 14) {
                        Text("10:00")
                            .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                            .padding(.vertical, 12).padding(.horizontal, 10)
                            .frame(minWidth: 62)
                            .background(Theme.redGrad).clipShape(RoundedRectangle(cornerRadius: 14))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Muster GmbH").font(.system(size: 15, weight: .bold)).foregroundColor(Theme.text)
                            Text("Firewall Check").font(.system(size: 13)).foregroundColor(Theme.text2)
                            Text("Hauptstraße 12, 12345 Musterstadt").font(.system(size: 12)).foregroundColor(Theme.text3)
                        }
                        Spacer()
                        Button { store.showToast("Navigation gestartet…") } label: {
                            Image(systemName: "location.north.fill").foregroundColor(Theme.text)
                                .frame(width: 40, height: 40).background(Theme.surface2)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }.buttonStyle(.plain)
                    }
                }

                // Aktuelle TimeCard
                SectionHead(title: "Aktuelle TimeCard")
                Card {
                    HStack(spacing: 18) {
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Arbeitszeit heute").font(.system(size: 12)).foregroundColor(Theme.text2)
                                Text("07:18 h").font(.system(size: 20, weight: .bold)).foregroundColor(Theme.text)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Pause").font(.system(size: 12)).foregroundColor(Theme.text2)
                                Text("00:45 h").font(.system(size: 20, weight: .bold)).foregroundColor(Theme.text)
                            }
                        }
                        Spacer()
                        ProgressRing(pct: 75, sub: "Ziel erreicht")
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 100)
        }
    }
}
