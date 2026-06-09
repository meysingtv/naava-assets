import SwiftUI
import CoreLocation

/// Resolves the company HQ address from AppState into a coordinate.
/// Caches the result in UserDefaults so we don't re-geocode on every launch.
@MainActor
final class CompanyLocationService: ObservableObject {
    @Published private(set) var coordinate: CLLocationCoordinate2D?

    private let geocoder = CLGeocoder()
    private var lastQuery: String = ""

    init() {
        loadCached()
    }

    /// Call when company address may have changed. No-op if address unchanged.
    func updateIfNeeded(street: String, city: String) {
        let query = "\(street), \(city)".trimmingCharacters(in: .whitespaces)
        guard query.count > 3, query != lastQuery else { return }
        lastQuery = query

        let cachedKey = UserDefaults.standard.string(forKey: "companyGeoQuery") ?? ""
        if cachedKey == query, coordinate != nil { return }

        geocoder.geocodeAddressString(query) { [weak self] placemarks, _ in
            guard let self = self,
                  let loc = placemarks?.first?.location?.coordinate else { return }
            Task { @MainActor in
                self.coordinate = loc
                UserDefaults.standard.set(query, forKey: "companyGeoQuery")
                UserDefaults.standard.set(loc.latitude,  forKey: "companyGeoLat")
                UserDefaults.standard.set(loc.longitude, forKey: "companyGeoLon")
            }
        }
    }

    private func loadCached() {
        let lat = UserDefaults.standard.double(forKey: "companyGeoLat")
        let lon = UserDefaults.standard.double(forKey: "companyGeoLon")
        lastQuery = UserDefaults.standard.string(forKey: "companyGeoQuery") ?? ""
        if lat != 0, lon != 0 {
            coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
    }
}
