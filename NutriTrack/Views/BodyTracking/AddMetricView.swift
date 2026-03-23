import SwiftUI
import SwiftData

struct AddMetricView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    @State private var viewModel = BodyTrackingViewModel()
    @State private var poids: Double = 75.0
    @State private var tourTaille: Double = 0
    @State private var tourHanches: Double = 0
    @State private var masseGrasse: Double = 0
    @State private var notes: String = ""
    @State private var healthKitService = HealthKitService()

    var profil: UserProfile? { profiles.first }

    private var imc: Double {
        guard let p = profil, p.taille > 0, poids > 0 else { return 0 }
        return NutritionCalculator.imc(poids: poids, taille: p.taille)
    }

    private var imcCategorie: String {
        switch imc {
        case ..<18.5: return "Insuffisance pondérale"
        case 18.5..<25: return "Normal"
        case 25..<30: return "Surpoids"
        default: return "Obésité"
        }
    }

    private var imcCouleur: Color {
        switch imc {
        case ..<18.5: return .blue
        case 18.5..<25: return .nutriGreen
        case 25..<30: return .orange
        default: return .red
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Titre
            HStack {
                Text("Nouvelle mesure")
                    .font(.nutriTitle2)
                    .padding(.leading, Spacing.lg)
                Spacer()
                Button("Annuler") { dismiss() }
                    .padding(.trailing, Spacing.lg)
            }
            .padding(.vertical, Spacing.md)
            .background(.ultraThinMaterial)

            Divider()

            ScrollView {
                VStack(spacing: Spacing.md) {

                    // Poids
                    GlassCard {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Label("Poids", systemImage: "scalemass.fill")
                                .font(.nutriHeadline)
                                .foregroundStyle(.blue)

                            Divider()

                            HStack {
                                Text("Poids actuel")
                                Spacer()
                                TextField("75.0", value: $poids,
                                          format: .number.precision(.fractionLength(1)))
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 70)
                                Text("kg").foregroundStyle(.secondary)
                            }

                            Slider(value: $poids, in: 30...200, step: 0.5)
                                .tint(.blue)

                            if imc > 0 {
                                Divider()
                                HStack {
                                    Text("IMC calculé")
                                    Spacer()
                                    Text(imc.arrondi(1))
                                        .font(.nutriHeadline)
                                        .foregroundStyle(imcCouleur)
                                    Text("— \(imcCategorie)")
                                        .font(.nutriCaption)
                                        .foregroundStyle(imcCouleur)
                                }
                            }
                        }
                    }

                    // Mensurations
                    GlassCard {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Label("Mensurations", systemImage: "ruler.fill")
                                .font(.nutriHeadline)
                                .foregroundStyle(.purple)

                            Divider()

                            mensurationLigne("Tour de taille", value: $tourTaille, unite: "cm")
                            Divider()
                            mensurationLigne("Tour de hanches", value: $tourHanches, unite: "cm")
                            Divider()
                            mensurationLigne("Masse grasse", value: $masseGrasse, unite: "%")
                        }
                    }

                    // Notes
                    GlassCard {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Label("Notes", systemImage: "note.text")
                                .font(.nutriHeadline)
                                .foregroundStyle(.gray)

                            Divider()

                            TextEditor(text: $notes)
                                .frame(minHeight: 60, maxHeight: 100)
                                .font(.nutriBody)
                        }
                    }
                }
                .padding(Spacing.lg)
            }

            Divider()

            // Bouton Enregistrer
            HStack(spacing: Spacing.md) {
                Spacer()
                Button(action: enregistrer) {
                    Text("Enregistrer")
                        .font(.nutriHeadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            poids > 0 ? Color.nutriGreen : Color.gray,
                            in: RoundedRectangle(cornerRadius: Radius.md)
                        )
                }
                .buttonStyle(.plain)
                .disabled(poids <= 0)
            }
            .padding(Spacing.lg)
            .background(.ultraThinMaterial)
        }
        .frame(minWidth: 440, idealWidth: 500, minHeight: 500)
    }

    private func mensurationLigne(_ label: String, value: Binding<Double>, unite: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", value: value, format: .number.precision(.fractionLength(1)))
                .multilineTextAlignment(.trailing)
                .frame(width: 70)
            Text(unite).foregroundStyle(.secondary).frame(width: 28, alignment: .leading)
        }
    }

    private func enregistrer() {
        viewModel.ajouterMetric(
            poids: poids,
            bmi: imc,
            tourTaille: tourTaille,
            tourHanches: tourHanches,
            masseGrasse: masseGrasse,
            notes: notes,
            context: modelContext
        )
        if healthKitService.isAvailable {
            Task {
                _ = await healthKitService.demanderAutorisation()
                _ = await healthKitService.ecrirePoids(poids)
            }
        }
        dismiss()
    }
}

#Preview {
    AddMetricView()
        .modelContainer(for: [BodyMetric.self, UserProfile.self], inMemory: true)
}
