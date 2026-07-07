import SwiftUI

struct TodayCard: View {
    let appointments: [Appointment]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("HEUTE")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.appTextSecondary)
                        .kerning(0.8)
                    Text("\(appointments.count) Termine")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                }
                Spacer()
                Button(action: {}) {
                    Text("Alle anzeigen")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.appBlue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider().padding(.horizontal, 16)

            ForEach(Array(appointments.enumerated()), id: \.element.id) { index, appt in
                AppointmentRow(appointment: appt)
                if index < appointments.count - 1 {
                    Divider().padding(.leading, 60)
                }
            }
        }
        .cardStyle()
    }
}

private struct AppointmentRow: View {
    let appointment: Appointment

    var body: some View {
        HStack(spacing: 12) {
            Text(appointment.time)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.appTextSecondary)
                .frame(width: 36)

            Rectangle()
                .fill(appointment.status.color)
                .frame(width: 3)
                .cornerRadius(2)
                .padding(.vertical, 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(appointment.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                Text(appointment.customer)
                    .font(.system(size: 12))
                    .foregroundColor(.appTextSecondary)
            }

            Spacer()

            StatusBadge(status: appointment.status)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(minHeight: 54)
    }
}

#Preview {
    TodayCard(appointments: DummyData.appointments)
        .padding()
        .background(Color.appBackground)
}
