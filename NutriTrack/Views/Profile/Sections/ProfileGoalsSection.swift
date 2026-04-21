import SwiftUI

/// Section "Corps & Silhouette" — silhouette actuelle/objectif, date objectif, réévaluation, approche.
struct ProfileGoalsSection: View {
    @Binding var sexe: String
    @Binding var silhouetteActuelle: String
    @Binding var silhouetteObjectif: String
    @Binding var dateObjectif: Date
    @Binding var frequenceReevaluation: Int
    @Binding var approcheTransformation: String

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label("Corps & Silhouette", systemImage: "figure.arms.open")
                    .font(.nutriHeadline)
                    .foregroundStyle(Color.teal)
                Divider()

                // Silhouette actuelle
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.fill").foregroundStyle(.secondary).font(.caption)
                        Text("Silhouette actuelle").font(.nutriBody)
                    }
                    SilhouettePicker(
                        sexe: Sexe(rawValue: sexe) ?? .homme,
                        selection: $silhouetteActuelle
                    )
                    .frame(height: 130)
                }

                Divider()

                // Silhouette objectif
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: 6) {
                        Image(systemName: "target").foregroundStyle(Color.nutriGreen).font(.caption)
                        Text("Silhouette objectif").font(.nutriBody)
                    }
                    SilhouettePicker(
                        sexe: Sexe(rawValue: sexe) ?? .homme,
                        selection: $silhouetteObjectif
                    )
                    .frame(height: 130)
                }

                Divider()
                ProfileRowHelper.row("Date objectif") {
                    DatePicker("", selection: $dateObjectif, in: Date()..., displayedComponents: .date)
                        .labelsHidden()
                }
                Divider()
                ProfileRowHelper.row("Réévaluation") {
                    Stepper("\(frequenceReevaluation) jours", value: $frequenceReevaluation, in: 7...60, step: 7)
                }
                Divider()
                ProfileRowHelper.row("Approche") {
                    Picker("", selection: $approcheTransformation) {
                        ForEach(ApprocheTransformation.allCases, id: \.self) { a in
                            Text("\(a.emoji) \(a.label)").tag(a.rawValue)
                        }
                    }
                    .labelsHidden().frame(width: 200)
                }
            }
        }
    }
}

/// Helper partagé pour les lignes de type "label + contrôle à droite" dans les sections Profile.
enum ProfileRowHelper {
    static func row<Content: View>(_ label: String, @ViewBuilder trailing: () -> Content) -> some View {
        HStack(alignment: .center) {
            Text(label)
                .font(.nutriBody)
                .foregroundStyle(.primary)
            Spacer()
            trailing()
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
