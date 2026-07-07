import SwiftUI

struct StatusBadge: View {
    let status: AppointmentStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 6, height: 6)
            Text(status.rawValue)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.12))
        .cornerRadius(6)
    }
}

#Preview {
    HStack(spacing: 8) {
        StatusBadge(status: .inProgress)
        StatusBadge(status: .planned)
        StatusBadge(status: .open)
    }
    .padding()
}
