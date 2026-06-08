import SwiftUI

struct AuthView: View {
    var onNext: () -> Void

    @State private var isLogin = true
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @FocusState private var focused: Field?

    enum Field { case email, password, confirm }

    private var isValid: Bool {
        !email.isEmpty && password.count >= 6 &&
        (isLogin || password == confirmPassword)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.10, blue: 0.25), Color(red: 0.07, green: 0.20, blue: 0.48)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    header
                    card
                    divider
                    appleButton
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
        .onTapGesture { focused = nil }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Text("naava")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(.white)
            Text(isLogin ? "Willkommen zurück" : "Konto erstellen")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    // MARK: - Card

    private var card: some View {
        VStack(spacing: 20) {
            // Segment
            HStack(spacing: 0) {
                segmentButton("Anmelden",    selected: isLogin)  { withAnimation { isLogin = true  } }
                segmentButton("Registrieren",selected: !isLogin) { withAnimation { isLogin = false } }
            }
            .background(Color(white: 0.95))
            .cornerRadius(10)

            // Fields
            VStack(spacing: 12) {
                AuthField(icon: "envelope.fill", placeholder: "E-Mail-Adresse",
                          text: $email, type: .emailAddress, focused: $focused, tag: .email)
                AuthField(icon: "lock.fill", placeholder: "Passwort (min. 6 Zeichen)",
                          text: $password, isSecure: true, focused: $focused, tag: .password)
                if !isLogin {
                    AuthField(icon: "lock.fill", placeholder: "Passwort wiederholen",
                              text: $confirmPassword, isSecure: true, focused: $focused, tag: .confirm)
                }
            }

            if isLogin {
                Button(action: {}) {
                    Text("Passwort vergessen?")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.appBlue)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            // CTA
            Button(action: proceed) {
                ZStack {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        HStack(spacing: 6) {
                            Text(isLogin ? "Anmelden" : "Konto erstellen")
                                .font(.system(size: 16, weight: .bold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(isValid ? Color.appBlue : Color.appBlue.opacity(0.4))
                .cornerRadius(13)
            }
            .disabled(!isValid || isLoading)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 8)
    }

    private func segmentButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(selected ? .white : .appTextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(selected ? Color.appBlue : Color.clear)
                .cornerRadius(8)
                .padding(3)
        }
    }

    // MARK: - Divider

    private var divider: some View {
        HStack(spacing: 12) {
            Rectangle().fill(Color.white.opacity(0.25)).frame(height: 1)
            Text("oder").font(.system(size: 13)).foregroundColor(.white.opacity(0.5))
            Rectangle().fill(Color.white.opacity(0.25)).frame(height: 1)
        }
    }

    // MARK: - Apple Button

    private var appleButton: some View {
        Button(action: proceed) {
            HStack(spacing: 10) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 17, weight: .semibold))
                Text("Mit Apple anmelden")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.white)
            .cornerRadius(13)
        }
    }

    // MARK: - Action

    private func proceed() {
        focused = nil
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isLoading = false
            onNext()
        }
    }
}

// MARK: - Auth Field

private struct AuthField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var type: UIKeyboardType = .default
    var isSecure: Bool = false
    var focused: FocusState<AuthView.Field?>.Binding
    var tag: AuthView.Field

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.appTextSecondary)
                .frame(width: 18)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(type)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
            }
            .font(.system(size: 15))
            .foregroundColor(.appTextPrimary)
            .focused(focused, equals: tag)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(Color(white: 0.97))
        .cornerRadius(11)
        .overlay(
            RoundedRectangle(cornerRadius: 11)
                .stroke(focused.wrappedValue == tag ? Color.appBlue : Color.clear, lineWidth: 1.5)
        )
    }
}

#Preview { AuthView { }.environmentObject(AppState()) }
