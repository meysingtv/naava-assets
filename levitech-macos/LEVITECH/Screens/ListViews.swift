//
//  ListViews.swift  (08–13 + Mehr)
//

import SwiftUI

// MARK: - Mehr (Übersicht + Features)

struct MoreView: View {
    @EnvironmentObject var store: Store

    private let links: [(AppScreen, String, String)] = [
        (.zeiterfassung, "list.bullet.rectangle", "Zeiterfassung"),
        (.notifications, "bell.fill", "Benachrichtigungen"),
        (.passwords, "key.fill", "Passwörter"),
        (.ki, "sparkles", "KI Assistent"),
        (.checklists, "checklist", "Checklisten"),
        (.documents, "doc.fill", "Dokumente"),
        (.customer, "building.2.fill", "Kunden"),
        (.profile, "person.fill", "Profil"),
    ]

    let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                PageTitle(text: "Mehr").padding(.top, 6)

                Card(padding: 4) {
                    ForEach(links.indices, id: \.self) { i in
                        let (screen, icon, label) = links[i]
                        HStack(spacing: 16) {
                            Image(systemName: icon).foregroundColor(Theme.red2).frame(width: 24)
                            Text(label).font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(Theme.text3)
                        }
                        .padding(.vertical, 15).padding(.horizontal, 12)
                        .contentShape(Rectangle())
                        .onTapGesture { store.go(screen) }
                        if i < links.count - 1 { Divider().overlay(Theme.line).padding(.leading, 12) }
                    }
                }

