import SwiftUI

struct ProgrammeCompletSheet: View {
    let plan: UserPlan
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {

                    // Critique IA
                    if !plan.critiqueIA.isEmpty {
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                HStack(spacing: 6) {
                                    Image(systemName: plan.niveauFaisabiliteEnum.icon)
                                        .foregroundStyle(plan.niveauFaisabiliteEnum.couleur)
                                    Text(plan.niveauFaisabiliteEnum.label)
                                        .font(.nutriHeadline)
                                        .foregroundStyle(plan.niveauFaisabiliteEnum.couleur)
                                }
                                Text(plan.critiqueIA)
                                    .font(.nutriCaption).foregroundStyle(.secondary)

                                if !plan.alternativeSuggeree.isEmpty {
                                    Divider()
                                    Text(plan.alternativeSuggeree)
                                        .font(.nutriCaption).foregroundStyle(.orange)
                                }
                            }
                        }
                    }

                    // Programme semaine
                    if let entrainement = plan.planEntrainement {
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                Label("Programme de la semaine", systemImage: "calendar")
                                    .font(.nutriHeadline).foregroundStyle(.red)

                                if !entrainement.noteGenerale.isEmpty {
                                    Text(entrainement.noteGenerale)
                                        .font(.nutriCaption).foregroundStyle(.secondary)
                                    Divider()
                                }

                                ForEach(entrainement.semaineType) { jour in
                                    jourRow(jour)
                                    if jour.id != entrainement.semaineType.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }

                        // Recommandations entraînement
                        if !entrainement.recommandations.isEmpty {
                            GlassCard {
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    Label("Conseils entraînement", systemImage: "lightbulb.fill")
                                        .font(.nutriHeadline).foregroundStyle(.red)
                                    ForEach(entrainement.recommandations, id: \.self) { conseil in
                                        HStack(alignment: .top, spacing: 6) {
                                            Text("•").foregroundStyle(.red)
                                            Text(conseil).font(.nutriCaption).foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Recommandations de vie
                    if !plan.recommandationsVie.isEmpty {
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Label("Habitudes de vie", systemImage: "moon.stars.fill")
                                    .font(.nutriHeadline).foregroundStyle(.indigo)
                                Text(plan.recommandationsVie)
                                    .font(.nutriCaption).foregroundStyle(.secondary)
                            }
                        }
                    }

                    Text("Plan généré le \(plan.dateCreation.formatMedium)")
                        .font(.system(size: 10)).foregroundStyle(.secondary)
                        .padding(.bottom, Spacing.md)
                }
                .padding(Spacing.md)
            }
            .navigationTitle("Mon programme")
            .background(Color.fondPrincipal)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 520, minHeight: 600)
        #endif
    }

    private func jourRow(_ jour: JourEntrainement) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: jour.estJourRepos ? "moon.fill" : jour.iconeSeance)
                    .foregroundStyle(jour.estJourRepos ? .indigo : .red)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 1) {
                    Text(jour.jourLabel).font(.nutriHeadline)
                    if !jour.estJourRepos {
                        Text("\(jour.typeSeance) · \(jour.dureeMinutes) min")
                            .font(.nutriCaption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if jour.seanceFaite {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.nutriGreen)
                } else if jour.estJourRepos {
                    Text("Repos").font(.nutriCaption).foregroundStyle(.secondary)
                }
            }

            if !jour.estJourRepos {
                ForEach(jour.exercices) { ex in
                    exerciceRow(ex)
                }
            }
        }
    }

    private func exerciceRow(_ ex: ExercicePlan) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(ex.nom).font(.nutriBody)
                HStack(spacing: 4) {
                    ForEach(ex.musclesCibles.prefix(3), id: \.self) { muscle in
                        Text(muscle)
                            .font(.system(size: 9))
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color.red.opacity(0.12), in: Capsule())
                            .foregroundStyle(.red)
                    }
                }
                if let notes = ex.notes, !notes.isEmpty {
                    Text(notes).font(.system(size: 10)).foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text("\(ex.series) séries × \(ex.repetitions)")
                    .font(.nutriCaption)
                Text("Repos : \(ex.reposSecondes)s")
                    .font(.system(size: 10)).foregroundStyle(.secondary)
            }
        }
        .padding(.leading, 28)
    }
}
