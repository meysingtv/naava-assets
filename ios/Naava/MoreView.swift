import SwiftUI

struct MoreView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLogoutAlert = false

    var body: some View {
        List {
            companyHeader

            Section("Verwaltung") {
                NavRow(icon: "map.fill",              label: "Karte",       color: .appBlue)   { MapFullscreenView() }
                NavRow(icon: "calendar",             label: "Kalender",    color: .appBlue)   { CalendarView() }
                NavRow(icon: "eurosign.circle.fill", label: "Rechnungen",  color: .appGreen)  { InvoicesView() }
                NavRow(icon: "doc.text.fill",        label: "Angebote",    color: .appOrange) { QuotesView() }
                NavRow(icon: "person.2.fill",        label: "Mitarbeiter", color: .appPurple) { EmployeesView() }
                NavRow(icon: "chart.bar.fill",       label: "Auswertungen",color: .appGreen)  { PlaceholderView(icon: "chart.bar.fill", title: "Auswertungen", subtitle: "Kommt bald") }
            }

            Section("Einstellungen") {
                NavRow(icon: "gear",                   label: "Einstellungen",  color: .appTextSecondary) { PlaceholderView(icon: "gear", title: "Einstellungen", subtitle: "Kommt bald") }
                NavRow(icon: "questionmark.circle.fill",label: "Hilfe & Support",color: .appGreen) { PlaceholderView(icon: "questionmark.circle.fill", title: "Hilfe", subtitle: "Kommt bald") }
            }

            Section {
                Button(action: { showLogoutAlert = true }) {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.12))
                            .frame(width: 36, height: 36)
                            .overlay(Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.red))
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
        .alert("Abmelden?", isPresented: $showLogoutAlert) {
            Button("Abmelden", role: .destructive) { appState.logout() }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Du wirst aus \(appState.companyName.isEmpty ? "Naava" : appState.companyName) abgemeldet.")
        }
    }

    // MARK: - Company header tile

    private var companyHeader: some View {
        Section {
            NavigationLink(destination: CompanyProfileView().toolbar(.hidden, for: .tabBar)) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(appState.selectedPlan.color.opacity(0.12))
                            .frame(width: 50, height: 50)
                        if appState.companyName.isEmpty {
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(appState.selectedPlan.color)
                        } else {
                            Text(String(appState.companyName.prefix(2)).uppercased())
                                .font(.system(size: 18, weight: .black))
                                .foregroundColor(appState.selectedPlan.color)
                        }
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(appState.companyName.isEmpty ? "Mein Betrieb" : appState.companyName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.appTextPrimary)
                        HStack(spacing: 4) {
                            Image(systemName: appState.selectedPlan.icon)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(appState.selectedPlan.color)
                            Text("\(appState.selectedPlan.rawValue)-Plan")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(appState.selectedPlan.color)
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 6)
            }
        }
    }
}

// MARK: - Nav Row

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
    NavigationStack {
        MoreView()
            .environmentObject({ let s = AppState(); s.companyName = "Mustermann Dachdeckerei"; return s }())
    }
}
