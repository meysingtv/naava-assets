import SwiftUI

struct NewCustomerView: View {
    var onSave: (Customer) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var firstName  = ""
    @State private var lastName   = ""
    @State private var company    = ""
    @State private var phone      = ""
    @State private var email      = ""
    @State private var street     = ""
    @State private var city       = ""

    private var isValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !phone.trimmingCharacters(in: .whitespaces).isEmpty
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
                    TextField("Firma (optional)", text: $company)
                        .textContentType(.organizationName)
                }

                Section("Kontakt *") {
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.appGreen)
                            .frame(width: 22)
                        TextField("Telefon", text: $phone)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                    }
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.appBlue)
                            .frame(width: 22)
                        TextField("E-Mail (optional)", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                }

                Section("Adresse") {
                    HStack {
                        Image(systemName: "mappin.fill")
                            .foregroundColor(.appOrange)
                            .frame(width: 22)
                        TextField("Straße & Hausnummer", text: $street)
                            .textContentType(.streetAddressLine1)
                    }
                    TextField("Ort", text: $city)
                        .textContentType(.addressCity)
                }
            }
            .navigationTitle("Neuer Kunde")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(.appTextSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Speichern") { save() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isValid ? .appBlue : .appTextSecondary)
                        .disabled(!isValid)
                }
            }
        }
    }

    private func save() {
        let color = avatarColors[abs(lastName.hashValue) % avatarColors.count]
        let customer = Customer(
            firstName: firstName.trimmingCharacters(in: .whitespaces),
            lastName:  lastName.trimmingCharacters(in: .whitespaces),
            company:   company.isEmpty ? nil : company,
            phone:     phone,
            email:     email,
            street:    street,
            city:      city,
            avatarColor: color
        )
        onSave(customer)
        dismiss()
    }
}

#Preview {
    NewCustomerView { _ in }
}
