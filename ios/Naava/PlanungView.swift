import SwiftUI

// MARK: - PlanungView

struct PlanungView: View {
    @State private var selectedTab = 0
    @State private var absences: [Absence]           = DummyData.absences
    @State private var assignments: [WorkAssignment] = DummyData.workAssignments
    @State private var showAbsenceSheet     = false
    @State private var showAddActionSheet   = false

    @EnvironmentObject private var toast: ToastManager

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("Kalender").tag(0)
                Text("Einsatzplan").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            if selectedTab == 0 {
                PlanungKalenderTab(absences: $absences)
                    .transition(.opacity)
            } else {
                PlanungEinsatzplanTab(absences: $absences, assignments: $assignments)
                    .transition(.opacity)
            }
        }
        .background(Color.appBackground)
        .navigationTitle("Planung")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if selectedTab == 0 {
                    Button {
                        showAddActionSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                    }
                } else {
                    Button {
                        showAbsenceSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Abwesenheit")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                }
            }
        }
        .confirmationDialog("Hinzufügen", isPresented: $showAddActionSheet) {
            Button("Termin") {
                toast.show("Termin-Funktion folgt demnächst", style: .info, icon: "calendar.badge.plus")
            }
            Button("Abwesenheit") {
                showAbsenceSheet = true
            }
            Button("Abbrechen", role: .cancel) {}
        }
        .sheet(isPresented: $showAbsenceSheet) {
            AddAbsenceSheet { newAbsence in
                absences.append(newAbsence)
            }
        }
    }
}

// MARK: - Kalender Tab

