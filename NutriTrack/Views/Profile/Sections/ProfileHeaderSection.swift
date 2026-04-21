import SwiftUI

/// Section "Informations personnelles" — avatar, prénom, date de naissance, sexe, taille, objectif poids.
/// Reçoit des @Binding depuis le ProfileView parent qui détient les @State et la logique de sauvegarde.
struct ProfileHeaderSection: View {
    @Binding var prenom: String
    @Binding var dateNaissance: Date
    @Binding var sexe: String
    @Binding var taille: Double
    @Binding var objectifPoids: Double

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label("Informations personnelles", systemImage: "person.fill")
                    .font(.nutriHeadline)
                    .foregroundStyle(Color.blue)
                Divider()

                // ── Avatar + Prénom ───────────────────────────────────────────
                HStack(spacing: Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.12))
                            .frame(width: 54, height: 54)
                        Circle()
                            .strokeBorder(Color.blue.opacity(0.25), lineWidth: 1.5)
                            .frame(width: 54, height: 54)
                        Text(prenom.prefix(1).uppercased().isEmpty
                             ? "?" : String(prenom.prefix(1).uppercased()))
                            .font(.nutriTitle2)
                            .foregroundStyle(.blue)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Prénom")
                            .font(.nutriCaption2)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        TextField("Votre prénom", text: $prenom)
                            .font(.nutriHeadline)
                            .textFieldStyle(.plain)
                    }
                }
                .padding(.vertical, Spacing.xs)

                Divider()

                // ── Date de naissance ─────────────────────────────────────────
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack(spacing: 6) {
                        Image(systemName: "birthday.cake.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text("Date de naissance")
                            .font(.nutriBody)
                        Spacer()
                        Text("\(dateNaissance.age) ans")
                            .font(.nutriCaption)
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background { Capsule().fill(Color.blue.opacity(0.1)) }
                    }
                    HStack {
                        DatePicker("", selection: $dateNaissance, displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .tint(.blue)
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 8)
                    .background { RoundedRectangle(cornerRadius: Radius.sm).fill(Color.blue.opacity(0.05)) }
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.sm)
                            .strokeBorder(Color.blue.opacity(0.15), lineWidth: 1)
                    )
                }
                .padding(.vertical, Spacing.xs)

                Divider()

                // ── Sexe — segmented ─────────────────────────────────────────
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Sexe").font(.nutriBody)
                    }
                    Picker("", selection: $sexe) {
                        ForEach(Sexe.allCases, id: \.self) { s in
                            Text(s.label).tag(s.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                .padding(.vertical, Spacing.xs)

                Divider()

                // ── Taille ────────────────────────────────────────────────────
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "ruler.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Taille").font(.nutriBody)
                    }
                    Spacer()
                    Stepper(value: $taille, in: 100...250, step: 0.5) {
                        Text("\(taille.arrondi(0)) cm")
                            .font(.nutriHeadline)
                            .foregroundStyle(.primary)
                    }
                }
                .padding(.vertical, 2)

                Divider()

                // ── Objectif poids ────────────────────────────────────────────
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "scalemass.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Objectif poids").font(.nutriBody)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        TextField("75", value: $objectifPoids,
                                  format: .number.precision(.fractionLength(1)))
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            .font(.nutriHeadline)
                        Text("kg")
                            .font(.nutriCaption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}
