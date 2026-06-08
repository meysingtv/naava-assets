import SwiftUI

struct WeatherWarningCard: View {
    @StateObject private var service = WeatherForecastService()

    var body: some View {
        Group {
            if !service.forecast.isEmpty {
                card
            }
        }
        .onAppear { service.fetchIfNeeded() }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Header
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill((service.rainDays.isEmpty ? Color.appBlue : Color.appOrange).opacity(0.12))
                        .frame(width: 34, height: 34)
                    Image(systemName: service.rainDays.isEmpty ? "sun.max.fill" : "cloud.rain.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(service.rainDays.isEmpty ? .appBlue : .appOrange)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(service.rainDays.isEmpty ? "Gutes Wetter diese Woche" : "Regenwarnung")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                    Text(service.rainDays.isEmpty
                         ? "Keine Niederschläge in den nächsten Tagen"
                         : "\(service.rainDays.count) Regentag\(service.rainDays.count > 1 ? "e" : "") – Außenarbeiten prüfen")
                        .font(.system(size: 12))
                        .foregroundColor(.appTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Forecast tiles
            HStack(spacing: 6) {
                ForEach(service.forecast) { day in
                    VStack(spacing: 5) {
                        Image(systemName: day.icon)
                            .font(.system(size: 15))
                            .foregroundColor(day.iconColor)
                        Text(day.shortDay)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.appTextSecondary)
                        if day.precipMM > 0.5 {
                            Text("\(Int(day.precipMM))mm")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(day.hasRain ? .appOrange : .appTextSecondary)
                        } else {
                            Text("–")
                                .font(.system(size: 9))
                                .foregroundColor(.appTextSecondary.opacity(0.4))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(day.hasRain ? Color.appOrange.opacity(0.07) : Color.appBackground)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(day.hasRain ? Color.appOrange.opacity(0.25) : Color.clear, lineWidth: 1)
                    )
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    service.rainDays.isEmpty ? Color.clear : Color.appOrange.opacity(0.2),
                    lineWidth: 1
                )
        )
    }
}

#Preview {
    WeatherWarningCard()
        .padding()
        .background(Color.appBackground)
}
