import SwiftUI

// MARK: - NutriPicker
// Auto-switch : .segmented si ≤3 options, .menu si ≥4.

struct NutriPickerOption<Value: Hashable>: Identifiable {
    let id = UUID()
    let value: Value
    let label: String
    let icon: String?

    init(_ value: Value, label: String, icon: String? = nil) {
        self.value = value
        self.label = label
        self.icon = icon
    }
}

struct NutriPicker<Value: Hashable>: View {
    let title: String
    @Binding var selection: Value
    let options: [NutriPickerOption<Value>]
    var forceStyle: Style? = nil

    enum Style { case segmented, menu }

    init(
        _ title: String,
        selection: Binding<Value>,
        options: [NutriPickerOption<Value>],
        forceStyle: Style? = nil
    ) {
        self.title = title
        self._selection = selection
        self.options = options
        self.forceStyle = forceStyle
    }

    private var effectiveStyle: Style {
        if let forced = forceStyle { return forced }
        return options.count <= 3 ? .segmented : .menu
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if !title.isEmpty {
                Text(title)
                    .font(.nutriCaption)
                    .foregroundStyle(Color.nutriTextSecondary)
            }

            switch effectiveStyle {
            case .segmented:
                segmentedPicker
            case .menu:
                menuPicker
            }
        }
    }

    private var segmentedPicker: some View {
        Picker(title, selection: $selection) {
            ForEach(options) { opt in
                if let icon = opt.icon {
                    Label(opt.label, systemImage: icon).tag(opt.value)
                } else {
                    Text(opt.label).tag(opt.value)
                }
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    private var menuPicker: some View {
        Menu {
            ForEach(options) { opt in
                Button {
                    selection = opt.value
                } label: {
                    if let icon = opt.icon {
                        Label(opt.label, systemImage: icon)
                    } else {
                        Text(opt.label)
                    }
                }
            }
        } label: {
            HStack {
                Text(currentLabel)
                    .font(.nutriBody)
                    .foregroundStyle(Color.nutriTextPrimary)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.nutriTextSecondary)
            }
            .nutriFieldStyle()
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }

    private var currentLabel: String {
        options.first(where: { $0.value == selection })?.label ?? "—"
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        NutriPicker("Sexe", selection: .constant("homme"), options: [
            .init("homme", label: "Homme"),
            .init("femme", label: "Femme")
        ])
        NutriPicker("Approche", selection: .constant("normale"), options: [
            .init("douce", label: "🌱 Douce"),
            .init("normale", label: "⚡️ Normale"),
            .init("agressive", label: "🔥 Agressive"),
            .init("tres_agressive", label: "💥 Très agressive")
        ])
    }
    .padding(Spacing.lg)
    .frame(width: 400)
}
