import SwiftUI

struct NewCustomerView: View {
    var onSave: (Customer) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var customerType: CustomerType = .person
    @State private var salutation: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var company: String = ""
    @State private var taxId: String = ""
    @State private var phone: String = ""
    @State private var mobile: String = ""
    @State private var email: String = ""
    @State private var website: String = ""
    @State private var street: String = ""
    @State private var zip: String = ""
    @State private var city: String = ""
    @State private var notes: String = ""

    private var isValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !phone.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Kundentyp
                Section {
                    Picker("Kundentyp", selection: $customerType) {
                        ForEach(CustomerType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                // MARK: - Person
                Section("Person *") {
                    Picker("Anrede", selection: $salutation) {
                        Text("Keine").tag("")
                        Text("Herr").tag("Herr")
                        Text("Frau").tag("Frau")
                        Text("Divers").tag("Divers")
                    }
                    .pickerStyle(.menu)

                    TextField("Vorname *", text: $firstName)
                        .textContentType(.givenName)

                    TextField("Nachname *", text: $lastName)
                        .textContentType(.familyName)
                }

                // MARK: - Unternehmen
                Section(customerType == .business ? "Unternehmen *" : "Unternehmen") {
                    TextField("Firmenname", text: $company)
                        .textContentType(.organizationName)

                    if customerType == .business {
                        HStack {
                            Image(systemName: "number")
                                .foregroundColor(.appPurple)
                                .frame(width: 22)
                            TextField("USt-IdNr. (optional)", text: $taxId)
                        }
                    }
                }

                // MARK: - Kontakt
                Section("Kontakt *") {
                    contactRow(
                        icon: "phone.fill", color: .appGreen,
                        placeholder: "Telefon *", text: $phone,
                        keyboard: .phonePad
                    )
                    contactRow(
                        icon: "iphone", color: .appBlue,
                        placeholder: "Mobil", text: $mobile,
                        keyboard: .phonePad
                    )
                    contactRow(
                        icon: "envelope.fill", color: .appOrange,
                        placeholder: "E-Mail", text: $email,
                        keyboard: .emailAddress,
                        autocap: .never
                    )
                    contactRow(
                        icon: "globe", color: .appPurple,
                        placeholder: "Website", text: $website,
                        keyboard: .URL,
                        autocap: .never
                    )
                }

                // MARK: - Adresse
                Section("Adresse") {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.fill")
                            .foregroundColor(.appOrange)
                            .frame(width: 22)
                        TextField("Straße & Hausnummer", text: $street)
                            .textContentType(.streetAddressLine1)
                    }
                    HStack(spacing: 8) {
                        TextField("PLZ", text: $zip)
                            .keyboardType(.numberPad)
                            .frame(width: 70)
                        TextField("Ort *", text: $city)
                    }
                }

                // MARK: - Notizen
                Section("Notizen") {
                    TextField("Interne Notizen (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .navigationTitle("Neuer Kunde")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                    .foregroundColor(.appTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        save()
                    }
                    .foregroundColor(.appBlue)
                    .disabled(!isValid)
                }
            }
        }
    }

    // MARK: - Helpers

    private func contactRow(
        icon: String,
        color: Color,
        placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default,
        autocap: TextInputAutocapitalization = .sentences
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 22)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(autocap)
        }
    }

    // MARK: - Save

    private func save() {
        let palette: [Color] = [.appBlue, .appGreen, .appOrange, .appPurple]
        let color = palette[abs(lastName.hashValue) % 4]
        let newCustomer = Customer(
            firstName: firstName.trimmingCharacters(in: .whitespaces),
            lastName: lastName.trimmingCharacters(in: .whitespaces),
            company: company.isEmpty ? nil : company,
            customerType: customerType,
            salutation: salutation,
            phone: phone,
            mobile: mobile,
            fax: "",
            email: email,
            website: website,
            street: street,
            zip: zip,
            city: city,
            avatarColor: color,
            taxId: taxId,
            notes: notes
        )
        onSave(newCustomer)
        dismiss()
    }
}

#Preview {
    NewCustomerView { customer in
        print("Saved: \(customer.fullName)")
    }
}
