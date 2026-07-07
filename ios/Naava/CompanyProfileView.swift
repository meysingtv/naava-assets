import SwiftUI

struct CompanyProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var isEditing = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                profileHeader
                planBadge
                contactSection
                editButton
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
        .background(Color.appBackground)
        .navigationTitle("Mein Betrieb")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Fertig" : "Bearbeiten") {
                    withAnimation { isEditing.toggle() }
                }
                .foregroundColor(.appBlue)
                .font(.system(size: 15, weight: .semibold))
            }
        }
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: - Profile header

    private var profileHeader: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.appBlue.opacity(0.12))
                    .frame(width: 80, height: 80)
                if appState.companyName.isEmpty {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundColor(.appBlue)
                } else {
                    Text(String(appState.companyName.prefix(2)).uppercased())
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(.appBlue)
                }
            }
            VStack(spacing: 4) {
                editableText(value: $appState.companyName, placeholder: "Firmenname",
                             font: .system(size: 20, weight: .bold), alignment: .center)
                editableText(value: $appState.ownerName, placeholder: "Dein Name",
                             font: .system(size: 14), color: .appTextSecondary, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Plan badge

    private var planBadge: some View {
        HStack(spacing: 10) {
            Image(systemName: appState.selectedPlan.icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(appState.selectedPlan.color)
            Text("\(appState.selectedPlan.rawValue)-Plan")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(appState.selectedPlan.color)
            Spacer()
            NavigationLink(destination: PlanSelectionView { }.toolbar(.hidden, for: .tabBar)) {
                Text("Upgrade")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.appBlue)
                    .cornerRadius(20)
            }
        }
        .padding(14)
        .background(appState.selectedPlan.color.opacity(0.08))
        .cornerRadius(14)
    }

    // MARK: - Contact section

    private var contactSection: some View {
        VStack(spacing: 0) {
            profileRow(icon: "mappin.fill",      color: .appOrange, label: "Straße",   binding: $appState.companyStreet, placeholder: "Straße & Hausnummer")
            Divider().padding(.leading, 50)
            profileRow(icon: "building.columns.fill", color: .appBlue, label: "Ort",   binding: $appState.companyCity, placeholder: "PLZ & Ort")
            Divider().padding(.leading, 50)
            profileRow(icon: "phone.fill",       color: .appGreen,  label: "Telefon", binding: $appState.companyPhone, placeholder: "Telefonnummer")
            Divider().padding(.leading, 50)
            profileRow(icon: "envelope.fill",    color: .appBlue,   label: "E-Mail",  binding: $appState.companyEmail, placeholder: "Geschäftliche E-Mail")
            if !appState.companyTaxId.isEmpty || isEditing {
                Divider().padding(.leading, 50)
                profileRow(icon: "doc.text.fill", color: .appPurple, label: "USt-IdNr.", binding: $appState.companyTaxId, placeholder: "DE123456789")
            }
        }
        .cardStyle()
    }

    private func profileRow(icon: String, color: Color, label: String, binding: Binding<String>, placeholder: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.appTextSecondary)
                if isEditing {
                    TextField(placeholder, text: binding)
                        .font(.system(size: 14))
                        .foregroundColor(.appTextPrimary)
                } else {
                    Text(binding.wrappedValue.isEmpty ? placeholder : binding.wrappedValue)
                        .font(.system(size: 14))
                        .foregroundColor(binding.wrappedValue.isEmpty ? .appTextSecondary.opacity(0.5) : .appTextPrimary)
                }
            }
            Spacer()
            if isEditing {
                Image(systemName: "pencil")
                    .font(.system(size: 12))
                    .foregroundColor(.appTextSecondary.opacity(0.4))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    @ViewBuilder
    private func editableText(value: Binding<String>, placeholder: String, font: Font, color: Color = .appTextPrimary, alignment: TextAlignment) -> some View {
        if isEditing {
            TextField(placeholder, text: value)
                .font(font)
                .foregroundColor(color)
                .multilineTextAlignment(alignment)
        } else {
            Text(value.wrappedValue.isEmpty ? placeholder : value.wrappedValue)
                .font(font)
                .foregroundColor(value.wrappedValue.isEmpty ? color.opacity(0.4) : color)
        }
    }

    // MARK: - Edit button (when not editing)

    private var editButton: some View {
        Group {
            if !isEditing {
                Button(action: { withAnimation { isEditing = true } }) {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil")
                        Text("Betriebsdaten bearbeiten")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.appBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appBlue.opacity(0.08))
                    .cornerRadius(14)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CompanyProfileView()
            .environmentObject({ let s = AppState(); s.companyName = "Mustermann Dachdeckerei"; s.ownerName = "Max Mustermann"; return s }())
    }
}
