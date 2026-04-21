import SwiftUI

struct QuickLogSection: View {
    let templates: [MealTemplate]
    let onLog: (MealTemplate) -> Void

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label("Repas rapide", systemImage: "bolt.fill")
                    .font(.nutriHeadline)
                    .foregroundStyle(Color.orange)

                if templates.isEmpty {
                    Text("Aucun template pour ce moment de la journée")
                        .font(.nutriCaption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, Spacing.sm)
                } else {
                    ForEach(templates) { tpl in
                        templateRow(tpl)
                        if tpl.id != templates.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private func templateRow(_ tpl: MealTemplate) -> some View {
        Button {
            onLog(tpl)
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Color.nutriGreen)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(tpl.name)
                        .font(.nutriBodyBold)
                        .foregroundStyle(Color.nutriTextPrimary)
                    Text(macroSummary(for: tpl))
                        .font(.nutriCaption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .font(.nutriCaption)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, Spacing.xs)
    }

    private func macroSummary(for tpl: MealTemplate) -> String {
        let items = tpl.items ?? []
        let totalP = items.reduce(0.0) { $0 + $1.proteinG }
        let totalKcal = items.reduce(0) { $0 + $1.kcal }
        return "\(Int(totalP.rounded()))g P · \(totalKcal) kcal"
    }
}
