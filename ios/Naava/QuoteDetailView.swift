import SwiftUI

struct QuoteDetailView: View {
    @State var quote: Quote
    let onUpdate: (Quote) -> Void

    @State private var showShare = false
    @State private var pdfURL: URL?
    @State private var showStatusSheet = false
    @State private var showConvertAlert = false
    @State private var showConvertSuccess = false
    @State private var showEmailAI = false
    @EnvironmentObject var toast: ToastManager

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                headerCard
                lineItemsCard
                totalsCard
                actionButtons
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Color.appBackground)
        .navigationTitle(quote.number)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showShare) {
            if let url = pdfURL { ShareSheet(url: url) }
        }
        .sheet(isPresented: $showEmailAI) {
            AIEmailView(
                context: "Angebot",
                details: "\(quote.number), \(quote.title), \(Int(quote.netTotal)) €, Kunde: \(quote.customerName)"
            )
            .environmentObject(toast)
        }
        .confirmationDialog("Status ändern", isPresented: $showStatusSheet, titleVisibility: .visible) {
            ForEach(QuoteStatus.allCases, id: \.self) { s in
                Button(s.rawValue) {
                    quote.status = s
                    onUpdate(quote)
                }
            }
            Button("Abbrechen", role: .cancel) {}
        }
        .alert("Zu Auftrag konvertieren?", isPresented: $showConvertAlert) {
            Button("Konvertieren", role: .destructive) { convertToOrder() }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Ein neuer Auftrag wird für \(quote.customerName) erstellt.")
        }
        .alert("Auftrag erstellt ✓", isPresented: $showConvertSuccess) {
            Button("OK") {}
        } message: {
            Text("Der Auftrag wurde angelegt. Du findest ihn in der Aufträge-Liste.")
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(quote.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                    Text(quote.customerName)
                        .font(.system(size: 14))
                        .foregroundColor(.appTextSecondary)
                    Text(quote.customerAddress.replacingOccurrences(of: "\n", with: " · "))
                        .font(.system(size: 12))
                        .foregroundColor(.appTextSecondary.opacity(0.7))
                }
                Spacer()
                statusBadge
            }

            Divider()

            HStack(spacing: 0) {
                infoBlock(label: "Erstellt",   value: dateStr(quote.issueDate))
                Divider().frame(height: 32)
                infoBlock(label: "Gültig bis", value: dateStr(quote.validUntil),
                          highlight: quote.validUntil < Date() ? .red : nil)
                Divider().frame(height: 32)
                infoBlock(label: "Brutto",     value: quote.formattedGross)
            }

            if !quote.description.isEmpty {
                Divider()
                Text(quote.description)
                    .font(.system(size: 13))
                    .foregroundColor(.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    private var statusBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: quote.status.icon)
                .font(.system(size: 11, weight: .bold))
            Text(quote.status.rawValue)
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundColor(quote.status.color)
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(quote.status.color.opacity(0.12))
        .cornerRadius(10)
    }

    private func infoBlock(label: String, value: String, highlight: Color? = nil) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.appTextSecondary)
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(highlight ?? .appTextPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Line Items Card

    private var lineItemsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("POSITIONEN")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.appTextSecondary)
                .kerning(0.5)
                .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 10)

            // Column headers
            HStack {
                Text("Beschreibung").frame(maxWidth: .infinity, alignment: .leading)
                Text("Menge").frame(width: 56, alignment: .trailing)
                Text("EP").frame(width: 58, alignment: .trailing)
                Text("Gesamt").frame(width: 68, alignment: .trailing)
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.appTextSecondary)
            .padding(.horizontal, 16).padding(.vertical, 6)
            .background(Color.appBackground)

            ForEach(quote.lineItems) { item in
                Divider()
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.description)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.appTextPrimary)
                        Text(item.unit)
                            .font(.system(size: 11))
                            .foregroundColor(.appTextSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(formatQty(item.quantity))
                        .font(.system(size: 12))
                        .foregroundColor(.appTextSecondary)
                        .frame(width: 56, alignment: .trailing)

                    Text(Invoice.format(item.unitPrice))
                        .font(.system(size: 12))
                        .foregroundColor(.appTextSecondary)
                        .frame(width: 58, alignment: .trailing)

                    Text(Invoice.format(item.total))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.appTextPrimary)
                        .frame(width: 68, alignment: .trailing)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: - Totals Card

    private var totalsCard: some View {
        VStack(spacing: 8) {
            totalRow("Netto",      quote.formattedNet,   bold: false)
            totalRow("MwSt. 19%", quote.formattedTax,   bold: false)
            Divider()
            totalRow("Gesamt",    quote.formattedGross, bold: true)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    private func totalRow(_ label: String, _ value: String, bold: Bool) -> some View {
        HStack {
            Text(label)
                .font(.system(size: bold ? 15 : 13, weight: bold ? .bold : .regular))
                .foregroundColor(bold ? .appTextPrimary : .appTextSecondary)
            Spacer()
            Text(value)
                .font(.system(size: bold ? 17 : 13, weight: bold ? .bold : .regular))
                .foregroundColor(bold ? .appTextPrimary : .appTextSecondary)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button(action: exportPDF) {
                Label("PDF teilen", systemImage: "square.and.arrow.up")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appBlue)
                    .cornerRadius(14)
            }

            Button(action: { showEmailAI = true }) {
                Label("Email per KI", systemImage: "sparkles")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.appBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appBlue.opacity(0.08))
                    .cornerRadius(14)
            }

            Button(action: { showStatusSheet = true }) {
                Label("Status ändern", systemImage: "arrow.triangle.2.circlepath")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.appBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appBlue.opacity(0.1))
                    .cornerRadius(14)
            }

            if quote.status == .accepted || quote.status == .sent {
                Button(action: { showConvertAlert = true }) {
                    Label("Zu Auftrag konvertieren", systemImage: "arrow.right.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.appGreen)
                        .cornerRadius(14)
                }
            }
        }
    }

    // MARK: - Helpers

    private func dateStr(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.locale = Locale(identifier: "de_DE")
        return f.string(from: date)
    }

    private func formatQty(_ qty: Double) -> String {
        qty.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(qty))" : String(format: "%.1f", qty)
    }

    private func convertToOrder() {
        let order = Order(
            number: String(format: "AU-2026-%03d", DummyData.orders.count + 13),
            title: quote.title,
            customerName: quote.customerName,
            address: quote.customerAddress.components(separatedBy: "\n").first ?? "",
            description: quote.description,
            status: .open,
            date: Date(),
            estimatedHours: nil
        )
        DummyData.orders.insert(order, at: 0)
        quote.status = .accepted
        onUpdate(quote)
        showConvertSuccess = true
    }

    private func exportPDF() {
        pdfURL = QuotePDF.generate(quote: quote)
        showShare = pdfURL != nil
    }
}

