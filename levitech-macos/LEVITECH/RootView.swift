//
//  RootView.swift
//  Handy-Rahmen, Statusbar, Screen-Router und Bottom-Navigation.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        ZStack {
            // Backdrop
            LinearGradient(colors: [Color(hex: 0x1a0608), Color(hex: 0x050506)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            phone
                .frame(width: 390, height: 844)
                .background(Theme.bg)
                .clipShape(RoundedRectangle(cornerRadius: 46))
                .overlay(RoundedRectangle(cornerRadius: 46).stroke(Color(hex: 0x1c1c20), lineWidth: 2))
                .shadow(color: .black.opacity(0.6), radius: 40, y: 20)
                .padding(24)
        }
    }

    private var phone: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                StatusBar()
                screenContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            TabBar()

            // Toast
            if let t = store.toast {
                Text(t)
                    .font(.system(size: 14, weight: .semibold)).foregroundColor(Theme.text)
                    .padding(.horizontal, 18).padding(.vertical, 12)
                    .background(Theme.surface3)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.lineStrong, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.5), radius: 12, y: 6)
                    .padding(.bottom, 86)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.25), value: store.toast)
    }

    @ViewBuilder
    private var screenContent: some View {
        switch store.screen {
        case .dashboard:     DashboardView()
        case .tickets:       TicketsView()
        case .ticketDetail:  TicketDetailView()
        case .ticketEdit:    TicketEditView()
        case .customer:      CustomerView()
        case .timecard:      TimeCardView()
        case .zeiterfassung: ZeiterfassungView()
        case .notifications: NotificationsView()
        case .passwords:     PasswordsView()
        case .ki:            KIAssistantView()
        case .checklists:    ChecklistsView()
        case .documents:     DocumentsView()
        case .profile:       ProfileView()
        case .more:          MoreView()
        }
    }
}

// MARK: - Statusbar

struct StatusBar: View {
    var body: some View {
        HStack {
            Text("9:41").font(.system(size: 14, weight: .semibold))
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "cellularbars")
                Image(systemName: "wifi")
                Image(systemName: "battery.75")
            }
            .font(.system(size: 13, weight: .semibold))
        }
        .foregroundColor(Theme.text)
        .padding(.horizontal, 26)
        .frame(height: 44)
    }
}

// MARK: - Bottom-Navigation

struct TabBar: View {
    @EnvironmentObject var store: Store

    private let tabs: [(AppTab, String, String)] = [
        (.dashboard, "house.fill", "Dashboard"),
        (.tickets, "ticket.fill", "Tickets"),
        (.timecard, "clock.fill", "TimeCard"),
        (.customer, "person.2.fill", "Kunden"),
        (.more, "line.3.horizontal", "Mehr"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.0) { tab, icon, label in
                let active = store.activeTab == tab
                VStack(spacing: 4) {
                    Image(systemName: icon).font(.system(size: 20))
                    Text(label).font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(active ? Theme.red2 : Theme.text3)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { store.selectTab(tab) }
            }
        }
        .padding(.top, 10).padding(.bottom, 12)
        .background(.ultraThinMaterial)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Theme.line), alignment: .top)
    }
}
