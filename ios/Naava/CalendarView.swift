import SwiftUI

struct CalendarView: View {
    @State private var currentMonth = Date()
    @State private var selectedDate = Date()
    private let cal = Calendar(identifier: .gregorian)
    private let weekdays = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]

    private var monthTitle: String {
        currentMonth.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "de_DE"))).capitalized
    }

    private var days: [Date?] {
        guard let range = cal.range(of: .day, in: .month, for: currentMonth),
              let first = cal.date(from: cal.dateComponents([.year, .month], from: currentMonth))
        else { return [] }
        let wd = cal.component(.weekday, from: first)
        let offset = (wd - 2 + 7) % 7
        var result: [Date?] = Array(repeating: nil, count: offset)
        for n in range {
            result.append(cal.date(byAdding: .day, value: n - 1, to: first))
        }
        while result.count % 7 != 0 { result.append(nil) }
        return result
    }

    private func events(for date: Date) -> [CalendarEvent] {
        DummyData.calendarEvents.filter { cal.isDate($0.date, inSameDayAs: date) }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                calendarCard
                eventsCard
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color.appBackground)
        .navigationTitle("Kalender")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: - Calendar Card

    private var calendarCard: some View {
        VStack(spacing: 12) {
            // Month nav
            HStack {
                Button(action: { stepMonth(-1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.appBlue)
                }
                Spacer()
                Text(monthTitle)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                Spacer()
                Button(action: { stepMonth(1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.appBlue)
                }
            }
            .padding(.horizontal, 6)

            // Weekday labels
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { wd in
                    Text(wd)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.appTextSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                ForEach(days.indices, id: \.self) { i in
                    if let date = days[i] {
                        DayCell(
                            date: date,
                            isToday: cal.isDateInToday(date),
                            isSelected: cal.isDate(date, inSameDayAs: selectedDate),
                            hasEvents: !events(for: date).isEmpty,
                            action: { selectedDate = date }
                        )
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: - Events for selected day

    private var eventsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(selectedDate.formatted(.dateTime.day().month(.wide).locale(Locale(identifier: "de_DE"))))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                Spacer()
                Text("\(events(for: selectedDate).count) Termine")
                    .font(.system(size: 13))
                    .foregroundColor(.appTextSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            let dayEvents = events(for: selectedDate)
            if dayEvents.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 32))
                        .foregroundColor(.appTextSecondary.opacity(0.3))
                    Text("Keine Termine")
                        .font(.system(size: 14))
                        .foregroundColor(.appTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
            } else {
                Divider().padding(.horizontal, 16)
                ForEach(Array(dayEvents.enumerated()), id: \.element.id) { idx, event in
                    EventRow(event: event)
                    if idx < dayEvents.count - 1 {
                        Divider().padding(.leading, 72)
                    }
                }
            }
        }
        .cardStyle()
    }

    private func stepMonth(_ n: Int) {
        if let d = cal.date(byAdding: .month, value: n, to: currentMonth) {
            currentMonth = d
        }
    }
}

// MARK: - Day Cell

private struct DayCell: View {
    let date: Date
    let isToday: Bool
    let isSelected: Bool
    let hasEvents: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.appBlue : (isToday ? Color.appBlue.opacity(0.12) : Color.clear))
                        .frame(width: 34, height: 34)
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.system(size: 15, weight: isToday || isSelected ? .bold : .regular))
                        .foregroundColor(isSelected ? .white : (isToday ? .appBlue : .appTextPrimary))
                }
                Circle()
                    .fill(hasEvents ? (isSelected ? Color.white : Color.appBlue) : Color.clear)
                    .frame(width: 4, height: 4)
            }
        }
        .frame(height: 48)
    }
}

// MARK: - Event Row

private struct EventRow: View {
    let event: CalendarEvent

    var timeString: String {
        let cal = Calendar.current
        let h = cal.component(.hour, from: event.date)
        let m = cal.component(.minute, from: event.date)
        return String(format: "%02d:%02d", h, m)
    }

    var durationString: String {
        let h = event.durationMinutes / 60
        let m = event.durationMinutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text(timeString)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.appTextPrimary)
                Text(durationString)
                    .font(.system(size: 10))
                    .foregroundColor(.appTextSecondary)
            }
            .frame(width: 44)

            Rectangle()
                .fill(event.status.color)
                .frame(width: 3)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                Text(event.customer)
                    .font(.system(size: 12))
                    .foregroundColor(.appTextSecondary)
            }
            Spacer()
            StatusBadge(status: event.status)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

#Preview {
    NavigationStack { CalendarView() }
}
