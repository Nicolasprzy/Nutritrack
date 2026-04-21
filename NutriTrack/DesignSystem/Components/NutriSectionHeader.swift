import SwiftUI

// MARK: - NutriSectionHeader

struct NutriSectionHeader: View {
    let title: String
    var icon: String? = nil
    var trailing: AnyView? = nil

    init(_ title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }

    init<Trailing: View>(_ title: String, icon: String? = nil, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.icon = icon
        self.trailing = AnyView(trailing())
    }

    var body: some View {
        HStack(spacing: Spacing.xs) {
            if let icon {
                Image(systemName: icon)
                    .font(.nutriCaption)
                    .foregroundStyle(Color.nutriTextSecondary)
            }
            Text(title.uppercased())
                .font(.nutriCaption)
                .tracking(0.8)
                .foregroundStyle(Color.nutriTextSecondary)
            Spacer()
            if let trailing {
                trailing
            }
        }
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.xs)
    }
}

#Preview {
    VStack(alignment: .leading) {
        NutriSectionHeader("Informations personnelles", icon: "person.fill")
        NutriSectionHeader("Objectifs") {
            Button("Modifier") {}
        }
    }
    .padding(Spacing.lg)
    .frame(width: 400)
}
