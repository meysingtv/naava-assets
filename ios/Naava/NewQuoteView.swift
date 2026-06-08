import SwiftUI

struct NewQuoteView: View {
    let onCreate: (Quote) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var customerName = ""
    @State private var customerAddress = ""
    @State private var description = ""
    @State private var validDays = 30
    @State private var lineItems: [LineItem] = [
        LineItem(description: "", quantity: 1, unit: "Std.", unitPrice: 75),
    ]
    @State private var showCustomerPicker = false
    @State private var showAIAssistant    = false

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !customerName.isEmpty &&
        lineItems.contains(where: { !$0.description.trimmingCharacters(in: .whitespaces).isEmpty })
    }

    private var netTotal: Double { lineItems.reduce(0) { $0 + $1.total } }

    var body: some View {
        NavigationStack {
            Form {
                customerSection
                detailsSection
                lineItemsSection
            }
            .navigationTitle("Neues Angebot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(.appTextSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 14) {
                        Button(action: { showAIAssistant = true }) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.appBlue)
                        }
                        Button("Erstellen") { save() }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isValid ? .appBlue : .appTextSecondary)
                            .disabled(!isValid)
                    }
                }
            }
            .sheet(isPresented: $showAIAssistant) {
                AIQuoteAssistantView { aiTitle, aiItems in
                    title = aiTitle
                    lineItems = aiItems.map {
                        LineItem(description: $0.beschreibung,
                                 quantity:    $0.menge,
                                 unit:        $0.einheit,
                                 unitPrice:   $0.einzelpreis)
                    }
                }
            }
            .sheet(isPresented: $showCustomerPicker) {
                QuoteCustomerPicker { customer in
                    customerName    = customer.company ?? customer.fullName
                    customerAddress = "\(customer.street)\n\(customer.city)"
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
            .onTapGesture { showCustomerPicker = true }
        }
    }

    private var detailsSection: some View {
        Section("Angebot *") {
            TextField("Titel (z.B. Dachsanierung)", text: $title)
            TextField("Beschreibung (optional)", text: $description, axis: .vertical)
                .lineLimit(2...5)
            Stepper("Gültig: \(validDays) Tage", value: $validDays, in: 7...90, step: 7)
        }
    }

    private var lineItemsSection: some View {
        Section {
            ForEach($lineItems) { $item in
                QuoteLineItemRow(item: $item)
            }
            .onDelete { lineItems.remove(atOffsets: $0) }

            Button(action: {
                lineItems.append(LineItem(description: "", quantity: 1, unit: "Std.", unitPrice: 75))
            }) {
                Label("Position hinzufügen", systemImage: "plus.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appBlue)
            }
        } header: {
            Text("Positionen")
        } footer: {
            let gross = netTotal * 1.19
            Text("Netto \(Invoice.format(netTotal))  ·  Brutto \(Invoice.format(gross))")
                .font(.system(size: 12))
        }
    }

    // MARK: - Save

    private func save() {
        let validUntil = Calendar.current.date(byAdding: .day, value: validDays, to: Date()) ?? Date()
        let number = String(format: "AN-2026-%03d", DummyData.quotes.count + 6)
        let quote = Quote(
            number: number,
            customerName: customerName,
            customerAddress: customerAddress,
            title: title.trimmingCharacters(in: .whitespaces),
            description: description,
            lineItems: lineItems.filter { !$0.description.trimmingCharacters(in: .whitespaces).isEmpty },
            status: .draft,
            issueDate: Date(),
            validUntil: validUntil
        )
        onCreate(quote)
        dismiss()
    }
}

// MARK: - Editable Line Item Row

private struct QuoteLineItemRow: View {
    @Binding var item: LineItem

    @State private var qtyText: String = ""
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
                    .onChange(of: qtyText) { item.quantity = parseDouble($0) ?? item.quantity }
                    .onAppear { qtyText = formatNum(item.quantity) }

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
                    .onChange(of: priceText) { item.unitPrice = parseDouble($0) ?? item.unitPrice }
                    .onAppear { priceText = formatNum(item.unitPrice) }

                Text("€")
                    .font(.system(size: 13))
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

// MARK: - Customer Picker

private struct QuoteCustomerPicker: View {
    let onSelect: (Customer) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(DummyData.customers) { customer in
                Button(action: {
                    onSelect(customer)
                    dismiss()
                }) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(customer.avatarColor.opacity(0.15))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text(customer.initials)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(customer.avatarColor)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(customer.fullName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.appTextPrimary)
                            Text("\(customer.street), \(customer.city)")
                                .font(.system(size: 12))
                                .foregroundColor(.appTextSecondary)
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle("Kunde wählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Abbrechen") { dismiss() }.foregroundColor(.appBlue)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview { NewQuoteView { _ in } }
