import SwiftUI

// MARK: - NutriDatePicker

struct NutriDatePicker: View {
    let title: String
    @Binding var date: Date
    var style: Style = .inline
    var components: DatePickerComponents = .date
    var range: ClosedRange<Date>? = nil

    enum Style { case inline, calendar }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if !title.isEmpty {
                Text(title)
                    .font(.nutriCaption)
                    .foregroundStyle(Color.nutriTextSecondary)
            }

            styledPicker
                .labelsHidden()
                .modifier(InlineFieldStyleIfNeeded(isInline: style == .inline))
        }
    }

    @ViewBuilder
    private var styledPicker: some View {
        switch style {
        case .inline:
            if let range {
                DatePicker("", selection: $date, in: range, displayedComponents: components)
                    .datePickerStyle(.compact)
            } else {
                DatePicker("", selection: $date, displayedComponents: components)
                    .datePickerStyle(.compact)
            }
        case .calendar:
            if let range {
                DatePicker("", selection: $date, in: range, displayedComponents: components)
                    .datePickerStyle(.graphical)
            } else {
                DatePicker("", selection: $date, displayedComponents: components)
                    .datePickerStyle(.graphical)
            }
        }
    }
}

private struct InlineFieldStyleIfNeeded: ViewModifier {
    let isInline: Bool
    func body(content: Content) -> some View {
        if isInline {
            content.nutriFieldStyle()
        } else {
            content
        }
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        NutriDatePicker(title: "Date", date: .constant(Date()))
        NutriDatePicker(title: "Calendrier", date: .constant(Date()), style: .calendar)
    }
    .padding(Spacing.lg)
    .frame(width: 400)
}
