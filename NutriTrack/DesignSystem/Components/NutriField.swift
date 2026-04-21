import SwiftUI

// MARK: - NutriField
// Composant unique pour tous les champs de saisie NutriTrack.
// Remplace : TextField, SecureField, TextEditor natifs.

enum NutriFieldVariant {
    case text
    case secure
    case multiline(minLines: Int = 3, maxLines: Int = 8)
    case number
    case decimal
    case email
}

struct NutriField: View {
    let title: String
    @Binding var text: String
    var variant: NutriFieldVariant = .text
    var placeholder: String = ""
    var suffix: String? = nil
    var prefix: String? = nil
    var error: String? = nil
    var isDisabled: Bool = false

    @FocusState private var isFocused: Bool

    init(
        _ title: String,
        text: Binding<String>,
        variant: NutriFieldVariant = .text,
        placeholder: String = "",
        suffix: String? = nil,
        prefix: String? = nil,
        error: String? = nil,
        isDisabled: Bool = false
    ) {
        self.title = title
        self._text = text
        self.variant = variant
        self.placeholder = placeholder
        self.suffix = suffix
        self.prefix = prefix
        self.error = error
        self.isDisabled = isDisabled
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if !title.isEmpty {
                Text(title)
                    .font(.nutriCaption)
                    .foregroundStyle(Color.nutriTextSecondary)
            }

            fieldContent
                .nutriFieldStyle(
                    isFocused: isFocused,
                    hasError: error != nil,
                    isDisabled: isDisabled
                )

            if let err = error {
                Text(err)
                    .font(.nutriCaption2)
                    .foregroundStyle(Color.nutriError)
                    .padding(.horizontal, Spacing.xs)
            }
        }
    }

    @ViewBuilder
    private var fieldContent: some View {
        HStack(spacing: Spacing.sm) {
            if let prefix {
                Text(prefix)
                    .font(.nutriBody)
                    .foregroundStyle(Color.nutriTextSecondary)
            }

            innerField

            if let suffix {
                Text(suffix)
                    .font(.nutriCaption)
                    .foregroundStyle(Color.nutriTextSecondary)
            }
        }
    }

    @ViewBuilder
    private var innerField: some View {
        switch variant {
        case .text:
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.nutriBody)
                .focused($isFocused)
                .disabled(isDisabled)
                #if os(iOS)
                .autocorrectionDisabled(false)
                #endif

        case .secure:
            SecureField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.nutriBody)
                .focused($isFocused)
                .disabled(isDisabled)

        case .multiline(let minLines, let maxLines):
            TextEditor(text: $text)
                .font(.nutriBody)
                .scrollContentBackground(.hidden)
                .frame(
                    minHeight: CGFloat(minLines) * 22,
                    maxHeight: CGFloat(maxLines) * 22
                )
                .focused($isFocused)
                .disabled(isDisabled)

        case .number:
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.nutriMonoBody)
                .focused($isFocused)
                .disabled(isDisabled)
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif

        case .decimal:
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.nutriMonoBody)
                .focused($isFocused)
                .disabled(isDisabled)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif

        case .email:
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.nutriBody)
                .focused($isFocused)
                .disabled(isDisabled)
                #if os(iOS)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                #endif
        }
    }
}

#Preview("NutriField variants") {
    VStack(spacing: Spacing.md) {
        NutriField("Nom", text: .constant(""), placeholder: "Prénom")
        NutriField("Email", text: .constant(""), variant: .email, placeholder: "vous@exemple.com")
        NutriField("Mot de passe", text: .constant(""), variant: .secure)
        NutriField("Poids", text: .constant("72.5"), variant: .decimal, suffix: "kg")
        NutriField("Calories", text: .constant("2200"), variant: .number, suffix: "kcal")
        NutriField("Notes", text: .constant(""), variant: .multiline())
        NutriField("Email", text: .constant("invalide"), variant: .email, error: "Format invalide")
    }
    .padding(Spacing.lg)
    .frame(width: 400)
}
