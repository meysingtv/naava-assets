import Foundation
import SwiftUI

struct ForecastDay: Identifiable {
    let id = UUID()
    let date: Date
    let weatherCode: Int
    let precipMM: Double
    let tempMax: Double
    let tempMin: Double

    var hasRain: Bool {
        precipMM > 1.0 || rainCodes.contains(weatherCode)
    }

    var icon: String {
        switch weatherCode {
        case 0:       return "sun.max.fill"
        case 1...3:   return "cloud.sun.fill"
        case 45, 48:  return "cloud.fog.fill"
        case 51...67: return "cloud.drizzle.fill"
        case 71...77: return "cloud.snow.fill"
        case 80...82: return "cloud.heavyrain.fill"
        case 95...99: return "cloud.bolt.rain.fill"
        default:      return "cloud.fill"
        }
    }

    var iconColor: Color {
        hasRain ? .appOrange : .appBlue
    }

    var shortDay: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "EE"
        return f.string(from: date)
    }

    var conditionLabel: String {
        switch weatherCode {
        case 0:       return "Sonnig"
        case 1:       return "Heiter"
        case 2:       return "Bewölkt"
        case 3:       return "Bedeckt"
        case 45, 48:  return "Nebel"
        case 51...55: return "Nieselregen"
        case 61...65: return "Regen"
        case 71...77: return "Schnee"
        case 80...82: return "Schauer"
        case 95...99: return "Gewitter"
        default:      return "Wechselhaft"
        }
    }

    private let rainCodes = Set([51,53,55,61,63,65,71,73,75,80,81,82,95,96,99])
}

@MainActor
class WeatherForecastService: ObservableObject {
    @Published var forecast: [ForecastDay] = []
    @Published var rainDays:  [ForecastDay] = []

    private var lastFetch: Date?

    func fetchIfNeeded() {
        if let last = lastFetch, Date().timeIntervalSince(last) < 3600 { return }
        Task { await fetch() }
    }

    private func fetch() async {
        let urlStr = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=51.19&longitude=6.44"
            + "&daily=weather_code,precipitation_sum,temperature_2m_max,temperature_2m_min"
            + "&timezone=Europe%2FBerlin&forecast_days=6"

        guard
            let url = URL(string: urlStr),
            let (data, _) = try? await URLSession.shared.data(from: url),
            let json    = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let daily   = json["daily"] as? [String: Any],
            let times   = daily["time"]         as? [String],
            let codes   = daily["weather_code"] as? [Int]
        else { return }

        let rawP    = daily["precipitation_sum"]  as? [Any] ?? []
        let rawMax  = daily["temperature_2m_max"] as? [Any] ?? []
        let rawMin  = daily["temperature_2m_min"] as? [Any] ?? []
        let precips = rawP.map   { ($0 as? Double) ?? 0.0 }
        let maxT    = rawMax.map { ($0 as? Double) ?? 0.0 }
        let minT    = rawMin.map { ($0 as? Double) ?? 0.0 }

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"

        let tomorrow = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )

        var days: [ForecastDay] = []
        for i in 0..<min(times.count, codes.count) {
            guard let date = fmt.date(from: times[i]), date >= tomorrow else { continue }
            days.append(ForecastDay(
                date:        date,
                weatherCode: codes[i],
                precipMM:    i < precips.count ? precips[i] : 0.0,
                tempMax:     i < maxT.count    ? maxT[i]    : 0.0,
                tempMin:     i < minT.count    ? minT[i]    : 0.0
            ))
        }

        forecast = Array(days.prefix(5))
        rainDays  = forecast.filter { $0.hasRain }
        lastFetch = Date()
    }
}
