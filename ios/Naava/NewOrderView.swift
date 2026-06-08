import SwiftUI

struct NewOrderView: View {
    var onSave: (Order) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var customerName = ""
    @State private var address = ""
    @State private var description = ""
    @State private var date = Date()
    @State private var hours = ""
    @State private var showCustomerPicker = false

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !customerName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var nextNumber: String {
        let count = DummyData.orders.count + 1
        return String(format: "AU-2026-%03d", count + 12)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Auftrag *") {
                    TextField("Titel (z.B. Dachsanierung)", text: $title)
                    DatePicker("Datum", selection: $date, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "de_DE"))
                }

                Section("Kunde *") {
                    HStack {
                        if customerName.isEmpty {
                            Text("Kunde wählen…")
                                .foregroundColor(.appTextSecondary)
                        } else {
                            Text(customerName)
                                .foregroundColor(.appTextPrimary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.appTextSecondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { showCustomerPicker = true }

                    TextField("Adresse", text: $address)
                        .textContentType(.fullStreetAddress)
                }

                Section("Details") {
                    TextField("Beschreibung der Arbeiten", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.appGreen)
                        TextField("Geschätzte Stunden", text: $hours)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle("Neuer Auftrag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(.appTextSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Erstellen") { save() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isValid ? .appBlue : .appTextSecondary)
                        .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showCustomerPicker) {
                CustomerPickerSheet(selected: $customerName)
            }
        }
    }

    private func save() {
        let order = Order(
            number: nextNumber,
            title: title.trimmingCharacters(in: .whitespaces),
            customerName: customerName,
            address: address,
            description: description,
            status: .open,
            date: date,
            estimatedHours: Double(hours)
        )
        onSave(order)
        dismiss()
    }
}

private struct CustomerPickerSheet: View {
    @Binding var selected: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(DummyData.customers) { customer in
                Button(action: {
                    selected = customer.company ?? customer.fullName
                    dismiss()
                }) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(customer.avatarColor.opacity(0.15))
                            .frame(width: 36, height: 36)
                            .overlay(Text(customer.initials)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(customer.avatarColor))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(customer.fullName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.appTextPrimary)
                            if let c = customer.company {
                                Text(c).font(.system(size: 12)).foregroundColor(.appTextSecondary)
                            }
                        }
                        Spacer()
                        if selected == (customer.company ?? customer.fullName) {
                            Image(systemName: "checkmark").foregroundColor(.appBlue)
                        }
                    }
                }
            }
            .navigationTitle("Kunde wählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }.foregroundColor(.appBlue)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview { NewOrderView { _ in } }
