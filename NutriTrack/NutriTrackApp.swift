import SwiftUI
import SwiftData

@main
struct NutriTrackApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            FoodItem.self,
            FoodEntry.self,
            BodyMetric.self,
            ActivityEntry.self,
            MealPlan.self,
            UserProfile.self
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
        }
        .modelContainer(container)

        #if os(macOS)
        Settings {
            ProfileView()
        }
        #endif
    }
}
