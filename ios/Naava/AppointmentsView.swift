import SwiftUI

struct AppointmentsView: View {
    var body: some View {
        PlaceholderView(
            icon: "briefcase.fill",
            title: "Aufträge",
            subtitle: "Kommt bald"
        )
        .navigationTitle("Aufträge")
        .toolbar(.hidden, for: .tabBar)
    }
}
