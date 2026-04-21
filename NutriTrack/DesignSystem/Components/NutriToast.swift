import SwiftUI

// MARK: - NutriToast

enum NutriToastType {
    case success, error, info, warning

    var color: Color {
        switch self {
        case .success: return .nutriSuccess
        case .error: return .nutriError
        case .info: return .nutriInfo
        case .warning: return .nutriWarning
        }
    }

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
}

struct NutriToastMessage: Equatable {
    let type: NutriToastType
    let text: String

    static func == (lhs: NutriToastMessage, rhs: NutriToastMessage) -> Bool {
        lhs.type == rhs.type && lhs.text == rhs.text
    }
}

struct NutriToastModifier: ViewModifier {
    @Binding var message: NutriToastMessage?
    var duration: Double = 2.0

    func body(content: Content) -> some View {
        ZStack {
            content
            if let msg = message {
                VStack {
                    Spacer()
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: msg.type.icon)
                            .foregroundStyle(.white)
                        Text(msg.text)
                            .font(.nutriBodyBold)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(msg.type.color)
                    .clipShape(Capsule())
                    .nutriShadow(.medium)
                    .padding(.bottom, Spacing.xl)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .task(id: msg) {
                    try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                    withAnimation { message = nil }
                }
            }
        }
        .animation(.spring(duration: 0.3), value: message)
    }
}

extension View {
    func nutriToast(message: Binding<NutriToastMessage?>, duration: Double = 2.0) -> some View {
        self.modifier(NutriToastModifier(message: message, duration: duration))
    }
}