// MARK: - PDF Generator

enum QuotePDF {
    static func generate(quote: Quote) -> URL? {
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Angebot_\(quote.number).pdf")

        let boldLarge = UIFont.systemFont(ofSize: 22, weight: .bold)
        let bold      = UIFont.systemFont(ofSize: 12, weight: .bold)
        let regular   = UIFont.systemFont(ofSize: 11)
        let small     = UIFont.systemFont(ofSize: 9)
        let gray      = UIColor.systemGray

        func attr(_ f: UIFont, _ c: UIColor = .black) -> [NSAttributedString.Key: Any] {
            [.font: f, .foregroundColor: c]
        }

        let df = DateFormatter()
        df.dateStyle = .medium
        df.locale = Locale(identifier: "de_DE")

        do {
            try renderer.writePDF(to: url) { ctx in
                ctx.beginPage()
                var y: CGFloat = 50

                // Header
                "Mustermann Dachdeckerei GmbH".draw(at: CGPoint(x: 40, y: y), withAttributes: attr(boldLarge))
                y += 28
                "Musterstraße 1 · 41061 Mönchengladbach · Tel: +49 2161 123456"
                    .draw(at: CGPoint(x: 40, y: y), withAttributes: attr(small, gray))
                y += 36

                // Title block
                "ANGEBOT".draw(at: CGPoint(x: 40, y: y),
                               withAttributes: attr(UIFont.systemFont(ofSize: 18, weight: .heavy)))
                y += 28

                let meta: [(String, String)] = [
                    ("Angebotsnummer:", quote.number),
                    ("Datum:",          df.string(from: quote.issueDate)),
                    ("Gültig bis:",     df.string(from: quote.validUntil)),
                ]
                for (label, value) in meta {
                    label.draw(at: CGPoint(x: 40, y: y), withAttributes: attr(regular, gray))
                    value.draw(at: CGPoint(x: 200, y: y), withAttributes: attr(bold))
                    y += 16
                }
                y += 18

                // Customer
                "Angebot für:".draw(at: CGPoint(x: 40, y: y), withAttributes: attr(regular, gray))
                y += 14
                quote.customerName.draw(at: CGPoint(x: 40, y: y), withAttributes: attr(bold))
                y += 14
                for line in quote.customerAddress.components(separatedBy: "\n") {
                    line.draw(at: CGPoint(x: 40, y: y), withAttributes: attr(regular))
                    y += 13
                }
                y += 18

                // Title + description
                quote.title.draw(at: CGPoint(x: 40, y: y),
                                 withAttributes: attr(UIFont.systemFont(ofSize: 13, weight: .bold)))
                y += 18
                if !quote.description.isEmpty {
                    let rect = CGRect(x: 40, y: y, width: 515, height: 44)
                    quote.description.draw(in: rect, withAttributes: attr(small, .darkGray))
                    y += 48
                }

                // Table header
                UIColor.systemBlue.withAlphaComponent(0.1).setFill()
                UIBezierPath(rect: CGRect(x: 40, y: y, width: 515, height: 22)).fill()
                let cols: [(String, CGFloat)] = [("Beschreibung", 48), ("Menge", 320), ("E-Preis", 395), ("Gesamt", 470)]
                for (h, x) in cols {
                    h.draw(at: CGPoint(x: x, y: y + 5), withAttributes: attr(UIFont.systemFont(ofSize: 9, weight: .semibold), .darkGray))
                }
                y += 26

                // Line items
                for item in quote.lineItems {
                    item.description.draw(at: CGPoint(x: 48, y: y), withAttributes: attr(regular))
                    let qty = item.quantity.truncatingRemainder(dividingBy: 1) == 0
                        ? "\(Int(item.quantity)) \(item.unit)"
                        : String(format: "%.1f \(item.unit)", item.quantity)
                    qty.draw(at: CGPoint(x: 320, y: y), withAttributes: attr(regular))
                    Invoice.format(item.unitPrice).draw(at: CGPoint(x: 395, y: y), withAttributes: attr(regular))
                    Invoice.format(item.total).draw(at: CGPoint(x: 470, y: y), withAttributes: attr(bold))
                    y += 16
                    UIColor.systemGray5.setFill()
                    UIBezierPath(rect: CGRect(x: 40, y: y, width: 515, height: 0.5)).fill()
                    y += 5
                }
                y += 12

                // Totals
                let totals: [(String, String, UIFont)] = [
                    ("Nettobetrag:", quote.formattedNet, regular),
                    ("MwSt. 19%:",   quote.formattedTax, regular),
                    ("Gesamtbetrag:", quote.formattedGross, UIFont.systemFont(ofSize: 13, weight: .bold)),
                ]
                for (label, value, font) in totals {
                    label.draw(at: CGPoint(x: 350, y: y), withAttributes: attr(font))
                    value.draw(at: CGPoint(x: 470, y: y), withAttributes: attr(font))
                    y += 18
                }

                // Footer
                "Dieses Angebot ist freibleibend und unverbindlich. Preise verstehen sich zzgl. gesetzlicher MwSt."
                    .draw(at: CGPoint(x: 40, y: 800), withAttributes: attr(small, gray))
            }
            return url
        } catch {
            return nil
        }
    }
}

#Preview {
    NavigationStack {
        QuoteDetailView(quote: DummyData.quotes[0], onUpdate: { _ in })
    }
}
