import SwiftUI
import MapKit

struct MapCard: View {
    let appointments: [Appointment]

    @State private var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.1963, longitude: 6.4428),
        span: MKCoordinateSpan(latitudeDelta: 0.10, longitudeDelta: 0.10)
    ))
    @State private var showFullMap = false
    @StateObject private var weather = WeatherService()
    @StateObject private var hq = CompanyLocationService()
    @EnvironmentObject private var appState: AppState
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 0) {
            mapLayer
                .frame(height: 190)
                .cornerRadius(16, corners: [.topLeft, .topRight])

            routeButton
                .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
        }
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 3)
        .sheet(isPresented: $showFullMap) {
            NavigationStack { MapFullscreenView() }
                .environmentObject(appState)
        }
    }

    // MARK: - Map layer

    private var mapLayer: some View {
        Map(position: $position) {
            if let hqCoord = hq.coordinate {
                Annotation("", coordinate: hqCoord) {
                    CompanyHQPin()
                }
            }
            ForEach(appointments) { appt in
                Annotation("", coordinate: appt.coordinate) {
                    DashboardPin(status: appt.status)
                }
            }
        }
        .allowsHitTesting(false)
        .overlay(alignment: .topTrailing) { weatherBadge }
        .overlay(alignment: .topLeading)  { expandButton }
        .onAppear {
            hq.updateIfNeeded(street: appState.companyStreet, city: appState.companyCity)
        }
        .onChange(of: appState.companyStreet) { _, _ in
            hq.updateIfNeeded(street: appState.companyStreet, city: appState.companyCity)
        }
        .onChange(of: appState.companyCity) { _, _ in
            hq.updateIfNeeded(street: appState.companyStreet, city: appState.companyCity)
        }
    }

    private var weatherBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: weather.conditionIcon)
                .font(.system(size: 12))
                .foregroundColor(weather.iconColor)
            Text(weather.temperature.map { "\($0)°  \(weather.conditionText)" } ?? weather.conditionText)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.appTextPrimary)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .padding(10)
        .onAppear { weather.fetchIfNeeded() }
    }

    private var expandButton: some View {
        Button(action: { showFullMap = true }) {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.appTextPrimary)
                .padding(8)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
        }
        .padding(10)
    }

    // MARK: - Route button

    private var routeButton: some View {
        Button(action: openRoute) {
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.system(size: 13, weight: .semibold))
                Text("Route starten")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Color.appBlue)
        }
    }

    private func openRoute() {
        guard let first = appointments.first else { return }
        let encoded = first.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "maps://?daddr=\(encoded)&dirflg=d") {
            openURL(url)
        }
    }
}

// MARK: - Dashboard Pin (compact)

private struct DashboardPin: View {
    let status: AppointmentStatus

    var body: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(status.color)
                .frame(width: 28, height: 28)
                .overlay(Image(systemName: status.icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white))
                .shadow(color: status.color.opacity(0.5), radius: 4, x: 0, y: 2)
            Triangle()
                .fill(status.color)
                .frame(width: 8, height: 5)
        }
    }
}

// MARK: - Company HQ Pin

private struct CompanyHQPin: View {
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.appBlue)
                    .frame(width: 30, height: 30)
                Circle()
                    .stroke(Color.white, lineWidth: 2.5)
                    .frame(width: 30, height: 30)
                Image(systemName: "house.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
            .shadow(color: Color.appBlue.opacity(0.55), radius: 5, x: 0, y: 2)
            Triangle()
                .fill(Color.appBlue)
                .frame(width: 8, height: 5)
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

#Preview {
    MapCard(appointments: DummyData.appointments)
        .padding()
        .background(Color.appBackground)
        .environmentObject(AppState())
}
