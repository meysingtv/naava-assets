import SwiftUI

struct PlanSelectionView: View {
    var onDone: () -> Void
    @EnvironmentObject var appState: AppState

    @State private var selectedPlan: SubscriptionPlan = .pro
    @State private var isYearly = false
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    progressHeader(step: 3, total: 3, title: "Dein Plan", subtitle: "14 Tage kostenlos testen – jederzeit kündbar.")

                    billingToggle

                    VStack(spacing: 12) {
                        ForEach(SubscriptionPlan.allCases, id: \.self) { plan in
                            PlanCard(plan: plan, isSelected: selectedPlan == plan, isYearly: isYearly) {
                                withAnimation(.spring(response: 0.3)) { selectedPlan = plan }
                            }
                        }
                    }

                    trialNote

                    ctaButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Billing toggle

    private var billingToggle: some View {
        HStack(spacing: 0) {
            billingOption(label: "Monatlich", selected: !isYearly) { withAnimation { isYearly = false } }
            billingOption(label: "Jährlich", badge: "-20%", selected: isYearly) { withAnimation { isYearly = true } }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    private func billingOption(label: String, badge: String? = nil, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(selected ? .white : .appTextSecondary)
                if let b = badge {
                    Text(b)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(selected ? .appGreen : .appGreen)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background((selected ? Color.white : Color.appGreen).opacity(selected ? 0.25 : 0.15))
                        .cornerRadius(6)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(selected ? Color.appBlue : Color.clear)
            .cornerRadius(10)
            .padding(3)
        }
    }

    // MARK: - Trial note

    private var trialNote: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.shield.fill")
                .foregroundColor(.appGreen)
                .font(.system(size: 16))
            VStack(alignment: .leading, spacing: 2) {
                Text("14 Tage kostenlos testen")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                Text("Keine Kreditkarte nötig · Jederzeit kündbar")
                    .font(.system(size: 12))
                    .foregroundColor(.appTextSecondary)
            }
        }
        .padding(14)
        .background(Color.appGreen.opacity(0.08))
        .cornerRadius(12)
    }

    // MARK: - CTA

    private var ctaButton: some View {
        VStack(spacing: 10) {
            Button(action: confirmPlan) {
                ZStack {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        HStack(spacing: 8) {
                            Text("Jetzt starten – \(price(selectedPlan))")
                                .font(.system(size: 17, weight: .bold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(selectedPlan.color)
                .cornerRadius(16)
                .shadow(color: selectedPlan.color.opacity(0.4), radius: 10, x: 0, y: 4)
            }
            .disabled(isLoading)

            Text("Danach \(price(selectedPlan))/Monat · Jederzeit kündbar")
                .font(.system(size: 12))
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private func price(_ plan: SubscriptionPlan) -> String {
        let p = isYearly ? plan.yearlyMonthlyPrice : plan.monthlyPrice
        return "\(p) €"
    }

    private func confirmPlan() {
        isLoading = true
        appState.selectedPlanRaw = selectedPlan.rawValue
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            onDone()
        }
    }
}

// MARK: - Plan Card

private struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let isYearly: Bool
    let onSelect: () -> Void

    private var price: Int { isYearly ? plan.yearlyMonthlyPrice : plan.monthlyPrice }
    private var isRecommended: Bool { plan == .pro }

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 0) {
                // Header
                HStack(alignment: .top) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(plan.color.opacity(0.15))
                                .frame(width: 38, height: 38)
                            Image(systemName: plan.icon)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(plan.color)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(plan.rawValue)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.appTextPrimary)
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text("\(price) €")
                                    .font(.system(size: 22, weight: .black))
                                    .foregroundColor(plan.color)
                                Text("/ Monat")
                                    .font(.system(size: 12))
                                    .foregroundColor(.appTextSecondary)
                            }
                        }
                    }
                    Spacer()
                    if isRecommended {
                        Text("⭐ BELIEBT")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(plan.color)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(plan.color.opacity(0.12))
                            .cornerRadius(8)
                    }
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(plan.color)
                            .font(.system(size: 22))
                    }
                }
                .padding(16)

                // Features
                if isSelected {
                    Divider().padding(.horizontal, 16)
                    VStack(spacing: 6) {
                        ForEach(plan.features, id: \.label) { feature in
                            HStack(spacing: 10) {
                                Image(systemName: feature.included ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(feature.included ? .appGreen : .appTextSecondary.opacity(0.4))
                                Text(feature.label)
                                    .font(.system(size: 13))
                                    .foregroundColor(feature.included ? .appTextPrimary : .appTextSecondary.opacity(0.5))
                                Spacer()
                            }
                        }
                    }
                    .padding(16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? plan.color : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? plan.color.opacity(0.15) : Color.black.opacity(0.05),
                    radius: isSelected ? 12 : 6, x: 0, y: 3)
        }
    }
}

#Preview { PlanSelectionView { }.environmentObject(AppState()) }
