import SwiftUI

struct InvoiceDetailView: View {
    @State private var invoice: Invoice
    var onUpdate: (Invoice) -> Void

    @State private var pdfURL: URL?
    @State private var showShare = false
    @State private var showMarkPaid = false

    init(invoice: Invoice, onUpdate: @escaping (Invoice) -> Void) {
        _invoice = State(initialValue: invoice)
        self.onUpdate = onUpdate
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                statusHeader
                datesCard
                customerCard
                lineItemsCard
                totalsCard
                actionButtons
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
        .background(Color.appBackground)
        .navigationTitle(invoice.number)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showShare) {
            if let url = pdfURL {
                ShareSheet(url: url)
            }
        }
        .confirmationDialog("Status ändern", isPresented: $showMarkPaid, titleVisibility: .visible) {
            Button("Als bezahlt markieren") {
                invoice.status = .paid
                onUpdate(invoice)
            }
            Button("Als offen markieren") {
                invoice.status = .open
                onUpdate(invoice)
            }
        }
    }

    // MARK: - Status Header

    private var statusHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(invoice.number)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                Text(invoice.orderTitle)
                    .font(.system(size: 14))
                    .foregroundColor(.appTextSecondary)
            }
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: invoice.status.icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(invoice.status.rawValue)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(invoice.status.color)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(invoice.status.color.opacity(0.12))
            .cornerRadius(20)
        }
        .padding(16)
        .cardStyle()
        .padding(.top, 4)
    }

    // MARK: - Dates

    private var datesCard: some View {
        HStack(spacing: 0) {
            dateItem(label: "Ausgestellt", date: invoice.issueDate)
            Divider()
            dateItem(label: "Fällig am", date: invoice.dueDate,
                     highlight: invoice.status == .overdue ? .red : nil)
        }
        .cardStyle()
    }

    private func dateItem(label: String, date: Date, highlight: Color? = nil) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.appTextSecondary)
            Text(date.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "de_DE"))))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(highlight ?? .appTextPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }

    // MARK: - Customer

    private var customerCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "person.fill")
                .font(.system(size: 16))
                .foregroundColor(.appBlue)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(invoice.customerName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                Text(invoice.customerAddress)
                    .font(.system(size: 13))
                    .foregroundColor(.appTextSecondary)
            }
            Spacer()
        }
        .padding(14)
        .cardStyle()
    }

    // MARK: - Line Items

    private var lineItemsCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("LEISTUNGEN")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.appTextSecondary)
                    .kerning(0.6)
                Spacer()
            }
            .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 10)

            ForEach(invoice.lineItems) { item in
                VStack(spacing: 0) {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.description)
                                .font(.system(size: 14))
                                .foregroundColor(.appTextPrimary)
                            Text("\(formatQty(item.quantity)) \(item.unit) × \(Invoice.format(item.unitPrice))")
                                .font(.system(size: 12))
                                .foregroundColor(.appTextSecondary)
                        }
                        Spacer()
                        Text(Invoice.format(item.total))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.appTextPrimary)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    if item.id != invoice.lineItems.last?.id {
                        Divider().padding(.horizontal, 14)
                    }
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Totals

    private var totalsCard: some View {
        VStack(spacing: 8) {
            totalRow(label: "Netto", value: invoice.formattedNet, bold: false)
            totalRow(label: "MwSt. \(Int(invoice.taxRate * 100))%", value: invoice.formattedTax, bold: false)
            Divider()
            totalRow(label: "Gesamt", value: invoice.formattedGross, bold: true)
        }
        .padding(14)
        .cardStyle()
    }

    private func totalRow(label: String, value: String, bold: Bool) -> some View {
        HStack {
            Text(label)
                .font(.system(size: bold ? 16 : 14, weight: bold ? .bold : .regular))
                .foregroundColor(bold ? .appTextPrimary : .appTextSecondary)
            Spacer()
            Text(value)
                .font(.system(size: bold ? 18 : 14, weight: bold ? .bold : .regular))
                .foregroundColor(bold ? .appTextPrimary : .appTextSecondary)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button(action: exportPDF) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Als PDF exportieren")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.appBlue)
                .cornerRadius(14)
            }

            if invoice.status != .paid {
                Button(action: { showMarkPaid = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                        Text("Status ändern")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.appBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appBlue.opacity(0.1))
                    .cornerRadius(14)
                }
            }
        }
    }

    // MARK: - PDF Generation

    private func exportPDF() {
        pdfURL = InvoicePDF.generate(invoice)
        showShare = pdfURL != nil
    }

    private func formatQty(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(v))" : String(format: "%.1f", v)
    }
}

// MARK: - PDF Generator

