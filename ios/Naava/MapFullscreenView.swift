import SwiftUI
import MapKit

// MARK: - Map Item Model

struct MapItem: Identifiable {
    let id = UUID()
    let title: String
    let customer: String
    let address: String
    let status: AppointmentStatus
    let coordinate: CLLocationCoordinate2D

    static let all: [MapItem] = [
        MapItem(title: "Dachsanierung",      customer: "Familie Müller",   address: "Hauptstr. 12, Mönchengladbach",         status: .inProgress, coordinate: CLLocationCoordinate2D(latitude: 51.1963, longitude: 6.4428)),
        MapItem(title: "Dachrinne erneuern", customer: "Fa. Schmidt GmbH", address: "Industriestr. 45, MG-Rheydt",           status: .planned,    coordinate: CLLocationCoordinate2D(latitude: 51.1695, longitude: 6.4424)),
        MapItem(title: "Angebot vor Ort",    customer: "Bauer, Thomas",    address: "Gartenweg 3, MG-Wickrath",              status: .open,       coordinate: CLLocationCoordinate2D(latitude: 51.1428, longitude: 6.4082)),
        MapItem(title: "Neueindeckung Anbau",customer: "Claudia Weber",    address: "Rosenstr. 7, Mönchengladbach",          status: .open,       coordinate: CLLocationCoordinate2D(latitude: 51.1578, longitude: 6.4011)),
        MapItem(title: "Gaubenanbau",        customer: "Maier & Söhne",    address: "Bergweg 22, MG-Neuwerk",                status: .planned,    coordinate: CLLocationCoordinate2D(latitude: 51.2189, longitude: 6.4189)),
    ]
}

// MARK: - MKMapView Wrapper (for mapType support)

