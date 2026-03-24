import SwiftUI
import SwiftData

@main
struct NutriTrackApp: App {
    let container: ModelContainer
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let schema = Schema([
            FoodItem.self,
            FoodEntry.self,
            BodyMetric.self,
            ActivityEntry.self,
            MealPlan.self,
            UserProfile.self,
            UserPlan.self,
            Exercise.self
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
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { @MainActor in checkReevaluationOnForeground() }
            }
        }

        #if os(macOS)
        Settings {
            ProfileView()
        }
        #endif
    }

    // MARK: - Foreground check

    @MainActor
    private func checkReevaluationOnForeground() {
        let context = container.mainContext
        let descriptor = FetchDescriptor<UserPlan>(
            predicate: #Predicate<UserPlan> { $0.estActif == true }
        )
        guard let plan = (try? context.fetch(descriptor))?.first,
              let profil = (try? context.fetch(FetchDescriptor<UserProfile>()))?.first,
              Date() >= plan.prochainReevaluation else { return }

        // Re-schedule si la notification a été manquée (app ouverte après l'échéance)
        NotificationService.shared.planifierReevaluation(dans: 0, prenom: profil.prenom)
    }

    // MARK: - Seeding

    @MainActor
    private func seedDatabases() async {
        let context = container.mainContext

        // 1. Base locale (~200 aliments génériques français)
        SeedFoodItems.run(context: context)

        // 2. Produits Lidl / Carrefour / Auchan via Open Food Facts
        let supermarketService = SupermarketSeedService()
        await supermarketService.fetchAndSeed(context: context)

        // 3. Exercices Wger (~300 exercices avec muscles & images)
        let wgerService = WgerSeedService()
        await wgerService.seedIfNeeded(context: context)
    }
}
