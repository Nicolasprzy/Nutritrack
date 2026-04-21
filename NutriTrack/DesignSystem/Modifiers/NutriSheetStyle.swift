import SwiftUI

// MARK: - NutriSheet
// Wrapper standardisé pour toutes les sheets NutriTrack.
// - macOS : frame selon NutriSheetSize
// - iOS : presentationDetents + dragIndicator
// - Header standardisé : titre + bouton fermer
// - Contenu scrollable obligatoire
// - Footer optionnel fixe

struct NutriSheetContent<Content: View, Footer: View>: View {
    let title: String
    let size: NutriSheetSize
    @Binding var isPresented: Bool
    let content: () -> Content
    let footer: () -> Footer?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
                .overlay(Color.nutriBorder)
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    content()
                }
                .padding(Spacing.lg)
            }
            .frame(maxHeight: .infinity)

            if let footerView = footer() {
                Divider().overlay(Color.nutriBorder)
                HStack {
                    footerView
                }
                .padding(Spacing.md)
                .background(Color.fondPrincipal.opacity(0.95))
            }
        }
        #if os(macOS)
        .frame(
            minWidth: size.width, idealWidth: size.width, maxWidth: size.width * 1.25,
            minHeight: size.height, idealHeight: size.height
        )
        #else
        .presentationDetents(size.detents)
        .presentationDragIndicator(.visible)
        #endif
    }

    private var header: some View {
        HStack {
            Text(title)
                .font(.nutriTitle2)
                .foregroundStyle(Color.nutriTextPrimary)
            Spacer()
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.nutriTextSecondary)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(".", modifiers: .command)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }
}

extension View {
    /// Sheet NutriTrack standardisé avec header, scroll, footer optionnel.
    func nutriSheet<Content: View, Footer: View>(
        title: String,
        size: NutriSheetSize = .standard,
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder footer: @escaping () -> Footer
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            NutriSheetContent(
                title: title,
                size: size,
                isPresented: isPresented,
                content: content,
                footer: { Optional(footer()) }
            )
        }
    }

    /// Overload sans footer
    func nutriSheet<Content: View>(
        title: String,
        size: NutriSheetSize = .standard,
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            NutriSheetContent<Content, EmptyView>(
                title: title,
                size: size,
                isPresented: isPresented,
                content: content,
                footer: { nil }
            )
        }
    }
}
