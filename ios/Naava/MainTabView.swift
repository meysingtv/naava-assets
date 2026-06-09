import SwiftUI

struct MainTabView: View {
    @State private var selectedTab     = 0
    @State private var showNewSheet    = false
    @State private var showNewOrder    = false
    @State private var showNewInvoice  = false
    @State private var showNewQuote    = false
    @State private var showNewCustomer = false

    @EnvironmentObject private var toast: ToastManager

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                NavigationStack { DashboardView() }.tag(0)
                NavigationStack { AppointmentsView() }.tag(1)
                Color.clear.tag(2)
                NavigationStack { CustomersView() }.tag(3)
                NavigationStack { MoreView() }.tag(4)
            }
            .accentColor(.appBlue)

            CustomTabBar(selectedTab: $selectedTab, showNewSheet: $showNewSheet)
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showNewSheet) {
            NewActionSheet(
                onNewOrder:    { showNewSheet = false; DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showNewOrder    = true } },
                onNewInvoice:  { showNewSheet = false; DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showNewInvoice  = true } },
                onNewQuote:    { showNewSheet = false; DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showNewQuote    = true } },
                onNewCustomer: { showNewSheet = false; DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showNewCustomer = true } }
            )
        }
        .sheet(isPresented: $showNewOrder) {
            NewOrderView { _ in
                toast.show("Auftrag erstellt", style: .success, icon: "briefcase.fill")
            }
        }
        .sheet(isPresented: $showNewInvoice) {
            NewInvoiceView { invoice in
                DummyData.invoices.insert(invoice, at: 0)
                toast.show("Rechnung erstellt", style: .success, icon: "eurosign.circle.fill")
            }
        }
        .sheet(isPresented: $showNewQuote) {
            NewQuoteView { _ in
                toast.show("Angebot erstellt", style: .success, icon: "doc.text.fill")
            }
        }
        .sheet(isPresented: $showNewCustomer) {
            NewCustomerView { customer in
                DummyData.customers.append(customer)
                toast.show("Kunde gespeichert", style: .success, icon: "person.badge.plus")
            }
        }
    }
}

// MARK: - Custom Tab Bar

private struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Binding var showNewSheet: Bool

    private let tabs: [(icon: String, label: String, tag: Int)] = [
        ("house.fill",     "Dashboard", 0),
        ("briefcase.fill", "Aufträge",  1),
        ("plus",           "",          2),
        ("person.2.fill",  "Kunden",    3),
        ("ellipsis",       "Mehr",      4),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.tag) { tab in
                if tab.tag == 2 {
                    fabButton
                } else {
                    TabBarButton(
                        icon: tab.icon,
                        label: tab.label,
                        isSelected: selectedTab == tab.tag,
                        action: { selectedTab = tab.tag }
                    )
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 28)
        .background(
            Color.white
                .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: -2)
        )
    }

    private var fabButton: some View {
        Button(action: { showNewSheet = true }) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.28, green: 0.54, blue: 1.0), Color.appBlue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 54, height: 54)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                )
                .shadow(color: Color.appBlue.opacity(0.45), radius: 10, x: 0, y: 5)
        }
        .offset(y: -18)
        .frame(maxWidth: .infinity)
    }
}

private struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .appBlue : .appTextSecondary)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .appBlue : .appTextSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - New Action Sheet (FAB)

private struct NewActionSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onNewOrder:    () -> Void = {}
    var onNewInvoice:  () -> Void = {}
    var onNewQuote:    () -> Void = {}
    var onNewCustomer: () -> Void = {}

    private let actions: [(icon: String, title: String, subtitle: String, color: Color)] = [
        ("briefcase.fill",       "Neuer Auftrag",  "Baustelle anlegen",    .appBlue),
        ("doc.text.fill",        "Neues Angebot",  "Angebot erstellen",    .appOrange),
        ("eurosign.circle.fill", "Neue Rechnung",  "Rechnung ausstellen",  .appGreen),
        ("person.badge.plus",    "Neuer Kunde",    "Kundendaten eingeben", .appPurple),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ForEach(actions, id: \.title) { action in
                    Button(action: {
                        switch action.title {
                        case "Neuer Auftrag":  onNewOrder()
                        case "Neues Angebot":  onNewQuote()
                        case "Neue Rechnung":  onNewInvoice()
                        case "Neuer Kunde":    onNewCustomer()
                        default:               dismiss()
                        }
                    }) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(action.color.opacity(0.13))
                                    .frame(width: 44, height: 44)
                                Image(systemName: action.icon)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(action.color)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(action.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.appTextPrimary)
                                Text(action.subtitle)
                                    .font(.system(size: 13))
                                    .foregroundColor(.appTextSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.appTextSecondary.opacity(0.4))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                    Divider().padding(.leading, 78)
                }
                Spacer()
            }
            .padding(.top, 8)
            .background(Color.appBackground)
            .navigationTitle("Was möchtest du tun?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(.appBlue)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
        .environmentObject(ToastManager())
}
