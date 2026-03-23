import SwiftUI

/// Carte verre dépoli — design macOS Tahoe
struct GlassCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = Spacing.md
    var cornerRadius: CGFloat = Radius.lg

    init(
        padding: CGFloat = Spacing.md,
        cornerRadius: CGFloat = Radius.lg,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
}

#Preview {
    GlassCard {
        VStack(alignment: .leading, spacing: 8) {
            Text("Exemple de carte").font(.headline)
            Text("Contenu en verre dépoli").font(.subheadline).foregroundStyle(.secondary)
        }
    }
    .padding()
}
