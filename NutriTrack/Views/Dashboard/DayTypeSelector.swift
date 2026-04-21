import SwiftUI

struct DayTypeSelector: View {
    let selected: DayType?
    let onSelect: (DayType) -> Void

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(DayType.allCases) { type in
                pill(for: type)
            }
        }
    }

    private func pill(for type: DayType) -> some View {
        let isSelected = selected == type
        return Button {
            onSelect(type)
        } label: {
            VStack(spacing: 2) {
                Text(type.shortName)
                    .font(.nutriCaption)
                    .fontWeight(isSelected ? .bold : .regular)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(isSelected ? Color.nutriGreen : Color.nutriSurface)
            .foregroundStyle(isSelected ? Color.white : Color.nutriTextPrimary)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        DayTypeSelector(selected: .muscle) { _ in }
        DayTypeSelector(selected: nil) { _ in }
    }
    .padding(Spacing.lg)
    .frame(width: 500)
}
