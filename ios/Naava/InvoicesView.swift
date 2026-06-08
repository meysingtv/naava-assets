import SwiftUI

struct InvoicesView: View {
    @State private var invoices = DummyData.invoices
    @State private var filter: InvoiceStatus? = nil

    var filtered: [Invoice] {
        guard let f = filter else { return invoices }
        return invoices.filter { $0.status == f }
    }

    private var totalOpen: Double {
        invoices.filter { $0.status == .open || $0.status == .overdue }.reduce(0) { $0 + $1.grossTotal }
    }

    var body: some View {
        VStack(spacing: 0) {
            summaryBanner
            filterBar
            List {
                ForEach(filtered) { invoice in
                    NavigationLink(destination: InvoiceDetailView(invoice: invoice) { updated in
                        if let i = invoices.firstIndex(where: { $0.id == updated.id }) {
                            invoices[i] = updated
                        }
                    }) {
                        InvoiceRow(invoice: invoice)
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
            }
            .listStyle(.plain)
            .background(Color.appBackground)
        }
        .background(Color.appBackground)
        .navigationTitle("Rechnungen")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.hidden, for: .tabBar)
    }

    private var summaryBanner: some View {
        HStack(spacing: 0) {
            summaryItem(label: "Gesamt offen", value: Invoice.format(totalOpen), color: .appOrange)
            Divider().frame(height: 36)
            summaryItem(label: "Bezahlt (Monat)", value: Invoice.format(
                invoices.filter { $0.status == .paid }.reduce(0) { $0 + $1.grossTotal }
            ), color: .appGreen)
            Divider().frame(height: 36)
            summaryItem(label: "Überfällig", value: Invoice.format(
                invoices.filter { $0.status == .overdue }.reduce(0) { $0 + $1.grossTotal }
            ), color: .red)
        }
        .padding(.vertical, 12)
        .background(Color.white)
    }

    private func summaryItem(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterPill(label: "Alle", color: .appTextSecondary, active: filter == nil) { filter = nil }
                ForEach(InvoiceStatus.allCases, id: \.self) { s in
                    FilterPill(label: s.rawValue, color: s.color, active: filter == s) {
                        filter = filter == s ? nil : s
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
        }
        .background(Color.white)
    }
}

private struct FilterPill: View {
    let label: String; let color: Color; let active: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(active ? .white : color)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(active ? color : color.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

private struct InvoiceRow: View {
    let invoice: Invoice
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(invoice.status.color.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: invoice.status.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(invoice.status.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(invoice.number)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                    Spacer()
                    Text(invoice.formattedGross)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                }
                Text(invoice.customerName)
                    .font(.system(size: 13))
                    .foregroundColor(.appTextSecondary)
                HStack(spacing: 4) {
                    Text("Fällig: " + invoice.dueDate.formatted(.dateTime.day().month().locale(Locale(identifier: "de_DE"))))
                        .font(.system(size: 11))
                        .foregroundColor(invoice.status == .overdue ? .red : .appTextSecondary)
                    Spacer()
                    Text(invoice.status.rawValue)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(invoice.status.color)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview { NavigationStack { InvoicesView() } }