private struct NaavaMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var mapType: MKMapType
    var items: [MapItem]
    var selectedItem: MapItem?
    var onSelect: (MapItem?) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let mv = MKMapView()
        mv.delegate = context.coordinator
        mv.showsUserLocation = true
        mv.setRegion(region, animated: false)
        mv.mapType = mapType
        return mv
    }

    func updateUIView(_ mv: MKMapView, context: Context) {
        mv.mapType = mapType

        // Sync region only when centre drifts meaningfully
        let cur = mv.region
        let dLat = abs(cur.center.latitude  - region.center.latitude)
        let dLon = abs(cur.center.longitude - region.center.longitude)
        if dLat > 0.001 || dLon > 0.001 {
            mv.setRegion(region, animated: true)
        }

        // Rebuild annotations when items change
        let existing = mv.annotations.compactMap { $0 as? MapPin }
        let existingIds = Set(existing.map { $0.item.id })
        let newIds = Set(items.map { $0.id })

        if existingIds != newIds {
            mv.removeAnnotations(mv.annotations)
            mv.addAnnotations(items.map { MapPin(item: $0) })
        }

        // Selection state
        for ann in mv.annotations {
            if let pin = ann as? MapPin,
               let view = mv.view(for: pin) as? MKMarkerAnnotationView {
                let sel = selectedItem?.id == pin.item.id
                view.markerTintColor = UIColor(pin.item.status.color)
                view.transform = sel ? CGAffineTransform(scaleX: 1.25, y: 1.25) : .identity
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: NaavaMapView
        init(_ p: NaavaMapView) { parent = p }

        func mapView(_ mv: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let pin = annotation as? MapPin else { return nil }
            let id = "naava-pin"
            let view = mv.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.annotation = annotation
            view.markerTintColor = UIColor(pin.item.status.color)
            view.glyphImage = UIImage(systemName: pin.item.status.icon)
            view.canShowCallout = false
            return view
        }

        func mapView(_ mv: MKMapView, didSelect view: MKAnnotationView) {
            guard let pin = view.annotation as? MapPin else { return }
            mv.deselectAnnotation(view.annotation, animated: false)
            parent.onSelect(pin.item)
        }

        func mapView(_ mv: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.region = mv.region
        }
    }
}

private class MapPin: NSObject, MKAnnotation {
    let item: MapItem
    var coordinate: CLLocationCoordinate2D { item.coordinate }
    var title: String? { item.title }
    init(item: MapItem) { self.item = item }
}

// MARK: - Full Screen Map

struct MapFullscreenView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.1963, longitude: 6.4428),
        span: MKCoordinateSpan(latitudeDelta: 0.13, longitudeDelta: 0.13)
    )
    @State private var selectedItem: MapItem? = nil
    @State private var filter: AppointmentStatus? = nil
    @State private var useHybrid = false

    private var filtered: [MapItem] {
        guard let f = filter else { return MapItem.all }
        return MapItem.all.filter { $0.status == f }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            mapLayer
            overlayControls
            if let item = selectedItem {
                PinDetailCard(item: item,
                    onRoute:   { openAppleMaps(item) },
                    onDismiss: { withAnimation(.spring()) { selectedItem = nil } }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle("Karte")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: centerMap) {
                    Image(systemName: "location.fill")
                        .foregroundColor(.appBlue)
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: - Map

    private var mapLayer: some View {
        NaavaMapView(
            region: $region,
            mapType: useHybrid ? .hybrid : .standard,
            items: filtered,
            selectedItem: selectedItem
        ) { tapped in
            withAnimation(.spring(response: 0.35)) {
                if selectedItem?.id == tapped?.id {
                    selectedItem = nil
                } else {
                    selectedItem = tapped
                    if let t = tapped { centerOn(t) }
                }
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Overlays

    private var overlayControls: some View {
        VStack(spacing: 0) {
            // Filter + map-type bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Map type toggle
                    Button(action: { withAnimation { useHybrid.toggle() } }) {
                        HStack(spacing: 5) {
                            Image(systemName: useHybrid ? "map.fill" : "globe.europe.africa.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text(useHybrid ? "Normal" : "Satellit")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(useHybrid ? .white : .appBlue)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(useHybrid ? Color.appBlue : Color.appBlue.opacity(0.12))
                        .cornerRadius(20)
                    }

                    Divider().frame(height: 20)

                    MapFilterChip(label: "Alle (\(MapItem.all.count))", color: .appTextSecondary, active: filter == nil) {
                        withAnimation { filter = nil }
                    }
                    ForEach(AppointmentStatus.allCases, id: \.self) { s in
                        let count = MapItem.all.filter { $0.status == s }.count
                        MapFilterChip(label: "\(s.rawValue) (\(count))", color: s.color, active: filter == s) {
                            withAnimation { filter = filter == s ? nil : s }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(.ultraThinMaterial)

            Spacer()

            // Legend (bottom left, above detail card)
            if selectedItem == nil {
                legendBadge
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var legendBadge: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(AppointmentStatus.allCases, id: \.self) { s in
                HStack(spacing: 6) {
                    Circle().fill(s.color).frame(width: 8, height: 8)
                    Text(s.rawValue)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(10)
    }

    // MARK: - Helpers

    private func openAppleMaps(_ item: MapItem) {
        let encoded = item.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "maps://?daddr=\(encoded)&dirflg=d") {
            openURL(url)
        }
    }

    private func centerOn(_ item: MapItem) {
        withAnimation(.easeInOut(duration: 0.4)) {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: item.coordinate.latitude - 0.015,
                    longitude: item.coordinate.longitude
                ),
                span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
            )
        }
    }

    private func centerMap() {
        withAnimation(.easeInOut(duration: 0.5)) {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 51.1963, longitude: 6.4428),
                span: MKCoordinateSpan(latitudeDelta: 0.13, longitudeDelta: 0.13)
            )
        }
    }
}

// MARK: - Filter Chip

private struct MapFilterChip: View {
    let label: String
    let color: Color
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(active ? .white : color)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(active ? color : color.opacity(0.12))
                .cornerRadius(20)
        }
    }
}

// MARK: - Pin Detail Card

private struct PinDetailCard: View {
    let item: MapItem
    let onRoute: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 8)

            HStack(alignment: .top, spacing: 14) {
                // Status icon
                ZStack {
                    Circle()
                        .fill(item.status.color.opacity(0.14))
                        .frame(width: 48, height: 48)
                    Image(systemName: item.status.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(item.status.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                    Text(item.customer)
                        .font(.system(size: 14))
                        .foregroundColor(.appTextSecondary)
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.mini.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.appTextSecondary)
                        Text(item.address)
                            .font(.system(size: 12))
                            .foregroundColor(.appTextSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.appTextSecondary.opacity(0.5))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            Divider().padding(.horizontal, 20)

            // Actions
            HStack(spacing: 12) {
                Button(action: onRoute) {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Route starten")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.appBlue)
                    .cornerRadius(12)
                }

                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: "briefcase.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Zum Auftrag")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.appBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.appBlue.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .padding(.bottom, 8)
        }
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(24, corners: [.topLeft, .topRight])
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: -4)
    }
}

#Preview {
    NavigationStack { MapFullscreenView() }
}
