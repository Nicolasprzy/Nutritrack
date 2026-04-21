import SwiftUI
import SwiftData

@main
struct NutriTrackApp: App {
    let container: ModelContainer

    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("activeProfileID") private var activeProfileID: String = ""
    @AppStorage("exportAutomatiqueActive") private var exportAutoActive: Bool = true

    init() {
        let schema = Schema([
            FoodItem.self,
            FoodEntry.self,
            BodyMetric.self,
            ActivityEntry.self,
            UserProfile.self,
            Exercise.self,
            WellnessScore.self,
            ProgressPhoto.self,
            MacroTarget.self,      // NEW Sprint 1
            DayContext.self,       // NEW Sprint 1
            MealTemplate.self,     // NEW Sprint 1
            MealTemplateItem.self  // NEW Sprint 1
        ])
        let config = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .automatic
        )
        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("ModelContainer error: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task { await seedDatabases() }
                .task { await NotificationService.shared.demanderAutorisation() }
                .task { await exportSiNecessaire() }
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, nouveau in
            if nouveau == .background {
                Task { await exportEnArrierePlan() }
            }
        }

        #if os(macOS)
        Settings {
            ProfileView()
        }
        #endif
    }

    // MARK: - Seeding

    @MainActor
    private func seedDatabases() async {
        let context = container.mainContext

        SeedFoodItems.run(context: context)

        let supermarketService = SupermarketSeedService()
        await supermarketService.fetchAndSeed(context: context)

        let wgerService = WgerSeedService()
        await wgerService.seedIfNeeded(context: context)
    }

    // MARK: - Export iCloud Drive

    @MainActor
    private func exportSiNecessaire() async {
        guard exportAutoActive else { return }
        let service = iCloudExportService.shared
        if let derniere = service.derniereExportDate,
           Date().timeIntervalSince(derniere) < 3600 {
            return
        }
        await effectuerExport()
    }

    @MainActor
    private func exportEnArrierePlan() async {
        guard exportAutoActive else { return }
        await effectuerExport()
    }

    @MainActor
    private func effectuerExport() async {
        let context = container.mainContext
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profiles = try? context.fetch(descriptor),
              let profile = profiles.first(where: { $0.profileID.uuidString == activeProfileID })
                ?? profiles.first else {
            return
        }
        do {
            try await iCloudExportService.shared.exportAll(context: context, profile: profile)
        } catch {
            print("Export iCloud échoué : \(error)")
        }
    }
}