private struct PlanungKalenderTab: View {
    @Binding var absences: [Absence]
    @State private var currentMonth = Date()
    @State private var selectedDate = Date()

    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "de_DE")
        return c
    }
    private let weekdays  = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
    private let deLocale  = Locale(identifier: "de_DE")

    private var monthTitle: String {
        currentMonth.formatted(.dateTime.month(.wide).year().locale(deLocale)).capitalized
    }

    private var days: [Date?] {
        guard
            let range = cal.range(of: .day, in: .month, for: currentMonth),
            let first = cal.date(from: cal.dateComponents([.year, .month], from: currentMonth))
        else { return [] }
        let wd     = cal.component(.weekday, from: first)
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

    private func absencesForDay(_ date: Date) -> [Absence] {
        absences.filter { $0.covers(date) }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                calendarCard
                dayDetailCard
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    // MARK: Calendar Card

    private var calendarCard: some View {
        VStack(spacing: 10) {
            // Month navigation
            HStack {
                Button { stepMonth(-1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.appBlue)
                        .frame(width: 32, height: 32)
                }
                Spacer()
                Text(monthTitle)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                Spacer()
                Button { stepMonth(1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.appBlue)
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, 4)

            // Weekday header (Mo–So)
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { wd in
                    Text(wd)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.appTextSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day grid
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
                spacing: 2
            ) {
                ForEach(days.indices, id: \.self) { i in
                    if let date = days[i] {
                        KalenderDayCell(
                            date: date,
                            isToday: cal.isDateInToday(date),
                            isSelected: cal.isDate(date, inSameDayAs: selectedDate),
                            hasEvents: !events(for: date).isEmpty,
                            absenceDots: absencesForDay(date).map { $0.type.color }
                        ) {
                            selectedDate = date
                        }
                    } else {
                        Color.clear.frame(height: 46)
                    }
                }
            }
        }
        .padding(14)
        .cardStyle()
    }

    // MARK: Day Detail Card

    private var dayDetailCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(selectedDate.formatted(.dateTime.day().month(.wide).locale(deLocale)))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                Spacer()
                let evCount = events(for: selectedDate).count
                let abCount = absencesForDay(selectedDate).count
                HStack(spacing: 6) {
                    if evCount > 0 {
                        Text("\(evCount) Termin\(evCount == 1 ? "" : "e")")
                            .font(.system(size: 12))
                            .foregroundColor(.appTextSecondary)
                    }
                    if abCount > 0 {
                        Text("\(abCount) Abw.")
                            .font(.system(size: 12))
                            .foregroundColor(.appOrange)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            let dayEvents   = events(for: selectedDate)
            let dayAbsences = absencesForDay(selectedDate)

            if dayEvents.isEmpty && dayAbsences.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 28))
                        .foregroundColor(.appTextSecondary.opacity(0.3))
                    Text("Keine Einträge")
                        .font(.system(size: 13))
                        .foregroundColor(.appTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                Divider().padding(.horizontal, 16)

                ForEach(Array(dayEvents.enumerated()), id: \.element.id) { idx, event in
                    PlanEventRow(event: event)
                    if idx < dayEvents.count - 1 || !dayAbsences.isEmpty {
                        Divider().padding(.leading, 64)
                    }
                }

                ForEach(Array(dayAbsences.enumerated()), id: \.element.id) { idx, absence in
                    AbsenceRow(absence: absence)
                    if idx < dayAbsences.count - 1 {
                        Divider().padding(.leading, 64)
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

// MARK: - Kalender Day Cell

private struct KalenderDayCell: View {
    let date: Date
    let isToday: Bool
    let isSelected: Bool
    let hasEvents: Bool
    let absenceDots: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? Color.appBlue
                                : (isToday ? Color.appBlue.opacity(0.12) : Color.clear)
                        )
                        .frame(width: 32, height: 32)
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.system(size: 14, weight: isToday || isSelected ? .bold : .regular))
                        .foregroundColor(
                            isSelected
                                ? .white
                                : (isToday ? .appBlue : .appTextPrimary)
                        )
                }

                HStack(spacing: 2) {
                    if hasEvents {
                        Circle()
                            .fill(isSelected ? Color.white : Color.appBlue)
                            .frame(width: 4, height: 4)
                    }
                    ForEach(absenceDots.prefix(2).indices, id: \.self) { i in
                        Circle()
                            .fill(absenceDots[i])
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 6)
            }
        }
        .frame(height: 46)
    }
}

// MARK: - Plan Event Row

private struct PlanEventRow: View {
    let event: CalendarEvent

    var timeString: String {
        let h = Calendar.current.component(.hour,   from: event.date)
        let m = Calendar.current.component(.minute, from: event.date)
        return String(format: "%02d:%02d", h, m)
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(timeString)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.appTextSecondary)
                .frame(width: 40)

            Rectangle()
                .fill(event.status.color)
                .frame(width: 3)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 1) {
                Text(event.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                Text(event.customer)
                    .font(.system(size: 11))
                    .foregroundColor(.appTextSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
    }
}

// MARK: - Absence Row

private struct AbsenceRow: View {
    let absence: Absence

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: absence.type.icon)
                .font(.system(size: 14))
                .foregroundColor(absence.type.color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 1) {
                Text(absence.employeeName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                Text(absence.type.rawValue)
                    .font(.system(size: 11))
                    .foregroundColor(absence.type.color)
            }
            Spacer()
            if !absence.note.isEmpty {
                Text(absence.note)
                    .font(.system(size: 11))
                    .foregroundColor(.appTextSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
    }
}

// MARK: - Einsatzplan Tab

private struct PlanungEinsatzplanTab: View {
    @Binding var absences: [Absence]
    @Binding var assignments: [WorkAssignment]

    @State private var weekOffset = 0
    @State private var addAssignmentTarget: AssignmentTarget?

    private var cal: Calendar { Calendar.current }

    private var weekStart: Date {
        let base = cal.startOfWeek(for: Date())
        return cal.date(byAdding: .weekOfYear, value: weekOffset, to: base) ?? base
    }

    private var weekDays: [Date] {
        (0..<5).compactMap { cal.date(byAdding: .day, value: $0, to: weekStart) }
    }

    private var weekTitle: String {
        let kw = cal.component(.weekOfYear, from: weekStart)
        guard let end = weekDays.last else { return "KW \(kw)" }
        let fmtStart = DateFormatter()
        fmtStart.locale = Locale(identifier: "de_DE")
        fmtStart.dateFormat = "d."
        let fmtEnd = DateFormatter()
        fmtEnd.locale = Locale(identifier: "de_DE")
        fmtEnd.dateFormat = "d. MMM"
        let year = cal.component(.year, from: weekStart)
        return "KW \(kw) · \(fmtStart.string(from: weekStart))–\(fmtEnd.string(from: end)) \(year)"
    }

    private var activeEmployees: [Employee] {
        DummyData.employees.filter { $0.isActive }
    }

    private func assignment(for name: String, on date: Date) -> WorkAssignment? {
        assignments.first { $0.employeeName == name && cal.isDate($0.date, inSameDayAs: date) }
    }

    private func absence(for name: String, on date: Date) -> Absence? {
        absences.first { $0.employeeName == name && $0.covers(date) }
    }

    private func weekAssignmentCount() -> Int {
        assignments.filter { a in
            weekDays.contains { cal.isDate(a.date, inSameDayAs: $0) }
        }.count
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                weekNavBar
                gridCard
                summaryRow
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .sheet(item: $addAssignmentTarget) { target in
            AddAssignmentSheet(employeeName: target.employeeName, date: target.date) { newAssignment in
                assignments.append(newAssignment)
            }
        }
    }

    // MARK: Week Nav Bar

    private var weekNavBar: some View {
        HStack {
            Button { weekOffset -= 1 } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.appBlue)
                    .frame(width: 36, height: 36)
            }
            Spacer()
            Text(weekTitle)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.appTextPrimary)
            Spacer()
            Button { weekOffset += 1 } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.appBlue)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: Grid Card

    private var gridCard: some View {
        VStack(spacing: 0) {
            // Header row: name column + 5 day columns
            HStack(spacing: 0) {
                Text("Mitarbeiter")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.appTextSecondary)
                    .frame(width: 70, alignment: .leading)
                    .padding(.leading, 6)

                ForEach(weekDays, id: \.self) { day in
                    DayHeaderCell(date: day)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 8)
            .background(Color.white)

            Divider()

            // Employee rows
            ForEach(activeEmployees) { emp in
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        // Name column (70pt)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(emp.firstName)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.appTextPrimary)
                                .lineLimit(1)
                            Text(emp.lastName)
                                .font(.system(size: 10))
                                .foregroundColor(.appTextSecondary)
                                .lineLimit(1)
                        }
                        .frame(width: 70, alignment: .leading)
                        .padding(.leading, 6)

                        // Day cells
                        ForEach(weekDays, id: \.self) { day in
                            GridCell(
                                assignment: assignment(for: emp.fullName, on: day),
                                absence: absence(for: emp.fullName, on: day),
                                onAdd: {
                                    addAssignmentTarget = AssignmentTarget(
                                        employeeName: emp.fullName,
                                        date: day
                                    )
                                },
                                onRemove: {
                                    assignments.removeAll {
                                        $0.employeeName == emp.fullName
                                            && cal.isDate($0.date, inSameDayAs: day)
                                    }
                                }
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 4)

                    Divider().padding(.leading, 76)
                }
            }
        }
        .cardStyle()
    }

    // MARK: Summary Row

    private var summaryRow: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.appGreen)
            Text("\(weekAssignmentCount()) Einsätze diese Woche")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.appTextPrimary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .cardStyle()
    }
}