                SectionHead(title: "Funktionen").padding(.top, 4)
                LazyVGrid(columns: cols, spacing: 12) {
                    ForEach(Sample.features) { f in
                        VStack(alignment: .leading, spacing: 6) {
                            Image(systemName: f.icon).font(.system(size: 20)).foregroundColor(Theme.red2)
                                .frame(width: 44, height: 44)
                                .background(Theme.red.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 12))
                            Text(f.title).font(.system(size: 14, weight: .bold)).foregroundColor(Theme.text)
                            Text(f.sub).font(.system(size: 12)).foregroundColor(Theme.text2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16).background(Theme.surface)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - 08 Benachrichtigungen

struct NotificationsView: View {
    @EnvironmentObject var store: Store
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    IconButton(system: "chevron.left") { store.go(.more) }
                    PageTitle(text: "Mitteilungen")
                    IconButton(system: "checkmark") { store.showToast("Alle gelesen") }
                }.padding(.top, 6)

                Card {
                    ForEach(Sample.notifications.indices, id: \.self) { i in
                        let n = Sample.notifications[i]
                        HStack(spacing: 14) {
                            Image(systemName: n.icon).font(.system(size: 20)).foregroundColor(n.color)
                                .frame(width: 44, height: 44)
                                .background(n.color.opacity(0.14)).clipShape(RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(n.title).font(.system(size: 15, weight: .bold)).foregroundColor(Theme.text)
                                Text(n.sub).font(.system(size: 13)).foregroundColor(Theme.text2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                            Text(n.when).font(.system(size: 12)).foregroundColor(Theme.text3)
                        }
                        .padding(.vertical, 12)
                        if i < Sample.notifications.count - 1 { Divider().overlay(Theme.line) }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - 09 Passwortmanager

struct PasswordsView: View {
    @EnvironmentObject var store: Store
    @State private var query = ""
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    IconButton(system: "chevron.left") { store.go(.more) }
                    PageTitle(text: "Passwörter")
                    IconButton(system: "plus") { store.showToast("Neues Passwort") }
                }.padding(.top, 6)

                SearchBar(text: $query)

                Card {
                    ForEach($store.passwords) { $p in
                        HStack(spacing: 14) {
                            Image(systemName: p.icon).font(.system(size: 18)).foregroundColor(Theme.red2)
                                .frame(width: 44, height: 44).background(Theme.surface2)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(p.title).font(.system(size: 15, weight: .bold)).foregroundColor(Theme.text)
                                Text(p.revealed ? p.sub : "••••••").font(.system(size: 13)).foregroundColor(Theme.text2)
                            }
                            Spacer()
                            if p.starred {
                                Image(systemName: "star.fill").foregroundColor(Theme.yellow)
                            }
                            Button { $p.revealed.wrappedValue.toggle() } label: {
                                Image(systemName: p.revealed ? "eye.slash" : "eye").foregroundColor(Theme.text3)
                            }.buttonStyle(.plain)
                        }
                        .padding(.vertical, 12)
                        if p.id != store.passwords.last?.id { Divider().overlay(Theme.line) }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - 11 Checklisten

struct ChecklistsView: View {
    @EnvironmentObject var store: Store
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    IconButton(system: "chevron.left") { store.go(.more) }
                    PageTitle(text: "Checklisten")
                }.padding(.top, 6)

                Card {
                    Text("Serverwartung").font(.system(size: 17, weight: .bold)).foregroundColor(Theme.text)
                    Text("\(store.checkDone) / \(store.checklist.count) erledigt")
                        .font(.system(size: 12)).foregroundColor(Theme.text2)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.surface3).frame(height: 8)
                            Capsule().fill(Theme.redGrad)
                                .frame(width: geo.size.width * CGFloat(store.checkDone) / CGFloat(store.checklist.count), height: 8)
                        }
                    }.frame(height: 8).padding(.top, 8)
                }

                Card {
                    ForEach(store.checklist) { item in
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(item.done ? Theme.green : Color.clear)
                                    .frame(width: 26, height: 26)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(item.done ? Theme.green : Theme.lineStrong, lineWidth: 2))
                                if item.done { Image(systemName: "checkmark").font(.system(size: 13, weight: .bold)).foregroundColor(.white) }
                            }
                            Text(item.label).font(.system(size: 15, weight: .semibold))
                                .foregroundColor(item.done ? Theme.text3 : Theme.text)
                                .strikethrough(item.done, color: Theme.text3)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(Theme.text3)
                        }
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                        .onTapGesture { withAnimation(.easeOut(duration: 0.15)) { store.toggleCheck(item) } }
                        if item.id != store.checklist.last?.id { Divider().overlay(Theme.line) }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - 12 Dokumente

struct DocumentsView: View {
    @EnvironmentObject var store: Store
    @State private var query = ""
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    IconButton(system: "chevron.left") { store.go(.more) }
                    PageTitle(text: "Dokumente")
                }.padding(.top, 6)

                SearchBar(text: $query)

                Card {
                    ForEach(Sample.documents) { d in
                        HStack(spacing: 14) {
                            Text(d.type.uppercased())
                                .font(.system(size: 11, weight: .black)).foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(LinearGradient(colors: [d.color, d.color.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(d.name).font(.system(size: 15, weight: .bold)).foregroundColor(Theme.text)
                                Text(d.meta).font(.system(size: 12)).foregroundColor(Theme.text2)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(Theme.text3)
                        }
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                        .onTapGesture { store.showToast("Öffne \(d.name)") }
                        if d.id != Sample.documents.last?.id { Divider().overlay(Theme.line) }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - 13 Profil

struct ProfileView: View {
    @EnvironmentObject var store: Store
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    IconButton(system: "chevron.left") { store.go(.more) }
                    Spacer()
                }.padding(.top, 6)

                HStack(spacing: 14) {
                    Circle().fill(LinearGradient(colors: [Color(hex: 0x3a3a44), Color(hex: 0x22222a)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 64, height: 64)
                        .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 2))
                        .overlay(Image(systemName: "person.fill").font(.system(size: 26)).foregroundColor(Theme.text2))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Sample.userName).font(.system(size: 20, weight: .heavy)).foregroundColor(Theme.text)
                        Text(Sample.userRole).font(.system(size: 13)).foregroundColor(Theme.text2)
                    }
                    Spacer()
                }

                Card {
                    ForEach(Sample.profileMenu) { m in
                        HStack(spacing: 16) {
                            Image(systemName: m.icon).foregroundColor(Theme.red2).frame(width: 24)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(m.label).font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text)
                                if let s = m.sub { Text(s).font(.system(size: 12)).foregroundColor(Theme.text2) }
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(Theme.text3)
                        }
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                        .onTapGesture { store.showToast(m.label) }
                        if m.id != Sample.profileMenu.last?.id { Divider().overlay(Theme.line) }
                    }
                }

                RedButton(title: "Abmelden") { store.showToast("Abgemeldet") }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 100)
        }
    }
}
