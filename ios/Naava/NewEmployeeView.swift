import SwiftUI

struct NewEmployeeView: View {
    let onCreate: (Employee) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var firstName  = ""
    @State private var lastName   = ""
    @State private var role       = EmployeeRole.geselle
    @State private var phone      = ""
    @State private var email      = ""
    @State private var hireDate   = Date()

    private var isValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private let avatarColors: [Color] = [.appBlue, .appGreen, .appOrange, .appPurple]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name *") {
                    TextField("Vorname", text: $firstName)
                        .textContentType(.givenName)
                    TextField("Nachname", text: $lastName)
                        .textContentType(.familyName)
                }

                Section("Rolle & Einstellungsdatum") {
                    Picker("Rolle", selection: $role) {
                        ForEach(EmployeeRole.allCases, id: \.self) { r in
                            Label(r.rawValue, systemImage: r.icon)
                                .tag(r)
                        }
                    }
                    DatePicker("Eingestellt am", selection: $hireDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "de_DE"))
                }

                Section("Kontakt") {
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.appGreen)
                            .frame(width: 24)
                        TextField("Telefon", text: $phone)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                    }
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.appBlue)
                            .frame(width: 24)
                        TextField("E-Mail", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                    }
                }

                Section {
                    previewRow
                } header: {
                    Text("Vorschau")
                }
            }
            .navigationTitle("Neuer Mitarbeiter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(.appTextSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Hinzufügen") { save() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isValid ? .appBlue : .appTextSecondary)
                        .disabled(!isValid)
                }
            }
        }
    }

    // MARK: - Preview Row

    private var previewRow: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(role.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Text(previewInitials)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(role.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(previewName.isEmpty ? "Vorname Nachname" : previewName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(previewName.isEmpty ? .appTextSecondary : .appTextPrimary)
                HStack(spacing: 4) {
                    Image(systemName: role.icon)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(role.color)
                    Text(role.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(role.color)
                }
            }
            Spacer()
            Circle()
                .fill(Color.appGreen)
                .frame(width: 10, height: 10)
        }
    }

    private var previewName: String {
        let f = firstName.trimmingCharacters(in: .whitespaces)
        let l = lastName.trimmingCharacters(in: .whitespaces)
        if f.isEmpty && l.isEmpty { return "" }
        return "\(f) \(l)".trimmingCharacters(in: .whitespaces)
    }

    private var previewInitials: String {
        let f = String(firstName.prefix(1)).uppercased()
        let l = String(lastName.prefix(1)).uppercased()
        if f.isEmpty && l.isEmpty { return "??" }
        return "\(f)\(l)"
    }

    // MARK: - Save

    private func save() {
        let emp = Employee(
            firstName:      firstName.trimmingCharacters(in: .whitespaces),
            lastName:       lastName.trimmingCharacters(in: .whitespaces),
            role:           role,
            phone:          phone.isEmpty ? "–" : phone,
            email:          email.isEmpty ? "–" : email,
            avatarColor:    role.color,
            hireDate:       hireDate,
            isActive:       true,
            hoursThisMonth: 0
        )
        onCreate(emp)
        dismiss()
    }
}

#Preview { NewEmployeeView { _ in } }
