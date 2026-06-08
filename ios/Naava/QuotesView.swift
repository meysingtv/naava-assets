import SwiftUI

struct QuotesView: View {
    @State private var quotes = DummyData.quotes
    @State private var filter: QuoteStatus? = nil
    @State private var showNewQuote = false

    private var filtered: [Quote] {
        guard let f = filter else { return quotes }
        return quotes.filter { $0.status == f }
    }

    private var openValue: Double {
        quotes.filter { $0.status == .sent || $0.status == .draft }.reduce(0) { $0 + $1.grossTotal }
    }

    var body: some View {
        VStack(spacing: 0) {
            summaryBanner
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            filterBar

            List {
                ForEach(filtered) { quote in
                    NavigationLink(
                        destination: QuoteDetailView(quote: quote, onUpdate: { updated in
                            if let i = quotes.firstIndex(where: { $0.id == updated.id }) {
                                quotes[i] = updated
                            }
                        }).toolbar(.hidden, for: .tabBar)
                    ) {
                        QuoteRow(quote: quote)
                    }
                    .listRowBackground(Color.white)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
            }
            .listStyle(.plain)
            .background(Color.appBackground)
        }
        .background(Color.appBackground)
        .navigationTitle("Angebote")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showNewQuote = true }) {
                    Image(systemName: "plus").foregroundColor(.appBlue)
                }
            }
        }
        .sheet(isPresented: $showNewQuote) {
            NewQuoteView { quotes.insert($0, at: 0) }
        }
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: - Summary Banner

    private var summaryBanner: some View {
        HStack(spacing: 10) {
            summaryTile(
                label: "Offen",
                value: Invoice.format(openValue),
                icon: "doc.text.fill",
                color: .appBlue
            )
            summaryTile(
                label: "Angenommen",
                value: "\(quotes.filter { $0.status == .accepted }.count)",
                icon: "checkmark.seal.fill",
                color: .appGreen
            )
            summaryTile(
                label: "Gesamt",
                value: "\(quotes.count)",
                icon: "doc.on.doc.fill",
                color: .appOrange
            )
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
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                QuoteFilterChip(label: "Alle (\(quotes.count))", color: .appTextSecondary, active: filter == nil) {
                    withAnimation { filter = nil }
                }
                ForEach(QuoteStatus.allCases, id: \.self) { s in
                    let count = quotes.filter { $0.status == s }.count
                    QuoteFilterChip(label: "\(s.rawValue) (\(count))", color: s.color, active: filter == s) {
                        withAnimation { filter = filter == s ? nil : s }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Quote Row

private struct QuoteRow: View {
    let quote: Quote

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(quote.status.color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: quote.status.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(quote.status.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(quote.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                Text(quote.customerName)
                    .font(.system(size: 13))
                    .foregroundColor(.appTextSecondary)
                Text(quote.number)
                    .font(.system(size: 11))
                    .foregroundColor(.appTextSecondary.opacity(0.7))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                Text(quote.formattedGross)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                Text(quote.status.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(quote.status.color)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(quote.status.color.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Filter Chip

private struct QuoteFilterChip: View {
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
    NavigationStack { QuotesView() }
}
