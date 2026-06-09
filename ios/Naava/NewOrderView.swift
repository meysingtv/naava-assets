import SwiftUI

struct NewOrderView: View {
    var onSave: (Order) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title          = ""
    @State private var orderType: OrderType     = .sonstiges
    @State private var status: OrderStatus      = .open
    @State private var priority: OrderPriority  = .normal
    @State private var customerName   = ""
    @State private var customerAddress = ""
    @State private var address        = ""
    @State private var startDate      = Date()
    @State private var hasEndDate     = false
    @State private var endDate        = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var hours          = ""
    @State private var description    = ""
    @State private var notes          = ""
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
                auftragSection
                prioritySection
                customerSection
                baustelleSection
                zeitplanungSection
                descriptionSection
                notesSection
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
                OrderCustomerPickerSheet { customer in
                    customerName    = customer.company ?? customer.fullName
                    customerAddress = "\(customer.street)\n\(customer.zip) \(customer.city)"
                    if address.isEmpty {
                        address = "\(customer.street), \(customer.zip) \(customer.city)"
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var auftragSection: some View {
        Section("Auftrag *") {
            TextField("Bezeichnung (z.B. Dachsanierung Einfamilienhaus)", text: $title)

            Picker("Art der Arbeit", selection: $orderType) {
                ForEach(OrderType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.menu)

            Picker("Status", selection: $status) {
                ForEach(OrderStatus.allCases, id: \.self) { s in
                    Label(s.rawValue, systemImage: s.icon).tag(s)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var prioritySection: some View {
        Section("Priorität") {
            HStack(spacing: 6) {
                ForEach(OrderPriority.allCases, id: \.self) { p in
                    Button(action: { priority = p }) {
                        HStack(spacing: 4) {
                            Image(systemName: p.icon)
                                .font(.system(size: 11, weight: .semibold))
                            Text(p.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(
                            priority == p
                                ? p.color
                                : p.color.opacity(0.12)
                        )
                        .foregroundColor(
                            priority == p ? .white : p.color
                        )
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

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

    private var baustelleSection: some View {
        Section {
            HStack(spacing: 10) {
                Image(systemName: "mappin.fill")
                    .foregroundColor(.appOrange)
                    .frame(width: 20)
                TextField("Straße & Ort (optional)", text: $address)
            }
        } header: {
            Text("Baustelle")
        } footer: {
            Text("Leer lassen wenn gleich wie Kundenadresse")
                .font(.system(size: 12))
                .foregroundColor(.appTextSecondary)
        }
    }

    private var zeitplanungSection: some View {
        Section("Zeitplanung") {
            DatePicker("Startdatum", selection: $startDate, displayedComponents: .date)
                .environment(\.locale, Locale(identifier: "de_DE"))

            Toggle("Enddatum festlegen", isOn: $hasEndDate)

            if hasEndDate {
                DatePicker("Enddatum", selection: $endDate, in: startDate..., displayedComponents: .date)
                    .environment(\.locale, Locale(identifier: "de_DE"))
            }

            HStack(spacing: 10) {
                Image(systemName: "clock.fill")
                    .foregroundColor(.appGreen)
                    .frame(width: 20)
                TextField("Geschätzte Stunden", text: $hours)
                    .keyboardType(.decimalPad)
            }
        }
    }

    private var descriptionSection: some View {
        Section("Beschreibung der Arbeiten") {
            TextField("Beschreibung der Arbeiten", text: $description, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    private var notesSection: some View {
        Section("Interne Notizen") {
            TextField("Hinweise für das Team (optional)", text: $notes, axis: .vertical)
                .lineLimit(2, reservesSpace: true)
        }
    }

    // MARK: - Save

    private func save() {
        let parsedHours = Double(hours.replacingOccurrences(of: ",", with: "."))
        let finalAddress = address.trimmingCharacters(in: .whitespaces).isEmpty
            ? customerAddress.replacingOccurrences(of: "\n", with: ", ")
            : address.trimmingCharacters(in: .whitespaces)

        let order = Order(
            number:         nextNumber,
            title:          title.trimmingCharacters(in: .whitespaces),
            orderType:      orderType,
            priority:       priority,
            customerName:   customerName,
            address:        finalAddress,
            description:    description,
            status:         status,
            date:           startDate,
            endDate:        hasEndDate ? endDate : nil,
            estimatedHours: parsedHours,
            notes:          notes
        )
        onSave(order)
        dismiss()
    }
}

// MARK: - Customer Picker Sheet

private struct OrderCustomerPickerSheet: View {
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
                            Text("\(customer.street), \(customer.zip) \(customer.city)")
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

#Preview { NewOrderView { _ in } }
