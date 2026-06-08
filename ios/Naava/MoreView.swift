import SwiftUI

struct MoreView: View {
    private struct MenuItem: Identifiable {
        let id = UUID()
        let icon: String
        let label: String
        let color: Color
    }

    private struct MenuSection: Identifiable {
        let id = UUID()
        let title: String
        let items: [MenuItem]
    }

    private let sections: [MenuSection] = [
        MenuSection(title: "Verwaltung", items: [
            MenuItem(icon: "building.2.fill",       label: "Mein Betrieb",   color: .appBlue),
            MenuItem(icon: "person.2.fill",          label: "Mitarbeiter",    color: .appPurple),
            MenuItem(icon: "doc.richtext.fill",      label: "Dokumente",      color: .appOrange),
            MenuItem(icon: "chart.bar.fill",         label: "Auswertungen",   color: .appGreen),
        ]),
        MenuSection(title: "Einstellungen", items: [
            MenuItem(icon: "gear",                   label: "Einstellungen",  color: .appTextSecondary),
            MenuItem(icon: "questionmark.circle.fill",label: "Hilfe & Support",color: .appGreen),
            MenuItem(icon: "arrow.right.circle.fill",label: "Abmelden",       color: .red),
        ]),
    ]

    var body: some View {
        List {
            ForEach(sections) { section in
                Section(section.title) {
                    ForEach(section.items) { item in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(item.color.opacity(0.14))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: item.icon)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(item.color)
                                )
                            Text(item.label)
                                .font(.system(size: 16))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.appTextSecondary.opacity(0.5))
                        }
                        .padding(.vertical, 3)
                    }
                }
            }
        }
        .navigationTitle("Mehr")
        .toolbar(.hidden, for: .tabBar)
    }
}

#Preview {
    NavigationStack {
        MoreView()
    }
}
