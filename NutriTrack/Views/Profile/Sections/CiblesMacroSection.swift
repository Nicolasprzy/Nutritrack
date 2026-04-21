import SwiftUI
import SwiftData

struct CiblesMacroSection: View {
    let profileID: String
    @Environment(\.modelContext) private var modelContext

    @Query private var allTargets: [MacroTarget]
    @State private var editingTarget: MacroTarget?

    private var targetsForProfile: [MacroTarget] {
        allTargets
            .filter { $0.profileID == profileID }
            .sorted { lhs, rhs in
                let order: [String: Int] = [
                    "muscle": 0, "rest": 1, "trailLong": 2, "trailVeryLong": 3
                ]
                return (order[lhs.dayType] ?? 99) < (order[rhs.dayType] ?? 99)
            }
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label("Cibles macro par type de jour", systemImage: "chart.bar.doc.horizontal")
                    .font(.nutriHeadline)
                    .foregroundStyle(Color.nutriGreen)

                if targetsForProfile.isEmpty {
                    Text("Aucune cible définie. Initialise le plan nutrition ci-dessous.")
                        .font(.nutriCaption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(targetsForProfile) { target in
                        targetRow(target)
                        if target.id != targetsForProfile.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .nutriSheet(
            title: "Modifier la cible",
            size: .compact,
            isPresented: Binding(
                get: { editingTarget != nil },
                set: { if !$0 { editingTarget = nil } }
            )
        ) {
            if let t = editingTarget {
                MacroTargetEditView(target: t)
            }
        }
    }

    private func targetRow(_ target: MacroTarget) -> some View {
        let label = DayType(rawValue: target.dayType)?.displayName ?? target.dayType
        return Button {
            editingTarget = target
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.nutriBodyBold)
                        .foregroundStyle(Color.nutriTextPrimary)
                    Text("\(target.targetKcal) kcal · \(target.targetProteinG)g P · \(target.targetCarbsG)g G · \(target.targetFatG)g L")
                        .font(.nutriCaption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .font(.nutriCaption)
            }
            .contentShape(Rectangle())
            .padding(.vertical, Spacing.xs)
        }
        .buttonStyle(.plain)
    }
}
