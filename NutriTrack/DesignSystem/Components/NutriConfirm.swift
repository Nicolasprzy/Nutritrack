import SwiftUI

// MARK: - NutriConfirm
// Remplace .confirmationDialog avec layout contrôlé.

struct NutriConfirmModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let destructive: Bool
    let confirmLabel: String
    let cancelLabel: String
    let onConfirm: () -> Void

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            VStack(spacing: Spacing.lg) {
                VStack(spacing: Spacing.sm) {
                    Image(systemName: destructive ? "exclamationmark.triangle.fill" : "questionmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(destructive ? Color.red : Color.nutriGreen)
                        .symbolRenderingMode(.hierarchical)

                    Text(title)
                        .font(.nutriTitle3)
                        .multilineTextAlignment(.center)

                    if !message.isEmpty {
                        Text(message)
                            .font(.nutriBody)
                            .foregroundStyle(Color.nutriTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, Spacing.lg)

                HStack(spacing: Spacing.md) {
                    NutriButton(cancelLabel, style: .secondary) {
                        isPresented = false
                    }
                    NutriButton(
                        confirmLabel,
                        style: destructive ? .destructive : .primary
                    ) {
                        isPresented = false
                        onConfirm()
                    }
                }
            }
            .padding(Spacing.lg)
            #if os(macOS)
            .frame(width: 420)
            #else
            .presentationDetents([.fraction(0.35)])
            #endif
        }
    }
}

extension View {
    func nutriConfirm(
        title: String,
        message: String = "",
        destructive: Bool = false,
        confirmLabel: String = "Confirmer",
        cancelLabel: String = "Annuler",
        isPresented: Binding<Bool>,
        onConfirm: @escaping () -> Void
    ) -> some View {
        self.modifier(NutriConfirmModifier(
            isPresented: isPresented,
            title: title,
            message: message,
            destructive: destructive,
            confirmLabel: confirmLabel,
            cancelLabel: cancelLabel,
            onConfirm: onConfirm
        ))
    }
}
