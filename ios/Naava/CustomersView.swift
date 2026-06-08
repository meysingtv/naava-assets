import SwiftUI

struct CustomersView: View {
    var body: some View {
        PlaceholderView(
            icon: "person.2.fill",
            title: "Kunden",
            subtitle: "Kommt bald"
        )
        .navigationTitle("Kunden")
        .toolbar(.hidden, for: .tabBar)
    }
}
