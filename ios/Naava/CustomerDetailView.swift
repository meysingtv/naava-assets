import SwiftUI

struct CustomerDetailView: View {
    let customer: Customer
    @Environment(\.openURL) private var openURL

    private let recentJobs: [(title: String, date: String, status: AppointmentStatus)] = [
        ("Dachsanierung",      "12.05.2026", .inProgress),
        ("Dachrinne erneuern", "03.03.2026", .planned),
        ("Angebot vor Ort",    "18.01.2026", .open),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                header
                actionButtons
                contactSection
                if !customer.notes.isEmpty {
                    notesSection
                }
                jobsSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color.appBackground)
        .navigationTitle(customer.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            Circle()
                .fill(customer.avatarColor.opacity(0.15))
                .frame(width: 80, height: 80)
                .overlay(
                    Text(customer.initials)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(customer.avatarColor)
                )

            VStack(spacing: 4) {
                // Show salutation before name if non-empty
                let displayName = customer.salutation.isEmpty
                    ? customer.fullName
                    : "\(customer.salutation) \(customer.fullName)"
                Text(displayName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                if let company = customer.company {
                    Text(company)
                        .font(.system(size: 14))
                        .foregroundColor(.appTextSecondary)
                }
            }

            customerTypeBadge
        }
        .padding(.top, 8)
    }

    // MARK: - Customer Type Badge

    private var customerTypeBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: customer.customerType.icon)
                .font(.system(size: 11, weight: .semibold))
            Text(customer.customerType.rawValue)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(customer.customerType == .business ? .appPurple : .appBlue)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            (customer.customerType == .business ? Color.appPurple : Color.appBlue)
                .opacity(0.1)
        )
        .clipShape(Capsule())
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 10) {
            ActionChip(icon: "phone.fill", label: "Anrufen", color: .appGreen) {
                openTel(customer.phone)
            }
            ActionChip(icon: "message.fill", label: "SMS", color: .appBlue) {
                openSMS(preferredNumber)
            }
            ActionChip(icon: "bubble.left.fill", label: "WhatsApp", color: Color(red: 0.15, green: 0.69, blue: 0.36)) {
                openWhatsApp(preferredNumber)
            }
            ActionChip(icon: "envelope.fill", label: "E-Mail", color: .appOrange) {
                if let url = URL(string: "mailto:\(customer.email)") {
                    openURL(url)
                }
            }
        }
    }

    // MARK: - Communication helpers

    /// Prefer mobile number for SMS/WhatsApp, fall back to main phone.
    private var preferredNumber: String {
        customer.mobile.isEmpty ? customer.phone : customer.mobile
    }

    private func openTel(_ raw: String) {
        let digits = raw.filter { $0.isNumber || $0 == "+" }
        if let url = URL(string: "tel://\(digits)") { openURL(url) }
    }

    private func openSMS(_ raw: String) {
        let digits = raw.filter { $0.isNumber || $0 == "+" }
        if let url = URL(string: "sms:\(digits)") { openURL(url) }
    }

    private func openWhatsApp(_ raw: String) {
        // WhatsApp expects international format without "+" or spaces.
        var digits = raw.filter { $0.isNumber }
        // If number starts with 0 (German local format), prepend country code 49.
        if digits.hasPrefix("0") {
            digits = "49" + digits.dropFirst()
        }
        if let url = URL(string: "https://wa.me/\(digits)") {
            openURL(url)
        }
    }

    // MARK: - Kontakt

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("Kontakt")
            VStack(spacing: 0) {
                contactRow(icon: "phone.fill",    color: .appGreen,  value: customer.phone)

                if !customer.mobile.isEmpty {
                    Divider().padding(.leading, 52)
                    contactRow(icon: "iphone",    color: .appBlue,   value: customer.mobile)
                }

                Divider().padding(.leading, 52)
                contactRow(icon: "envelope.fill", color: .appBlue,   value: customer.email)

                if !customer.website.isEmpty {
                    Divider().padding(.leading, 52)
                    contactRow(icon: "globe",     color: .appPurple, value: customer.website)
                }

                Divider().padding(.leading, 52)
                contactRow(icon: "mappin.fill",   color: .appOrange, value: "\(customer.street)\n\(customer.city)")
            }
            .cardStyle()
        }
    }

    private func contactRow(icon: String, color: Color, value: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(color.opacity(0.12))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(color)
            }
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.appTextPrimary)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    // MARK: - Notizen

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("Notizen")
            VStack(alignment: .leading, spacing: 8) {
                Text(customer.notes)
                    .font(.system(size: 14))
                    .foregroundColor(.appTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .cardStyle()
        }
    }

    // MARK: - Aufträge

    private var jobsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                sectionTitle("Letzte Aufträge")
                Spacer()
                Button("Alle") {}
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.appBlue)
            }
            VStack(spacing: 0) {
                ForEach(Array(recentJobs.enumerated()), id: \.offset) { index, job in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(job.status.color)
                            .frame(width: 8, height: 8)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(job.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.appTextPrimary)
                            Text(job.date)
                                .font(.system(size: 12))
                                .foregroundColor(.appTextSecondary)
                        }
                        Spacer()
                        StatusBadge(status: job.status)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    if index < recentJobs.count - 1 {
                        Divider().padding(.leading, 34)
                    }
                }
            }
            .cardStyle()
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.appTextSecondary)
            .kerning(0.6)
            .padding(.bottom, 8)
    }
}

// MARK: - Action Chip

private struct ActionChip: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(color)
                }
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.appTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
}

#Preview {
    NavigationStack {
        CustomerDetailView(customer: DummyData.customers[0])
    }
}
