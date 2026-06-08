import SwiftUI

struct AppointmentsView: View {
    @State private var orders = DummyData.orders
    @State private var selectedStatus: OrderStatus? = nil
    @State private var showNew = false

    var filtered: [Order] {
        guard let s = selectedStatus else { return orders }
        return orders.filter { $0.status == s }
    }

    var body: some View {
        VStack(spacing: 0) {
            filterBar
            List {
                ForEach(filtered) { order in
                    NavigationLink(destination: OrderDetailView(order: order) { updated in
                        if let i = orders.firstIndex(where: { $0.id == updated.id }) {
                            orders[i] = updated
                        }
                    }) {
                        OrderRow(order: order)
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
                .onDelete { orders.remove(atOffsets: $0) }
            }
            .listStyle(.plain)
            .background(Color.appBackground)
        }
        .background(Color.appBackground)
        .navigationTitle("Aufträge")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showNew = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(.appBlue)
                        .font(.system(size: 17, weight: .semibold))
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showNew) {
            NewOrderView { newOrder in orders.insert(newOrder, at: 0) }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "Alle", color: .appTextSecondary, isSelected: selectedStatus == nil) {
                    selectedStatus = nil
                }
                ForEach(OrderStatus.allCases, id: \.self) { status in
                    FilterChip(label: status.rawValue, color: status.color, isSelected: selectedStatus == status) {
                        selectedStatus = selectedStatus == status ? nil : status
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color.white)
    }
}

private struct FilterChip: View {
    let label: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? color : color.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

private struct OrderRow: View {
    let order: Order

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(order.status.color.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: order.status.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(order.status.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(order.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.appTextPrimary)
                    Spacer()
                    Text(order.number)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.appTextSecondary)
                }
                Text(order.customerName)
                    .font(.system(size: 13))
                    .foregroundColor(.appTextSecondary)
                HStack(spacing: 4) {
                    Image(systemName: "mappin.mini.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.appTextSecondary)
                    Text(order.address)
                        .font(.system(size: 12))
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack { AppointmentsView() }
}