// MARK: - AssignmentTarget (Identifiable wrapper for sheet)

private struct AssignmentTarget: Identifiable {
    let id = UUID()
    let employeeName: String
    let date: Date
}

// MARK: - Day Header Cell

private struct DayHeaderCell: View {
    let date: Date
    private let cal = Calendar.current

    private var dayNum: Int { cal.component(.day, from: date) }
    private var weekdayAbbr: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "de_DE")
        fmt.dateFormat = "EE"
        return String(fmt.string(from: date).prefix(2)).capitalized
    }
    private var isToday: Bool { cal.isDateInToday(date) }

    var body: some View {
        VStack(spacing: 1) {
            Text(weekdayAbbr)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(isToday ? .appBlue : .appTextSecondary)
            Text("\(dayNum)")
                .font(.system(size: 12, weight: isToday ? .bold : .regular))
                .foregroundColor(isToday ? .appBlue : .appTextPrimary)
        }
    }
}

// MARK: - Grid Cell

private struct GridCell: View {
    let assignment: WorkAssignment?
    let absence: Absence?
    let onAdd: () -> Void
    let onRemove: () -> Void

    var body: some View {
        ZStack {
            if let ab = absence {
                AbsenceCellView(absence: ab)
            } else if let asgn = assignment {
                AssignmentCellView(assignment: asgn)
                    .onLongPressGesture { onRemove() }
            } else {
                EmptyCellView(onAdd: onAdd)
            }
        }
        .padding(2)
        .frame(height: 56)
    }
}

// MARK: - Assignment Cell View

private struct AssignmentCellView: View {
    let assignment: WorkAssignment

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(assignment.orderTitle)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Text(assignment.orderNumber)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(assignment.color)
        )
    }
}

