import SwiftUI

// MARK: - Onboarding Coordinator

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var step: Step = .welcome

    enum Step { case welcome, auth, company, plan }

    var body: some View {
        ZStack {
            switch step {
            case .welcome: WelcomeScreen { advance() }
            case .auth:    AuthView      { advance() }
            case .company: CompanySetupView { advance() }
            case .plan:    PlanSelectionView { appState.completeOnboarding() }
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: step)
    }

    private func advance() {
        switch step {
        case .welcome: step = .auth
        case .auth:    step = .company
        case .company: step = .plan
        case .plan:    break
        }
    }
}

// MARK: - Welcome Screen

private struct WelcomeScreen: View {
    var onNext: () -> Void

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                Spacer()
                logo
                Spacer()
                features
                Spacer()
                buttons
                    .padding(.bottom, 48)
            }
            .padding(.horizontal, 28)
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.04, green: 0.10, blue: 0.25),
                Color(red: 0.07, green: 0.20, blue: 0.48),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var logo: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 90, height: 90)
                Image(systemName: "house.fill")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundColor(.white)
            }
            Text("naava")
                .font(.system(size: 46, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .kerning(-1)
            Text("Dachdecker-Software, die wirklich funktioniert.")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    private var features: some View {
        VStack(spacing: 14) {
            FeatureRow(icon: "bolt.fill",       color: .yellow,  text: "Auftrag in unter 60 Sekunden anlegen")
            FeatureRow(icon: "camera.fill",      color: .appGreen,text: "Foto aufnehmen → Rechnung erstellen")
            FeatureRow(icon: "checkmark.seal.fill", color: .appBlue, text: "GoBD-konforme Belege & E-Rechnung")
        }
        .padding(.horizontal, 8)
    }

    private var buttons: some View {
        VStack(spacing: 14) {
            Button(action: onNext) {
                HStack {
                    Text("Kostenlos starten")
                        .font(.system(size: 17, weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(Color(red: 0.07, green: 0.20, blue: 0.48))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.white.opacity(0.25), radius: 12, x: 0, y: 4)
            }

            Button(action: onNext) {
                Text("Bereits Kunde? **Anmelden**")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.75))
            }
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(color)
            }
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.88))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.07))
        .cornerRadius(12)
    }
}

#Preview { OnboardingView().environmentObject(AppState()) }