private enum InvoicePDF {
    static func generate(_ invoice: Invoice) -> URL? {
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Rechnung_\(invoice.number).pdf")

        let attrs: (UIFont) -> [NSAttributedString.Key: Any] = { [.font: $0] }
        let boldLarge  = UIFont.systemFont(ofSize: 22, weight: .bold)
        let bold       = UIFont.systemFont(ofSize: 13, weight: .bold)
        let regular    = UIFont.systemFont(ofSize: 12)
        let small      = UIFont.systemFont(ofSize: 10)
        let gray       = UIColor.systemGray

        do {
            try renderer.writePDF(to: url) { ctx in
                ctx.beginPage()
                var y: CGFloat = 50

                // Company
                "Mustermann Dachdeckerei GmbH".draw(at: CGPoint(x: 40, y: y), withAttributes: attrs(boldLarge))
                y += 30
                "Musterstraße 1 · 80331 München · Tel: +49 89 123456".draw(
                    at: CGPoint(x: 40, y: y), withAttributes: [.font: small, .foregroundColor: gray])
                y += 40

                // RECHNUNG title
                "RECHNUNG".draw(at: CGPoint(x: 40, y: y), withAttributes: attrs(UIFont.systemFont(ofSize: 18, weight: .heavy)))
                y += 30

                // Invoice meta
                let meta = [
                    ("Rechnungsnummer:", invoice.number),
                    ("Ausgestellt:", invoice.issueDate.formatted(.dateTime.day().month().year())),
                    ("Fällig am:", invoice.dueDate.formatted(.dateTime.day().month().year())),
                ]
                for (label, val) in meta {
                    label.draw(at: CGPoint(x: 40, y: y), withAttributes: [.font: regular, .foregroundColor: gray])
                    val.draw(at: CGPoint(x: 200, y: y), withAttributes: attrs(bold))
                    y += 18
                }
                y += 20

                // Customer
                "Rechnungsempfänger:".draw(at: CGPoint(x: 40, y: y), withAttributes: [.font: regular, .foregroundColor: gray])
                y += 16
                invoice.customerName.draw(at: CGPoint(x: 40, y: y), withAttributes: attrs(bold))
                y += 16
                for line in invoice.customerAddress.components(separatedBy: "\n") {
                    line.draw(at: CGPoint(x: 40, y: y), withAttributes: attrs(regular))
                    y += 14
                }
                y += 20

                // Table header
                UIColor.systemBlue.withAlphaComponent(0.1).setFill()
                UIBezierPath(rect: CGRect(x: 40, y: y, width: 515, height: 22)).fill()
                let headers = [("Beschreibung", 40.0), ("Menge", 310.0), ("E-Preis", 390.0), ("Gesamt", 470.0)]
                for (h, x) in headers {
                    h.draw(at: CGPoint(x: x, y: y + 4), withAttributes: attrs(bold))
                }
                y += 26

                // Line items
                for item in invoice.lineItems {
                    item.description.draw(at: CGPoint(x: 40, y: y), withAttributes: attrs(regular))
                    "\(Int(item.quantity)) \(item.unit)".draw(at: CGPoint(x: 310, y: y), withAttributes: attrs(regular))
                    Invoice.format(item.unitPrice).draw(at: CGPoint(x: 390, y: y), withAttributes: attrs(regular))
                    Invoice.format(item.total).draw(at: CGPoint(x: 470, y: y), withAttributes: attrs(bold))
                    y += 18
                    UIColor.systemGray5.setFill()
                    UIBezierPath(rect: CGRect(x: 40, y: y, width: 515, height: 0.5)).fill()
                    y += 6
                }
                y += 14

                // Totals
                let totals: [(String, String, UIFont)] = [
                    ("Nettobetrag:", invoice.formattedNet, regular),
                    ("MwSt. \(Int(invoice.taxRate * 100))%:", invoice.formattedTax, regular),
                    ("Gesamtbetrag:", invoice.formattedGross, UIFont.systemFont(ofSize: 14, weight: .bold)),
                ]
                for (label, val, font) in totals {
                    label.draw(at: CGPoint(x: 350, y: y), withAttributes: [.font: font])
                    val.draw(at: CGPoint(x: 470, y: y), withAttributes: [.font: font])
                    y += 20
                }

                // Footer
                let footer = "Bitte überweisen Sie den Betrag innerhalb von 14 Tagen. Vielen Dank!"
                footer.draw(at: CGPoint(x: 40, y: 780), withAttributes: [.font: small, .foregroundColor: gray])
            }
            return url
        } catch {
            return nil
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        InvoiceDetailView(invoice: DummyData.invoices[0]) { _ in }
    }
}
