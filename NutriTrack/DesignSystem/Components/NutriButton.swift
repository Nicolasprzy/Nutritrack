import SwiftUI

// MARK: - NutriButton

enum NutriButtonStyle {
    case primary
    case secondary
    case tertiary
    case destructive
}

enum NutriButtonSize {
    case small
    case regular
    case large

    var height: CGFloat {
        switch self {
        case .small: return NutriLayout.buttonSmall
        case .regular: return NutriLayout.buttonRegular
        case .large: return NutriLayout.buttonLarge
        }
    }

    var font: Font {
        switch self {
        case .small: return .nutriCaption
        case .regular: return .nutriBody
        case .large: return .nutriBodyBold
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .small: return Spacing.sm
        case .regular: return Spacing.md
        case .large: return Spacing.lg
        }
    }
}

struct NutriButton: View {
    let title: String
    var icon: String? = nil
    var style: NutriButtonStyle = .primary
    var size: NutriButtonSize = .regular
    var loading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    @State private var isPressed = false

    init(
        _ title: String,
        icon: String? = nil,
        style: NutriButtonStyle = .primary,
        size: NutriButtonSize = .regular,
        loading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.loading = loading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: {
            guard !loading && !isDisabled else { return }
            action()
        }) {
            HStack(spacing: Spacing.xs) {
                if loading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(foregroundColor)
                } else if let icon {
                    Image(systemName: icon)
                        .font(size.font)
                }
                Text(title)
                    .font(size.font)
            }
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .foregroundStyle(foregroundColor)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .opacity((isDisabled || loading) ? 0.5 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || loading)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .nutriGreen
        case .tertiary: return .nutriTextPrimary
        case .destructive: return .red
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return .nutriGreen
        case .secondary: return Color.nutriGreen.opacity(0.15)
        case .tertiary: return .clear
        case .destructive: return Color.red.opacity(0.15)
        }
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        NutriButton("Enregistrer", style: .primary) {}
        NutriButton("Annuler", style: .secondary) {}
        NutriButton("Plus tard", style: .tertiary) {}
        NutriButton("Supprimer", icon: "trash.fill", style: .destructive) {}
        NutriButton("Chargement…", loading: true) {}
        NutriButton("Désactivé", isDisabled: true) {}
    }
    .padding(Spacing.lg)
}
