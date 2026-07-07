import SwiftUI

// MARK: - Colors
extension Color {
    static let appBlue      = Color(red: 0.18, green: 0.44, blue: 0.91)
    static let appGreen     = Color(red: 0.18, green: 0.76, blue: 0.51)
    static let appOrange    = Color(red: 1.00, green: 0.62, blue: 0.18)
    static let appPurple    = Color(red: 0.55, green: 0.35, blue: 0.95)
    static let appBackground     = Color(red: 0.96, green: 0.96, blue: 0.98)
    static let appTextPrimary    = Color(red: 0.10, green: 0.10, blue: 0.15)
    static let appTextSecondary  = Color(red: 0.50, green: 0.50, blue: 0.55)
}

// MARK: - Corner radius helper
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// MARK: - Card style
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 3)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
