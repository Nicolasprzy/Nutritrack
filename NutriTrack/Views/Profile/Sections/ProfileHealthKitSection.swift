import SwiftUI
import SwiftData

/// Section "Santé" — toggle HealthKit, import des données de poids.
struct ProfileHealthKitSection: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var healthKitActif: Bool
    @State private var healthKitService = HealthKitService()

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label("Santé", systemImage: "heart.fill")
                    .font(.nutriHeadline)
                    .foregroundStyle(Color.red)
                Divider()

                ProfileRowHelper.row("Synchroniser avec HealthKit") {
                    Toggle("", isOn: $healthKitActif)
                        .labelsHidden()
                        .onChange(of: healthKitActif) { _, actif in
                            if actif { Task { await healthKitService.demanderAutorisation() } }
                        }
                }

                if healthKitActif && healthKitService.isAuthorized {
                    Divider()
                    Button(action: {
                        Task { await healthKitService.importerPoidsDansSwiftData(context: modelContext) }
                    }) {
                        Label("Importer mes données de poids", systemImage: "arrow.down.circle")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                }

                if !healthKitService.isAvailable {
                    Divider()
                    Text("HealthKit non disponible sur cet appareil")
                        .font(.nutriCaption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
