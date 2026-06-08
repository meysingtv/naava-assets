import SwiftUI

struct HilfeView: View {
    @State private var expandedFAQ: UUID? = nil

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                headerBanner
                faqSection
                kontaktSection
                appInfoSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Color.appBackground)
        .navigationTitle("Hilfe & Support")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: - Header Banner

    private var headerBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.appBlue.opacity(0.12))
                    .frame(width: 56, height: 56)
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.appBlue)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Wie können wir helfen?")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                Text("Antworten auf häufige Fragen findest du hier. Für direkten Support schreib uns.")
                    .font(.system(size: 12))
                    .foregroundColor(.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: - FAQ

    private var faqSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("Häufige Fragen")

            VStack(spacing: 0) {
                ForEach(faqItems) { item in
                    FAQRow(item: item, isExpanded: expandedFAQ == item.id) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            expandedFAQ = expandedFAQ == item.id ? nil : item.id
                        }
                    }
                    if item.id != faqItems.last?.id {
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
    }

    // MARK: - Kontakt

    private var kontaktSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("Kontakt")

            VStack(spacing: 0) {
                kontaktRow(icon: "envelope.fill",   color: .appBlue,   label: "E-Mail Support",  value: "support@naava.de")
                Divider().padding(.leading, 52)
                kontaktRow(icon: "phone.fill",      color: .appGreen,  label: "Telefon",          value: "+49 2161 9876 00")
                Divider().padding(.leading, 52)
                kontaktRow(icon: "globe",            color: .appOrange, label: "Website",          value: "www.naava.de")
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
    }

    private func kontaktRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.appTextSecondary)
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11))
                .foregroundColor(.appTextSecondary.opacity(0.4))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - App Info

    private var appInfoSection: some View {
        VStack(spacing: 6) {
            Image(systemName: "house.fill")
                .font(.system(size: 28))
                .foregroundColor(.appBlue.opacity(0.4))
            Text("Naava")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.appTextPrimary)
            Text("Version 1.0.0 · Made with ♥ in Germany")
                .font(.system(size: 12))
                .foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: - Helper

    private func sectionTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.appTextSecondary)
            .kerning(0.6)
            .padding(.bottom, 8)
    }

    // MARK: - FAQ Data

    private let faqItems: [FAQItem] = [
        FAQItem(question: "Wie erstelle ich einen neuen Auftrag?",
                answer: "Tippe unten auf den blauen Plus-Button und wähle „Neuer Auftrag". Oder gehe zu Aufträge und tippe oben rechts auf +."),
        FAQItem(question: "Wie exportiere ich eine Rechnung als PDF?",
                answer: "Öffne die Rechnung und tippe auf „Als PDF exportieren". Du kannst das PDF dann per E-Mail, AirDrop oder anderen Apps teilen."),
        FAQItem(question: "Wie wandle ich ein Angebot in einen Auftrag um?",
                answer: "Öffne das Angebot (Status: Angenommen oder Gesendet) und tippe auf den grünen Button „Zu Auftrag konvertieren"."),
        FAQItem(question: "Kann ich mehrere Mitarbeiter hinzufügen?",
                answer: "Ja! Gehe zu Mehr → Mitarbeiter und tippe auf + oben rechts. Pro- und Business-Pläne unterstützen mehrere Nutzer."),
        FAQItem(question: "Wie ändere ich meinen Firmennamen?",
                answer: "Gehe zu Mehr → Firmenprofil (oben in der Liste) oder Mehr → Einstellungen → Firmenprofil und bearbeite die Daten."),
        FAQItem(question: "Sind meine Daten sicher?",
                answer: "Alle Daten werden verschlüsselt gespeichert. Backups erfolgen automatisch in der iCloud. Du behältst jederzeit die volle Kontrolle."),
    ]
}

// MARK: - FAQ Row

private struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

private struct FAQRow: View {
    let item: FAQItem
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.appBlue)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.spring(response: 0.3), value: isExpanded)
                    Text(item.question)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appTextPrimary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }

            if isExpanded {
                Text(item.answer)
                    .font(.system(size: 13))
                    .foregroundColor(.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 14)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

#Preview {
    NavigationStack { HilfeView() }
}