// MARK: - Absence Cell View

private struct AbsenceCellView: View {
    let absence: Absence

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: absence.type.icon)
                .font(.system(size: 11))
                .foregroundColor(.white)
            Text(absence.type.rawValue)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(absence.type.color.opacity(0.85))
        )
    }
}

// MARK: - Empty Cell View

private struct EmptyCellView: View {
    let onAdd: () -> Void

    var body: some View {
        Button(action: onAdd) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(UIColor.systemGray6))
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.appTextSecondary.opacity(0.5))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AddAssignmentSheet

struct AddAssignmentSheet: View {
    let employeeName: String
    let date: Date
    let onAdd: (WorkAssignment) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedOrderIndex = 0

    private let deLocale = Locale(identifier: "de_DE")

    private var dateString: String {
        date.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(deLocale))
    }

    private let assignmentColors: [Color] = [.appBlue, .appGreen, .appOrange, .appPurple]

    var body: some View {
        NavigationStack {
            Form {
                Section("Mitarbeiter") {
                    Text(employeeName)
                        .font(.system(size: 15))
                        .foregroundColor(.appTextPrimary)
                }

                Section("Datum") {
                    Text(dateString)
                        .font(.system(size: 15))
                        .foregroundColor(.appTextPrimary)
                }

                Section("Auftrag") {
                    Picker("Auftrag", selection: $selectedOrderIndex) {
                        ForEach(DummyData.orders.indices, id: \.self) { i in
                            VStack(alignment: .leading) {
                                Text(DummyData.orders[i].title)
                                Text(DummyData.orders[i].number)
                                    .font(.caption)
                                    .foregroundColor(.appTextSecondary)
                            }
                            .tag(i)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .navigationTitle("Einsatz hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Hinzufügen") {
                        guard DummyData.orders.indices.contains(selectedOrderIndex) else { return }
                        let order      = DummyData.orders[selectedOrderIndex]
                        let colorIndex = abs(employeeName.hashValue) % assignmentColors.count
                        let newEntry   = WorkAssignment(
                            employeeName: employeeName,
                            orderTitle:  order.title,
                            orderNumber: order.number,
                            date:        date,
                            color:       assignmentColors[colorIndex]
                        )
                        onAdd(newEntry)
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.appBlue)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - AddAbsenceSheet

struct AddAbsenceSheet: View {
    let onAdd: (Absence) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedEmployeeIndex = 0
    @State private var selectedType: AbsenceType = .urlaub
    @State private var startDate = Date()
    @State private var endDate   = Date()
    @State private var note      = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Mitarbeiter") {
                    Picker("Mitarbeiter", selection: $selectedEmployeeIndex) {
                        ForEach(DummyData.employees.indices, id: \.self) { i in
                            Text(DummyData.employees[i].fullName).tag(i)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Art der Abwesenheit") {
                    ForEach(AbsenceType.allCases, id: \.self) { type in
                        Button {
                            selectedType = type
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: type.icon)
                                    .font(.system(size: 14))
                                    .foregroundColor(type.color)
                                    .frame(width: 22)
                                Text(type.rawValue)
                                    .font(.system(size: 15))
                                    .foregroundColor(.appTextPrimary)
                                Spacer()
                                if selectedType == type {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.appBlue)
                                }
                            }
                        }
                    }
                }

                Section("Zeitraum") {
                    DatePicker("Von", selection: $startDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "de_DE"))
                    DatePicker("Bis", selection: $endDate, in: startDate..., displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "de_DE"))
                }

                Section("Notiz (optional)") {
                    TextField("z. B. Ärztliches Attest vorhanden", text: $note)
                        .font(.system(size: 15))
                }
            }
            .navigationTitle("Abwesenheit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Speichern") {
                        guard DummyData.employees.indices.contains(selectedEmployeeIndex) else { return }
                        let emp = DummyData.employees[selectedEmployeeIndex]
                        let newAbsence = Absence(
                            employeeName: emp.fullName,
                            type:         selectedType,
                            startDate:    startDate,
                            endDate:      max(endDate, startDate),
                            note:         note
                        )
                        onAdd(newAbsence)
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.appBlue)
                }
            }
        }
        .presentationDetents([.large])
    }
}

#Preview {
    NavigationStack {
        PlanungView()
    }
    .environmentObject(ToastManager())
}
