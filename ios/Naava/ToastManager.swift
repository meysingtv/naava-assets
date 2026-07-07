import SwiftUI

// MARK: - Toast Style

enum ToastStyle {
    case success, error, info, warning

    var color: Color {
        switch self {
        case .success: return .appGreen
        case .error:   return .red
        case .info:    return .appBlue
        case .warning: return .appOrange
        }
    }
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error:   return "xmark.circle.fill"
        case .info:    return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
    var haptic: UINotificationFeedbackGenerator.FeedbackType {
        switch self {
        case .success:          return .success
        case .error:            return .error
        case .info, .warning:   return .warning
        }
    }
}

struct ToastItem: Equatable {
    let id = UUID()
    let message: String
    let style: ToastStyle
    let customIcon: String?
    static func == (l: ToastItem, r: ToastItem) -> Bool { l.id == r.id }
}

// MARK: - Toast Manager

@MainActor
class ToastManager: ObservableObject {
    @Published var current: ToastItem?
    private var dismissTask: Task<Void, Never>?

    func show(_ message: String, style: ToastStyle = .success, icon: String? = nil) {
        dismissTask?.cancel()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.68)) {
            current = ToastItem(message: message, style: style, customIcon: icon)
        }
        UINotificationFeedbackGenerator().notificationOccurred(style.haptic)
        dismissTask = Task {
            try? await Task.sleep(nanoseconds: 3_200_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                current = nil
            }
        }
    }
}

// MARK: - Toast Banner (Dynamic Island style)

struct ToastBanner: View {
    @EnvironmentObject var toast: ToastManager

    var body: some View {
        ZStack {
            if let item = toast.current {
                HStack(spacing: 7) {
                    Image(systemName: item.customIcon ?? item.style.icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(item.style.color)
                    Text(item.message)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.85))
                        .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 6)
                )
                .transition(
                    .asymmetric(
                        insertion: .scale(scale: 0.4, anchor: .top)
                            .combined(with: .opacity)
                            .combined(with: .offset(y: -20)),
                        removal: .scale(scale: 0.4, anchor: .top)
                            .combined(with: .opacity)
                            .combined(with: .offset(y: -20))
                    )
                )
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.68), value: toast.current)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 70)
    }
}
