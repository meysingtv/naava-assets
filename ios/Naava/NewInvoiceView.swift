import SwiftUI

struct NewInvoiceView: View {
    var onSave: (Invoice) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var customerName    = ""
    @State private var customerAddress = ""
    @State private var orderTitle      = ""
    @State private var amountText      = ""
    @State private var issueDate       = Date()
    @State private var dueDate: Date   = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
    @State private var showPicker      = false

    private var parsedAmount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "."))
    }

    private var isValid: Bool {
        !orderTitle.trimmingCharacters(in: .whitespaces).isEmpty &&
        !customerName.isEmpty &&
        (parsedAmount ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                customerSection

                Section("Rechnung *") {
                    TextField("Auftragsbezeichnung", text: $orderTitle)
                }

                Section("Betrag (Netto, €) *") {
                    HStack {
                        Image(systemName: "eurosign.circle.fill")
                            .foregroundColor(.appGreen)
                            .frame(width: 22)
                        TextField("0,00", text: $amountText)
                            .keyboardType(.decimalPad)
                    }
                    if let amount = parsedAmount, amount > 0 {
                        HStack {
                            Text("Brutto inkl. 19% MwSt.")
                                .font(.system(size: 12))
                                .foregroundColor(.appTextSecondary)
                            Spacer()
                            Text(Invoice.format(amount * 1.19))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.appTextPrimary)
                        }
                    }
                }

                Section("Zeitraum") {
                    DatePicker("Rechnungsdatum", selection: $issueDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "de_DE"))
                    DatePicker("Fällig am", selection: $dueDate, in: issueDate..., displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "de_DE"))
                }
            }
            .navigationTitle("Neue Rechnung")
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
            .sheet(isPresented: $showPicker) {
                InvoiceCustomerPickerSheet { customer in
                    customerName    = customer.company ?? customer.fullName
                    customerAddress = "\(customer.street)\n\(customer.city)"
                }
            }
        }
    }

    // MARK: - Customer Row

    private var customerSection: some View {
        Section("Kunde *") {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    if customerName.isEmpty {
                        Text("Kunde wählen…")
                            .foregroundColor(.appTextSecondary)
                    } else {
                        Text(customerName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.appTextPrimary)
                        if !customerAddress.isEmpty {
                            Text(customerAddress.replacingOccurrences(of: "\n", with: " · "))
                                .font(.system(size: 12))
                                .foregroundColor(.appTextSecondary)
                        }
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.appTextSecondary)
            }
            .contentShape(Rectangle())
            .onTapGesture { showPicker = true }
        }
    }

    // MARK: - Save

    private func save() {
        let amount = parsedAmount ?? 0
        let item = LineItem(
            description: orderTitle.trimmingCharacters(in: .whitespaces),
            quantity: 1,
            unit: "Pauschal",
            unitPrice: amount
        )
        let count = DummyData.invoices.count + 1
        let invoice = Invoice(
            number:          String(format: "R-2026-%03d", count + 3),
            customerName:    customerName,
            customerAddress: customerAddress,
            orderTitle:      orderTitle.trimmingCharacters(in: .whitespaces),
            lineItems:       [item],
            status:          .open,
            issueDate:       issueDate,
            dueDate:         dueDate
        )
        onSave(invoice)
        dismiss()
    }
}

// MARK: - Customer Picker

private struct InvoiceCustomerPickerSheet: View {
    var onSelect: (Customer) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(DummyData.customers) { customer in
                Button {
                    onSelect(customer)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(customer.avatarColor.opacity(0.15))
                            .frame(width: 38, height: 38)
                            .overlay(
                                Text(customer.initials)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(customer.avatarColor)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(customer.fullName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.appTextPrimary)
                            Text(customer.city)
                                .font(.system(size: 12))
                                .foregroundColor(.appTextSecondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 3)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Kunde auswählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(.appBlue)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    NewInvoiceView { _ in }
}
