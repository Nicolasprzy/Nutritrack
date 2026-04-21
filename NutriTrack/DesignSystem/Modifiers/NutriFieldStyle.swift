import SwiftUI

// MARK: - NutriField ViewModifier
// Style filled cohérent pour TextField/SecureField/TextEditor.
// Appliqué automatiquement par NutriField — les vues n'y touchent pas.

struct NutriFieldStyleModifier: ViewModifier {
    let isFocused: Bool
    let hasError: Bool
    let isDisabled: Bool

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.sm)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            .opacity(isDisabled ? 0.5 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
            .animation(.easeInOut(duration: 0.15), value: hasError)
    }

    private var backgroundColor: Color {
        if isDisabled { return .nutriSurfaceDisabled }
        if hasError { return .nutriSurfaceError }
        if isFocused { return .nutriSurfaceFocus }
        return .nutriSurface
    }

    private var borderColor: Color {
        if hasError { return .nutriBorderError }
        if isFocused { return .nutriBorderFocus }
        return .clear
    }

    private var borderWidth: CGFloat {
        (isFocused || hasError) ? 1 : 0
    }
}

extension View {
    func nutriFieldStyle(isFocused: Bool = false, hasError: Bool = false, isDisabled: Bool = false) -> some View {
        self.modifier(NutriFieldStyleModifier(
            isFocused: isFocused,
            hasError: hasError,
            isDisabled: isDisabled
        ))
    }
}
