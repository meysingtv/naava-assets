import SwiftUI

struct StatsCard: View {
    let item: StatItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(item.color.opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: item.icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(item.color)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.appTextSecondary)
            }

            Text(item.value)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.appTextPrimary)

            Text(item.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.appTextSecondary)
        }
        .padding(16)
        .cardStyle()
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        ForEach(DummyData.stats) { stat in
            StatsCard(item: stat)
        }
    }
    .padding()
    .background(Color.appBackground)
}
