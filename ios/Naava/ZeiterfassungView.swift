import SwiftUI

struct ZeiterfassungView: View {
    @State private var entries: [TimeEntry] = DummyData.timeEntries
    @State private var showCheckIn = false
    @State private var now = Date()

    private let ticker = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var activeEntry: TimeEntry? { entries.first { $0.isActive } }

    private var todayEntries: [TimeEntry] {
        entries.filter { Calendar.current.isDateInToday($0.startTime) }
    }

    private var weekData: [(day: Date, hours: Double)] {
        let cal = Calendar.current
        let weekStart = cal.startOfWeek(for: now)
        return (0..<5).compactMap { offset -> (Date, Double)? in
            guard let day = cal.date(byAdding: .day, value: offset, to: weekStart) else { return nil }
            let total = entries
                .filter { cal.isDate($0.startTime, inSameDayAs: day) }
                .reduce(0.0) { $0 + $1.netDuration(at: now) / 3600 }
            return (day, total)
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                if let active = activeEntry {
                    activeCard(active)
                }
                statsRow
                if !todayEntries.filter({ !$0.isActive }).isEmpty {
                    todaySection
                }
                weekSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Color.appBackground)
        .navigationTitle("Zeiterfassung")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if activeEntry == nil {
                    Button(action: { showCheckIn = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Einstempeln")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.appGreen)
                    }
                }
            }
        }
        .sheet(isPresented: $showCheckIn) {
            CheckInSheet { name, order in
                entries.insert(TimeEntry(employeeName: name, orderTitle: order, startTime: Date()), at: 0)
            }
        }
        .onReceive(ticker) { t in now = t }
    }

    // MARK: - Active card

    @ViewBuilder
    private func activeCard(_ entry: TimeEntry) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Color.appGreen.opacity(0.15)).frame(width: 46, height: 46)
                    Image(systemName: "timer")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.appGreen)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.employeeName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                    Text(entry.orderTitle)
                        .font(.system(size: 13))
                        .foregroundColor(.appTextSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(entry.formattedNet(at: now))
                        .font(.system(size: 24, weight: .bold).monospacedDigit())
                        .foregroundColor(.appGreen)
                    Text("seit \(entry.startTime.formatted(.dateTime.hour().minute()))")
                        .font(.system(size: 11))
                        .foregroundColor(.appTextSecondary)
                }
            }
            Button(action: { clockOut(entry) }) {
                Label("Ausstempeln", systemImage: "stop.circle.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color.appGreen)
                    .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appGreen.opacity(0.3), lineWidth: 1.5))
    }

    // MARK: - Stats row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statsCell("Heute",
                      value: hoursString(todayEntries.reduce(0) { $0 + $1.netDuration(at: now) }),
                      icon: "sun.max.fill", color: .appOrange)
            Divider().frame(height: 38)
            statsCell("Diese Woche",
                      value: hoursString(weekData.reduce(0) { $0 + $1.hours * 3600 }),
                      icon: "calendar", color: .appBlue)
            Divider().frame(height: 38)
            statsCell("Einträge heute",
                      value: "\(todayEntries.count)",
                      icon: "list.bullet", color: .appPurple)
        }
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    private func statsCell(_ label: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 13, weight: .semibold)).foregroundColor(color)
            Text(value).font(.system(size: 17, weight: .bold).monospacedDigit()).foregroundColor(.appTextPrimary)
            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Today section

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HEUTE")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.appTextSecondary)
                .kerning(0.6)

            let finished = todayEntries.filter { !$0.isActive }
            VStack(spacing: 0) {
                ForEach(Array(finished.enumerated()), id: \.element.id) { i, entry in
                    entryRow(entry)
                    if i < finished.count - 1 {
                        Divider().padding(.leading, 52)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
    }

    private func entryRow(_ entry: TimeEntry) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.appBlue.opacity(0.10))
                    .frame(width: 38, height: 38)
                Image(systemName: "person.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appBlue)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.employeeName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                Text(entry.orderTitle)
                    .font(.system(size: 12))
                    .foregroundColor(.appTextSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.formattedNet(at: now))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                Text(timeRange(entry))
                    .font(.system(size: 11))
                    .foregroundColor(.appTextSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Week section

    private var weekSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DIESE WOCHE")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.appTextSecondary)
                .kerning(0.6)

            let maxH = weekData.map(\.hours).max() ?? 0

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(weekData, id: \.day) { item in
                    let isToday = Calendar.current.isDateInToday(item.day)
                    let ratio = maxH > 0 ? item.hours / maxH : 0

                    VStack(spacing: 5) {
                        Text(item.hours > 0.1 ? String(format: "%.1fh", item.hours) : "")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.appTextSecondary)
                        RoundedRectangle(cornerRadius: 5)
                            .fill(isToday ? Color.appBlue : Color.appBlue.opacity(0.25))
                            .frame(height: max(4, CGFloat(ratio) * 70))
                        Text(shortDay(item.day))
                            .font(.system(size: 11, weight: isToday ? .bold : .regular))
                            .foregroundColor(isToday ? .appBlue : .appTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Helpers

    private func clockOut(_ entry: TimeEntry) {
        if let i = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[i].endTime = Date()
        }
    }

    private func hoursString(_ secs: TimeInterval) -> String {
        let h = Int(secs) / 3600
        let m = (Int(secs) % 3600) / 60
        return h == 0 ? "\(m)min" : String(format: "%dh %02d", h, m)
    }

    private func timeRange(_ e: TimeEntry) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        let end = e.endTime.map { f.string(from: $0) } ?? "läuft"
        return "\(f.string(from: e.startTime)) – \(end)"
    }

    private func shortDay(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "EE"
        return f.string(from: d)
    }
}

// MARK: - Check-In Sheet

private struct CheckInSheet: View {
    var onCheckIn: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedEmployee = DummyData.employees.first?.fullName ?? ""
    @State private var selectedOrder    = DummyData.orders.first?.title ?? ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Mitarbeiter") {
                    Picker("Auswählen", selection: $selectedEmployee) {
                        ForEach(DummyData.employees.filter(\.isActive)) { emp in
                            Label(emp.fullName, systemImage: "person.fill").tag(emp.fullName)
                        }
                    }
                }
                Section("Auftrag") {
                    Picker("Auswählen", selection: $selectedOrder) {
                        ForEach(DummyData.orders) { order in
                            Text("\(order.number) – \(order.title)").tag(order.title)
                        }
                    }
                }
                Section {
                    Button {
                        onCheckIn(selectedEmployee, selectedOrder)
                        dismiss()
                    } label: {
                        Label("Jetzt einstempeln", systemImage: "play.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .listRowBackground(Color.appGreen)
                }
            }
            .navigationTitle("Einstempeln")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { dismiss() }.foregroundColor(.appTextSecondary)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    NavigationStack { ZeiterfassungView() }
}
