import Foundation
import SwiftUI

@MainActor
class WeatherService: ObservableObject {
    @Published var temperature: Int?
    @Published var conditionText: String = "Laden…"
    @Published var conditionIcon: String = "cloud"
    @Published var iconColor: Color = .gray

    private var lastFetch: Date?

    func fetchIfNeeded() {
        if let last = lastFetch, Date().timeIntervalSince(last) < 1800 { return }
        Task { await fetch() }
    }

    private func fetch() async {
        let urlString = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=51.1963&longitude=6.4428"
            + "&current=temperature_2m,weathercode"
            + "&timezone=Europe%2FBerlin"
        guard let url = URL(string: urlString) else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let resp = try JSONDecoder().decode(OMResponse.self, from: data)
            temperature = Int(resp.current.temperature_2m.rounded())
            let info = weatherInfo(for: resp.current.weathercode)
            conditionIcon = info.icon
            conditionText = info.text
            iconColor      = info.color
            lastFetch = Date()
        } catch {
            conditionText = "–"
        }
    }

    private struct WeatherInfo { let icon: String; let text: String; let color: Color }

    private func weatherInfo(for code: Int) -> WeatherInfo {
        switch code {
        case 0:         return WeatherInfo(icon: "sun.max.fill",          text: "Sonnig",          color: .appOrange)
        case 1:         return WeatherInfo(icon: "sun.max.fill",          text: "Meist klar",      color: .appOrange)
        case 2:         return WeatherInfo(icon: "cloud.sun.fill",        text: "Leicht bewölkt",  color: .appOrange)
        case 3:         return WeatherInfo(icon: "cloud.fill",            text: "Bewölkt",         color: .gray)
        case 45, 48:    return WeatherInfo(icon: "cloud.fog.fill",        text: "Nebel",           color: .gray)
        case 51, 53, 55:return WeatherInfo(icon: "cloud.drizzle.fill",    text: "Nieselregen",     color: .appBlue)
        case 61, 63, 65:return WeatherInfo(icon: "cloud.rain.fill",       text: "Regen",           color: .appBlue)
        case 71, 73, 75:return WeatherInfo(icon: "cloud.snow.fill",       text: "Schnee",          color: .appBlue)
        case 80, 81, 82:return WeatherInfo(icon: "cloud.heavyrain.fill",  text: "Schauer",         color: .appBlue)
        case 95...99:   return WeatherInfo(icon: "cloud.bolt.rain.fill",  text: "Gewitter",        color: .appOrange)
        default:        return WeatherInfo(icon: "cloud",                 text: "Bedeckt",         color: .gray)
        }
    }
}

// MARK: - Decodable models

private struct OMResponse: Decodable {
    let current: OMCurrent
}

private struct OMCurrent: Decodable {
    let temperature_2m: Double
    let weathercode: Int
}
