import SwiftUI

struct CompanySetupView: View {
    var onNext: () -> Void
    @EnvironmentObject var appState: AppState

    @State private var companyName = ""
    @State private var ownerName   = ""
    @State private var street      = ""
    @State private var city        = ""
    @State private var phone       = ""
    @State private var email       = ""
    @State private var taxId       = ""
    @FocusState private var focused: Field?

    enum Field: Hashable { case company, owner, street, city, phone, email, taxId }

    private var isValid: Bool {
        !companyName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !ownerName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    progressHeader(step: 2, total: 3, title: "Dein Betrieb", subtitle: "Wie heißt deine Firma?")

                    VStack(spacing: 14) {
                        SetupSection(title: "PFLICHTFELDER") {
                            SetupField(icon: "building.2.fill", placeholder: "Firmenname *",
                                       text: $companyName, content: .organizationName, focused: $focused, tag: .company)
                            SetupField(icon: "person.fill", placeholder: "Dein Name (Inhaber) *",
                                       text: $ownerName, content: .name, focused: $focused, tag: .owner)
                        }

                        SetupSection(title: "ADRESSE") {
                            SetupField(icon: "mappin.fill", placeholder: "Straße & Hausnummer",
                                       text: $street, content: .streetAddressLine1, focused: $focused, tag: .street)
                            SetupField(icon: "building.columns.fill", placeholder: "PLZ & Ort",
                                       text: $city, content: .addressCityAndState, focused: $focused, tag: .city)
                        }

                        SetupSection(title: "KONTAKT") {
                            SetupField(icon: "phone.fill", placeholder: "Telefonnummer",
                                       text: $phone, keyboard: .phonePad, content: .telephoneNumber, focused: $focused, tag: .phone)
                            SetupField(icon: "envelope.fill", placeholder: "Geschäftliche E-Mail",
                                       text: $email, keyboard: .emailAddress, content: .emailAddress, focused: $focused, tag: .email)
                        }

                        SetupSection(title: "STEUER") {
                            SetupField(icon: "doc.text.fill", placeholder: "USt-IdNr. (optional, z.B. DE123456789)",
                                       text: $taxId, focused: $focused, tag: .taxId)
                        }
                    }

                    ctaButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .onTapGesture { focused = nil }
    }

    private var ctaButton: some View {
        Button(action: save) {
            HStack(spacing: 8) {
                Text("Weiter")
                    .font(.system(size: 17, weight: .bold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isValid ? Color.appBlue : Color.appBlue.opacity(0.35))
            .cornerRadius(16)
        }
        .disabled(!isValid)
    }

    private func save() {
        appState.companyName  = companyName.trimmingCharacters(in: .whitespaces)
        appState.ownerName    = ownerName.trimmingCharacters(in: .whitespaces)
        appState.companyStreet = street
        appState.companyCity  = city
        appState.companyPhone = phone
        appState.companyEmail = email
        appState.companyTaxId = taxId
        onNext()
    }
}

// MARK: - Progress Header

func progressHeader(step: Int, total: Int, title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 4) {
            ForEach(1...total, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i <= step ? Color.appBlue : Color.appBlue.opacity(0.2))
                    .frame(height: 4)
            }
        }
        .animation(.easeInOut, value: step)

        Text("Schritt \(step) von \(total)")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.appTextSecondary)
            .textCase(.uppercase)
            .kerning(0.5)

        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.appTextPrimary)
            Text(subtitle)
                .font(.system(size: 15))
                .foregroundColor(.appTextSecondary)
        }
    }
}

// MARK: - Reusable components

struct SetupSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.appTextSecondary)
                .kerning(0.6)
            VStack(spacing: 10) { content }
        }
    }
}

struct SetupField<Tag: Hashable>: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var content: UITextContentType? = nil
    var focused: FocusState<Tag?>.Binding
    var tag: Tag

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.appTextSecondary)
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .font(.system(size: 15))
                .keyboardType(keyboard)
                .textContentType(content)
                .focused(focused, equals: tag)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(focused.wrappedValue == tag ? Color.appBlue : Color.clear, lineWidth: 1.5)
        )
    }
}

#Preview { CompanySetupView { }.environmentObject(AppState()) }
