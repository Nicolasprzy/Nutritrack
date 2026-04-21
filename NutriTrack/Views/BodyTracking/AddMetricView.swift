import SwiftUI
import SwiftData

struct AddMetricView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.activeProfileID) private var activeProfileID
    @Query private var profiles: [UserProfile]

    @State private var viewModel = BodyTrackingViewModel()
    @State private var poids: Double = 75.0
    @State private var poidsTexte: String = "75.0"
    @State private var tourTaille: String = ""
    @State private var tourHanches: String = ""
    @State private var poitrine: String = ""
    @State private var bras: String = ""
    @State private var cuisse: String = ""
    @State private var masseGrasse: String = ""
    @State private var notes: String = ""
    @State private var healthKitService = HealthKitService()

    var profil: UserProfile? { profiles.first(where: { $0.profileID.uuidString == activeProfileID }) }

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
        VStack(alignment: .leading, spacing: Spacing.lg) {

            // ── Poids + IMC ──────────────────────────────────────────────
            VStack(alignment: .leading, spacing: Spacing.sm) {
                NutriSectionHeader("Poids", icon: "scalemass.fill")

                NutriField("Poids actuel",
                           text: $poidsTexte,
                           variant: .decimal,
                           placeholder: "75.0",
                           suffix: "kg")
                    .onChange(of: poidsTexte) { _, nouveau in
                        if let v = Double(nouveau.replacingOccurrences(of: ",", with: ".")) {
                            poids = v
                        }
                    }

                Slider(value: $poids, in: 30...200, step: 0.5)
                    .tint(.blue)
                    .onChange(of: poids) { _, nouveau in
                        poidsTexte = String(format: "%.1f", nouveau)
                    }

                if imc > 0 {
                    HStack {
                        Text("IMC calculé")
                            .font(.nutriBody)
                        Spacer()
                        Text(imc.arrondi(1))
                            .font(.nutriHeadline).foregroundStyle(imcCouleur)
                        Text("— \(imcCategorie)")
                            .font(.nutriCaption).foregroundStyle(imcCouleur)
                    }
                }
            }

            // ── Mensurations ─────────────────────────────────────────────
            VStack(alignment: .leading, spacing: Spacing.sm) {
                NutriSectionHeader("Mensurations", icon: "ruler.fill")

                NutriField("Tour de taille", text: $tourTaille, variant: .decimal, placeholder: "0", suffix: "cm")
                NutriField("Tour de hanches", text: $tourHanches, variant: .decimal, placeholder: "0", suffix: "cm")
                NutriField("Poitrine", text: $poitrine, variant: .decimal, placeholder: "0", suffix: "cm")
                NutriField("Bras droit", text: $bras, variant: .decimal, placeholder: "0", suffix: "cm")
                NutriField("Cuisse", text: $cuisse, variant: .decimal, placeholder: "0", suffix: "cm")
                NutriField("Masse grasse", text: $masseGrasse, variant: .decimal, placeholder: "0", suffix: "%")
            }

            // ── Notes ────────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: Spacing.sm) {
                NutriSectionHeader("Notes", icon: "note.text")
                NutriField("", text: $notes, variant: .multiline(minLines: 3, maxLines: 5),
                           placeholder: "Ressenti, contexte…")
            }

            // ── Bouton d'action ──────────────────────────────────────────
            NutriButton("Enregistrer",
                        icon: "checkmark.circle.fill",
                        style: .primary,
                        isDisabled: poids <= 0) {
                enregistrer()
            }
            .padding(.top, Spacing.sm)
        }
        .onAppear {
            poids = profil?.poidsActuel ?? 75.0
            poidsTexte = String(format: "%.1f", poids)
        }
    }

    // MARK: - Sauvegarde

    private func enregistrer() {
        viewModel.ajouterMetric(
            poids:       poids,
            bmi:         imc,
            tourTaille:  Self.parse(tourTaille),
            tourHanches: Self.parse(tourHanches),
            poitrine:    Self.parse(poitrine),
            bras:        Self.parse(bras),
            cuisse:      Self.parse(cuisse),
            masseGrasse: Self.parse(masseGrasse),
            notes:       notes,
            profileID:   activeProfileID,
            context:     modelContext
        )
        if let p = profil { p.poidsActuel = poids }
        try? modelContext.save()

        if healthKitService.isAvailable {
            Task {
                _ = await healthKitService.demanderAutorisation()
                _ = await healthKitService.ecrirePoids(poids)
            }
        }
        dismiss()
    }

    private static func parse(_ s: String) -> Double {
        Double(s.replacingOccurrences(of: ",", with: ".")) ?? 0
    }
}

#Preview {
    AddMetricView()
        .modelContainer(for: [BodyMetric.self, UserProfile.self], inMemory: true)
}
