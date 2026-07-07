import SwiftUI

struct EmployeesView: View {
    @EnvironmentObject var toast: ToastManager
    @State private var employees = DummyData.employees
    @State private var search = ""
    @State private var roleFilter: EmployeeRole? = nil
    @State private var showNewEmployee = false

    private var filtered: [Employee] {
        employees.filter { emp in
            let matchesRole = roleFilter == nil || emp.role == roleFilter
            let matchesSearch = search.isEmpty ||
                emp.fullName.localizedCaseInsensitiveContains(search) ||
                emp.role.rawValue.localizedCaseInsensitiveContains(search)
            return matchesRole && matchesSearch
        }
    }

    private var totalHours: Int { employees.reduce(0) { $0 + $1.hoursThisMonth } }

    var body: some View {
        VStack(spacing: 0) {
            summaryBanner
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            searchBar
                .padding(.horizontal, 16)
                .padding(.bottom, 4)

            roleFilterBar

            List {
                ForEach(filtered) { emp in
                    NavigationLink(
                        destination: EmployeeDetailView(employee: emp, onUpdate: { updated in
                            if let i = employees.firstIndex(where: { $0.id == updated.id }) {
                                employees[i] = updated
                            }
                        }).toolbar(.hidden, for: .tabBar)
                    ) {
                        EmployeeRow(employee: emp)
                    }
                    .listRowBackground(Color.white)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
            }
            .listStyle(.plain)
            .background(Color.appBackground)
        }
        .background(Color.appBackground)
        .navigationTitle("Mitarbeiter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showNewEmployee = true }) {
                    Image(systemName: "plus").foregroundColor(.appBlue)
                }
            }
        }
        .sheet(isPresented: $showNewEmployee) {
            NewEmployeeView { emp in
                employees.append(emp)
                toast.show("Mitarbeiter hinzugefügt", style: .success, icon: "person.fill.checkmark")
            }
        }
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: - Summary

    private var summaryBanner: some View {
        HStack(spacing: 10) {
            summaryTile(label: "Gesamt",       value: "\(employees.count)",     icon: "person.2.fill",     color: .appBlue)
            summaryTile(label: "Aktiv",        value: "\(employees.filter { $0.isActive }.count)", icon: "checkmark.circle.fill", color: .appGreen)
            summaryTile(label: "Std./Monat",   value: "\(totalHours)",          icon: "clock.fill",        color: .appOrange)
        }
    }

    private func summaryTile(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.appTextSecondary)
            }
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.appTextPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.appTextSecondary)
                .font(.system(size: 15))
            TextField("Suchen…", text: $search)
                .font(.system(size: 15))
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
    }

    // MARK: - Role Filter

    private var roleFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                EmpFilterChip(label: "Alle", color: .appTextSecondary, active: roleFilter == nil) {
                    withAnimation { roleFilter = nil }
                }
                ForEach(EmployeeRole.allCases, id: \.self) { role in
                    EmpFilterChip(label: role.rawValue, color: role.color, active: roleFilter == role) {
                        withAnimation { roleFilter = roleFilter == role ? nil : role }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Employee Row

private struct EmployeeRow: View {
    let employee: Employee

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(employee.avatarColor.opacity(0.15))
                    .frame(width: 46, height: 46)
                Text(employee.initials)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(employee.avatarColor)
            }
            .overlay(alignment: .bottomTrailing) {
                Circle()
                    .fill(employee.isActive ? Color.appGreen : Color.appTextSecondary)
                    .frame(width: 11, height: 11)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(employee.fullName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                HStack(spacing: 5) {
                    Image(systemName: employee.role.icon)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(employee.role.color)
                    Text(employee.role.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(employee.role.color)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(employee.hoursThisMonth) Std.")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                Text("diesen Monat")
                    .font(.system(size: 11))
                    .foregroundColor(.appTextSecondary)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Filter Chip

private struct EmpFilterChip: View {
    let label: String
    let color: Color
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(active ? .white : color)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(active ? color : color.opacity(0.12))
                .cornerRadius(20)
        }
    }
}

#Preview {
    NavigationStack { EmployeesView() }
        .environmentObject(ToastManager())
}
