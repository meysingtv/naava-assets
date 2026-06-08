import SwiftUI

struct MoreView: View {
    var body: some View {
        List {
            Section("Übersicht") {
                NavRow(icon: "calendar",              label: "Kalender",       color: .appBlue)   { CalendarView() }
                NavRow(icon: "eurosign.circle.fill",  label: "Rechnungen",     color: .appGreen)  { InvoicesView() }
                NavRow(icon: "doc.text.fill",         label: "Angebote",       color: .appOrange) { PlaceholderView(icon: "doc.text.fill", title: "Angebote", subtitle: "Kommt bald") }
            }

            Section("Betrieb") {
                NavRow(icon: "building.2.fill",       label: "Mein Betrieb",   color: .appBlue)   { PlaceholderView(icon: "building.2.fill", title: "Mein Betrieb", subtitle: "Kommt bald") }
                NavRow(icon: "person.2.fill",         label: "Mitarbeiter",    color: .appPurple) { PlaceholderView(icon: "person.2.fill", title: "Mitarbeiter", subtitle: "Kommt bald") }
                NavRow(icon: "chart.bar.fill",        label: "Auswertungen",   color: .appGreen)  { PlaceholderView(icon: "chart.bar.fill", title: "Auswertungen", subtitle: "Kommt bald") }
            }

            Section("Einstellungen") {
                NavRow(icon: "gear",                  label: "Einstellungen",  color: .appTextSecondary) { PlaceholderView(icon: "gear", title: "Einstellungen", subtitle: "Kommt bald") }
                NavRow(icon: "questionmark.circle.fill", label: "Hilfe & Support", color: .appGreen) { PlaceholderView(icon: "questionmark.circle.fill", title: "Hilfe", subtitle: "Kommt bald") }
            }

            Section {
                Button(action: {}) {
                    HStack {
                        iconBox(icon: "arrow.right.circle.fill", color: .red)
                        Text("Abmelden")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding(.vertical, 3)
                }
            }
        }
        .navigationTitle("Mehr")
        .toolbar(.hidden, for: .tabBar)
    }

    private func iconBox(icon: String, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(color.opacity(0.14))
            .frame(width: 36, height: 36)
            .overlay(Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color))
    }
}

// MARK: - Generic nav row helper

private struct NavRow<Destination: View>: View {
    let icon: String
    let label: String
    let color: Color
    @ViewBuilder var destination: () -> Destination

    var body: some View {
        NavigationLink(destination: destination().toolbar(.hidden, for: .tabBar)) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.14))
                    .frame(width: 36, height: 36)
                    .overlay(Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color))
                Text(label)
                    .font(.system(size: 16))
                    .foregroundColor(.appTextPrimary)
            }
            .padding(.vertical, 3)
        }
    }
}

#Preview {
    NavigationStack { MoreView() }
}
