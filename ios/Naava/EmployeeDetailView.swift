import SwiftUI

struct EmployeeDetailView: View {
    @State var employee: Employee
    let onUpdate: (Employee) -> Void

    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                header
                actionChips
                statsRow
                infoCard
                ordersSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
        .background(Color.appBackground)
        .navigationTitle(employee.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: toggleActive) {
                    Text(employee.isActive ? "Deaktivieren" : "Aktivieren")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(employee.isActive ? .red : .appGreen)
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [employee.avatarColor.opacity(0.25), employee.avatarColor.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                Text(employee.initials)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(employee.avatarColor)
            }
            .overlay(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(employee.isActive ? Color.appGreen : Color.appTextSecondary)
                        .frame(width: 20, height: 20)
                    Circle().stroke(Color.white, lineWidth: 3).frame(width: 20, height: 20)
                }
            }
            .padding(.top, 8)

            VStack(spacing: 5) {
                Text(employee.fullName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.appTextPrimary)

                HStack(spacing: 6) {
                    Image(systemName: employee.role.icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(employee.role.color)
                    Text(employee.role.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(employee.role.color)
                }
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(employee.role.color.opacity(0.1))
                .cornerRadius(10)

                Text(employee.isActive ? "Aktiv" : "Inaktiv")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(employee.isActive ? .appGreen : .appTextSecondary)
            }
        }
    }

    // MARK: - Action Chips

    private var actionChips: some View {
        HStack(spacing: 12) {
            EmpActionChip(icon: "phone.fill", label: "Anrufen", color: .appGreen) {
                if let url = URL(string: "tel://\(employee.phone.filter(\.isNumber))") {
                    openURL(url)
                }
            }
            EmpActionChip(icon: "envelope.fill", label: "E-Mail", color: .appBlue) {
                if let url = URL(string: "mailto:\(employee.email)") {
                    openURL(url)
                }
            }
            EmpActionChip(icon: "message.fill", label: "Nachricht", color: .appOrange) {
                if let url = URL(string: "sms:\(employee.phone.filter(\.isNumber))") {
                    openURL(url)
                }
            }
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 10) {
            statTile(value: "\(employee.hoursThisMonth)", label: "Std. / Monat",  icon: "clock.fill",           color: .appBlue)
            statTile(value: employee.experienceText,      label: "Im Betrieb",    icon: "calendar.badge.clock", color: .appGreen)
            statTile(value: hireMonthYear,                label: "Eingestellt",   icon: "person.badge.plus",    color: .appOrange)
        }
    }

    private func statTile(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.appTextPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // MARK: - Info Card

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("Kontakt")
            VStack(spacing: 0) {
                infoRow(icon: "phone.fill",    color: .appGreen,  value: employee.phone)
                Divider().padding(.leading, 50)
                infoRow(icon: "envelope.fill", color: .appBlue,   value: employee.email)
                Divider().padding(.leading, 50)
                infoRow(icon: "briefcase.fill",color: employee.role.color, value: employee.role.rawValue)
            }
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }

    private func infoRow(icon: String, color: Color, value: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.12))
                    .frame(width: 32, height: 32)
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
        .padding(.vertical, 12)
    }

    // MARK: - Orders Section

    private var ordersSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("Aktuelle Aufträge")
            VStack(spacing: 0) {
                ForEach(Array(DummyData.orders.prefix(3).enumerated()), id: \.offset) { idx, order in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(order.status.color)
                            .frame(width: 8, height: 8)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(order.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.appTextPrimary)
                            Text(order.customerName)
                                .font(.system(size: 12))
                                .foregroundColor(.appTextSecondary)
                        }
                        Spacer()
                        Text(order.status.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(order.status.color)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(order.status.color.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 11)
                    if idx < 2 {
                        Divider().padding(.leading, 34)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.appTextSecondary)
            .kerning(0.6)
            .padding(.bottom, 8)
    }

    private var hireMonthYear: String {
        let f = DateFormatter()
        f.dateFormat = "MM/yyyy"
        f.locale = Locale(identifier: "de_DE")
        return f.string(from: employee.hireDate)
    }

    private func toggleActive() {
        employee.isActive.toggle()
        onUpdate(employee)
    }
}

// MARK: - Action Chip

private struct EmpActionChip: View {
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
        EmployeeDetailView(employee: DummyData.employees[0], onUpdate: { _ in })
    }
}
