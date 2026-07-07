import SwiftUI

struct NewInvoiceView: View {
    var onSave: (Invoice) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var customerName    = ""
    @State private var customerAddress = ""
    @State private var orderTitle      = ""
    @State private var issueDate       = Date()
    @State private var taxRate: Double = 0.19
    @State private var paymentTermsDays: Int = 14
    @State private var lineItems: [LineItem] = [
        LineItem(description: "", quantity: 1, unit: "Std.", unitPrice: 85)
    ]
    @State private var notes = ""
    @State private var showPicker = false

    private var netTotal: Double { lineItems.reduce(0) { $0 + $1.total } }
    private var taxAmount: Double { netTotal * taxRate }
    private var grossTotal: Double { netTotal + taxAmount }

    private var dueDate: Date {
        Calendar.current.date(byAdding: .day, value: paymentTermsDays, to: issueDate) ?? issueDate
    }

    private var isValid: Bool {
        !orderTitle.trimmingCharacters(in: .whitespaces).isEmpty &&
        !customerName.isEmpty &&
        lineItems.contains(where: {
            !$0.description.trimmingCharacters(in: .whitespaces).isEmpty && $0.unitPrice > 0
        })
    }

    var body: some View {
        NavigationStack {
            Form {
                customerSection
                detailsSection
                lineItemsSection
                taxAndDueDateSection
                totalSection
                notesSection
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
                    customerAddress = "\(customer.street)\n\(customer.zip) \(customer.city)"
                }
            }
        }
    }

    // MARK: - Sections

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

    private var detailsSection: some View {
        Section("Rechnungsdetails *") {
            TextField("Auftragsbezeichnung (z.B. Dachsanierung)", text: $orderTitle)
            DatePicker("Rechnungsdatum", selection: $issueDate, displayedComponents: .date)
                .environment(\.locale, Locale(identifier: "de_DE"))
        }
    }

    private var lineItemsSection: some View {
        Section {
            ForEach($lineItems) { $item in
                InvoiceLineItemRow(item: $item)
            }
            .onDelete { lineItems.remove(atOffsets: $0) }

            Button(action: {
                lineItems.append(LineItem(description: "", quantity: 1, unit: "Std.", unitPrice: 85))
            }) {
                Label("Position hinzufügen", systemImage: "plus.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appBlue)
            }
        } header: {
            Text("Positionen *")
        } footer: {
            Text("Netto gesamt: \(Invoice.format(netTotal))")
                .font(.system(size: 12))
        }
    }

    private var taxAndDueDateSection: some View {
        Section("Steuer & Fälligkeit") {
            Picker("MwSt.", selection: $taxRate) {
                Text("0 % (steuerbefreit)").tag(0.0)
                Text("7 % (ermäßigt)").tag(0.07)
                Text("19 % (Standard)").tag(0.19)
            }
            .pickerStyle(.menu)

            Picker("Zahlungsziel", selection: $paymentTermsDays) {
                ForEach([7, 14, 21, 30, 60], id: \.self) { n in
                    Text("\(n) Tage netto").tag(n)
                }
            }
            .pickerStyle(.menu)

            HStack {
                Text("Fällig am")
                    .foregroundColor(.appTextPrimary)
                Spacer()
                Text(dueDate, style: .date)
                    .foregroundColor(.appTextSecondary)
                    .environment(\.locale, Locale(identifier: "de_DE"))
            }
        }
    }

    private var totalSection: some View {
        Section("Gesamtbetrag") {
            HStack {
                Text("Nettobetrag")
                    .font(.system(size: 14))
                    .foregroundColor(.appTextSecondary)
                Spacer()
                Text(Invoice.format(netTotal))
                    .font(.system(size: 14))
                    .foregroundColor(.appTextSecondary)
            }
            HStack {
                Text("MwSt. \(taxRate == 0 ? "0" : taxRate == 0.07 ? "7" : "19") %")
                    .font(.system(size: 14))
                    .foregroundColor(.appTextSecondary)
                Spacer()
                Text(Invoice.format(taxAmount))
                    .font(.system(size: 14))
                    .foregroundColor(.appTextSecondary)
            }
            HStack {
                Text("Gesamtbetrag")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                Spacer()
                Text(Invoice.format(grossTotal))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.appBlue)
            }
        }
    }

    private var notesSection: some View {
        Section("Notizen") {
            TextField("Zahlungshinweis, Bankverbindung usw. (optional)",
                      text: $notes,
                      axis: .vertical)
                .lineLimit(3, reservesSpace: true)
        }
    }

    // MARK: - Save

    private func save() {
        let count = DummyData.invoices.count + 4
        let invoice = Invoice(
            number:          String(format: "R-2026-%03d", count),
            customerName:    customerName,
            customerAddress: customerAddress,
            orderTitle:      orderTitle.trimmingCharacters(in: .whitespaces),
            lineItems:       lineItems.filter {
                !$0.description.trimmingCharacters(in: .whitespaces).isEmpty
            },
            status:          .open,
            issueDate:       issueDate,
            dueDate:         dueDate,
            taxRate:         taxRate
        )
        onSave(invoice)
        dismiss()
    }
}

// MARK: - Line Item Row

private struct InvoiceLineItemRow: View {
    @Binding var item: LineItem

    @State private var qtyText: String   = ""
    @State private var priceText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Beschreibung", text: $item.description)
                .font(.system(size: 14, weight: .medium))

            HStack(spacing: 8) {
                TextField("Menge", text: $qtyText)
                    .keyboardType(.decimalPad)
                    .frame(width: 56)
                    .font(.system(size: 13))
                    .foregroundColor(.appTextSecondary)
                    .onAppear { qtyText = formatNum(item.quantity) }
                    .onChange(of: qtyText) { _, v in
                        if let d = parseDouble(v) { item.quantity = d }
                    }

                TextField("Einheit", text: $item.unit)
                    .frame(width: 60)
                    .font(.system(size: 13))
                    .foregroundColor(.appTextSecondary)

                Spacer()

                TextField("E-Preis €", text: $priceText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                    .onAppear { priceText = formatNum(item.unitPrice) }
                    .onChange(of: priceText) { _, v in
                        if let d = parseDouble(v) { item.unitPrice = d }
                    }

                Text("€")
                    .font(.system(size: 13))
                    .foregroundColor(.appTextSecondary)
            }

            if item.quantity > 0 && item.unitPrice > 0 {
                Text("= \(Invoice.format(item.total))")
                    .font(.system(size: 11))
                    .foregroundColor(.appTextSecondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func parseDouble(_ s: String) -> Double? {
        Double(s.replacingOccurrences(of: ",", with: "."))
    }
    private func formatNum(_ v: Double) -> String {
        v == 0 ? "" : (v.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(v))" : String(format: "%.2f", v))
    }
}

// MARK: - Customer Picker Sheet

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
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(customer.initials)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(customer.avatarColor)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(customer.fullName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.appTextPrimary)
                            Text("\(customer.zip) \(customer.city)")
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
