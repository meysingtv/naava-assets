import SwiftUI

struct EinstellungenView: View {
    @EnvironmentObject var appState: AppState

    @AppStorage("defaultTaxRate")     private var taxRate: Int    = 19
    @AppStorage("paymentDays")        private var paymentDays: Int = 14
    @AppStorage("invoicePrefix")      private var invoicePrefix: String = "RE"
    @AppStorage("quotePrefix")        private var quotePrefix: String   = "AN"

    @State private var showLogoutAlert = false

    var body: some View {
        List {
            firmaSection
            rechnungenSection
            abonnementSection
            appSection
            abmeldenSection
        }
        .navigationTitle("Einstellungen")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .alert("Abmelden?", isPresented: $showLogoutAlert) {
            Button("Abmelden", role: .destructive) { appState.logout() }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Du wirst aus Naava abgemeldet.")
        }
    }

    // MARK: - Sections

    private var firmaSection: some View {
        Section("Firma") {
            NavigationLink(destination: CompanyProfileView().toolbar(.hidden, for: .tabBar)) {
                settingsRow(icon: "building.2.fill", color: .appBlue, label: "Firmenprofil",
                            value: appState.companyName.isEmpty ? "Nicht eingerichtet" : appState.companyName)
            }
        }
    }

    private var rechnungenSection: some View {
        Section("Rechnungen & Angebote") {
            Picker(selection: $taxRate) {
                Text("19% (Standard)").tag(19)
                Text("7% (ermäßigt)").tag(7)
            } label: {
                settingsRowLabel(icon: "percent", color: .appGreen, label: "Standard-MwSt.")
            }

            Picker(selection: $paymentDays) {
                Text("7 Tage").tag(7)
                Text("14 Tage").tag(14)
                Text("30 Tage").tag(30)
            } label: {
                settingsRowLabel(icon: "calendar.badge.clock", color: .appOrange, label: "Zahlungsziel")
            }

            HStack {
                settingsRowLabel(icon: "doc.text.fill", color: .appPurple, label: "Rechnungs-Präfix")
                Spacer()
                TextField("RE", text: $invoicePrefix)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                    .foregroundColor(.appTextSecondary)
            }

            HStack {
                settingsRowLabel(icon: "doc.badge.plus", color: .appOrange, label: "Angebots-Präfix")
                Spacer()
                TextField("AN", text: $quotePrefix)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                    .foregroundColor(.appTextSecondary)
            }
        }
    }

    private var abonnementSection: some View {
        Section("Abonnement") {
            NavigationLink(destination: PlanSelectionView().toolbar(.hidden, for: .tabBar)) {
                settingsRow(icon: appState.selectedPlan.icon,
                            color: appState.selectedPlan.color,
                            label: "Aktueller Plan",
                            value: "\(appState.selectedPlan.rawValue) – \(appState.selectedPlan.monthlyPrice) €/Monat")
            }
        }
    }

    private var appSection: some View {
        Section("App") {
            settingsRow(icon: "number",         color: .appTextSecondary, label: "Version",    value: "1.0.0 (1)")
            settingsRow(icon: "iphone",         color: .appTextSecondary, label: "Plattform",  value: "iOS")
            settingsRow(icon: "building.2",     color: .appTextSecondary, label: "Entwickelt von", value: "Naava GmbH")
        }
    }

    private var abmeldenSection: some View {
        Section {
            Button(action: { showLogoutAlert = true }) {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.12))
                        .frame(width: 30, height: 30)
                        .overlay(Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.red))
                    Text("Abmelden")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                }
            }
        }
    }

    // MARK: - Helpers

    private func settingsRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            settingsRowLabel(icon: icon, color: color, label: label)
            Spacer()
            Text(value)
                .font(.system(size: 13))
                .foregroundColor(.appTextSecondary)
                .lineLimit(1)
        }
    }

    private func settingsRowLabel(icon: String, color: Color, label: String) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 7)
                .fill(color.opacity(0.15))
                .frame(width: 30, height: 30)
                .overlay(Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(color))
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.appTextPrimary)
        }
    }
}

#Preview {
    NavigationStack {
        EinstellungenView()
            .environmentObject({ let s = AppState(); s.companyName = "Mustermann GmbH"; return s }())
    }
}
