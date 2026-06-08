import SwiftUI

struct CustomersView: View {
    @EnvironmentObject var toast: ToastManager
    @State private var searchText = ""
    @State private var showNewCustomer = false
    @State private var customers = DummyData.customers

    var filtered: [Customer] {
        guard !searchText.isEmpty else { return customers }
        return customers.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            ($0.company?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            $0.city.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            ForEach(filtered) { customer in
                NavigationLink(destination: CustomerDetailView(customer: customer)) {
                    CustomerRow(customer: customer)
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            }
            .onDelete(perform: delete)
        }
        .listStyle(.plain)
        .background(Color.appBackground)
        .searchable(text: $searchText, prompt: "Name oder Firma suchen")
        .navigationTitle("Kunden")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showNewCustomer = true }) {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(.appBlue)
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showNewCustomer) {
            NewCustomerView { newCustomer in
                customers.insert(newCustomer, at: 0)
                toast.show("Kunde gespeichert", style: .success, icon: "person.crop.circle.fill.badge.checkmark")
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        let ids = offsets.map { filtered[$0].id }
        customers.removeAll { ids.contains($0.id) }
    }
}

// MARK: - Customer Row

private struct CustomerRow: View {
    let customer: Customer

    var body: some View {
        HStack(spacing: 12) {
            avatar
            VStack(alignment: .leading, spacing: 2) {
                Text(customer.fullName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                Text(customer.displaySubtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.appTextSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(customer.city.components(separatedBy: "-").last ?? customer.city)
                .font(.system(size: 12))
                .foregroundColor(.appTextSecondary)
        }
        .padding(.vertical, 4)
    }

    private var avatar: some View {
        Circle()
            .fill(customer.avatarColor.opacity(0.15))
            .frame(width: 44, height: 44)
            .overlay(
                Text(customer.initials)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(customer.avatarColor)
            )
    }
}

#Preview {
    NavigationStack {
        CustomersView()
    }
    .environmentObject(ToastManager())
}
