import SwiftUI

struct PlaceholderView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 52))
                .foregroundColor(.appTextSecondary.opacity(0.3))
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.appTextSecondary)
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(.appTextSecondary.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}
