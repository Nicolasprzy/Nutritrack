import SwiftUI
import SwiftData

struct ComparePhotosView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.activeProfileID) private var activeProfileID
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \BodyMetric.date, order: .reverse) private var tousMetrics: [BodyMetric]

    let photoA: ProgressPhoto
    let photoB: ProgressPhoto

    private var photoAvant: ProgressPhoto { photoA.date <= photoB.date ? photoA : photoB }
    private var photoApres: ProgressPhoto { photoA.date <= photoB.date ? photoB : photoA }

    private var metricsProfile: [BodyMetric] {
        tousMetrics.filter { $0.profileID == activeProfileID }
    }

    private func metricProche(de date: Date) -> BodyMetric? {
        metricsProfile.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
    }

    private var jours: Int {
        Calendar.current.dateComponents([.day], from: photoAvant.date, to: photoApres.date).day ?? 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        colonnePhoto(photoAvant, label: "Avant")
                        colonnePhoto(photoApres, label: "Après")
                    }
                    ecartCard
                    if !photoAvant.notes.isEmpty || !photoApres.notes.isEmpty {
                        notesCard
                    }
                }
                .padding(Spacing.md)
            }
            .navigationTitle("Comparer")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .background(Color.fondPrincipal)
        }
    }

    // MARK: - Colonne photo

    private func colonnePhoto(_ photo: ProgressPhoto, label: String) -> some View {
        GlassCard(padding: Spacing.sm) {
            VStack(spacing: Spacing.xs) {
                HStack {
                    Text(label)
                        .font(.nutriHeadline)
                        .foregroundStyle(label == "Avant" ? .orange : Color.nutriGreen)
                    Spacer()
                    Label(photo.angleEnum.label, systemImage: photo.angleEnum.icon)
                        .font(.nutriCaption2)
                        .foregroundStyle(.purple)
                }
                PhotoImage(data: photo.imageData)
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                Text(photo.dateFormatted)
                    .font(.nutriCaption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Écart

    private var ecartCard: some View {
        let mA = metricProche(de: photoAvant.date)
        let mB = metricProche(de: photoApres.date)

        return GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label("Écart entre les 2 dates", systemImage: "calendar.badge.clock")
                    .font(.nutriHeadline)

                HStack(spacing: Spacing.lg) {
                    statEcart(label: "Durée", valeur: "\(jours) j", couleur: .blue)

                    if let mA, let mB, mA.weight > 0, mB.weight > 0 {
                        let diff = mB.weight - mA.weight
                        statEcart(
                            label: "Poids",
                            valeur: (diff > 0 ? "+" : "") + "\(diff.arrondi(1)) kg",
                            couleur: diff < 0 ? Color.nutriSuccess : Color.nutriError
                        )
                    }

                    if let mA, let mB, mA.waist > 0, mB.waist > 0 {
                        let diff = mB.waist - mA.waist
                        statEcart(
                            label: "Tour taille",
                            valeur: (diff > 0 ? "+" : "") + "\(diff.arrondi(1)) cm",
                            couleur: diff < 0 ? Color.nutriSuccess : Color.nutriError
                        )
                    }

                    if let mA, let mB, mA.bodyFatPercentage > 0, mB.bodyFatPercentage > 0 {
                        let diff = mB.bodyFatPercentage - mA.bodyFatPercentage
                        statEcart(
                            label: "MG",
                            valeur: (diff > 0 ? "+" : "") + "\(diff.arrondi(1)) %",
                            couleur: diff < 0 ? Color.nutriSuccess : Color.nutriError
                        )
                    }
                }
            }
        }
    }

    private func statEcart(label: String, valeur: String, couleur: Color) -> some View {
        VStack(spacing: Spacing.xxs) {
            Text(valeur)
                .font(.nutriTitle2)
                .foregroundStyle(couleur)
                .monospacedDigit()
            Text(label)
                .font(.nutriCaption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Notes

    private var notesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label("Notes", systemImage: "note.text")
                    .font(.nutriHeadline)
                if !photoAvant.notes.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Avant").font(.nutriCaption).foregroundStyle(.orange)
                        Text(photoAvant.notes).font(.nutriCaption)
                    }
                }
                if !photoApres.notes.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Après").font(.nutriCaption).foregroundStyle(Color.nutriGreen)
                        Text(photoApres.notes).font(.nutriCaption)
                    }
                }
            }
        }
    }
}
