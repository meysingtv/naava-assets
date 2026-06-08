import SwiftUI
import MapKit

struct MapCard: View {
    let appointments: [Appointment]

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 48.1440, longitude: 11.5250),
        span: MKCoordinateSpan(latitudeDelta: 0.10, longitudeDelta: 0.10)
    )

    var body: some View {
        VStack(spacing: 0) {
            mapLayer
                .frame(height: 190)
                .cornerRadius(16, corners: [.topLeft, .topRight])

            routeButton
                .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
        }
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 3)
    }

    // MARK: - Subviews

    private var mapLayer: some View {
        Map(coordinateRegion: $region, annotationItems: appointments) { appt in
            MapAnnotation(coordinate: appt.coordinate) {
                MapPinView(status: appt.status)
            }
        }
        .allowsHitTesting(false)
        .overlay(alignment: .topTrailing) {
            weatherBadge
        }
    }

    private var weatherBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 12))
                .foregroundColor(.appOrange)
            Text("22°  Kein Regen")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.appTextPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .padding(10)
    }

    private var routeButton: some View {
        Button(action: {}) {
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
}

private struct MapPinView: View {
    let status: AppointmentStatus

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(status.color)
                    .frame(width: 30, height: 30)
                    .shadow(color: status.color.opacity(0.5), radius: 4, x: 0, y: 2)
                Image(systemName: status.icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            Triangle()
                .fill(status.color)
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
}
