import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var selection: SidebarItem? = .dashboard
    @State private var showOnboarding = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView(onComplete: {
                    showOnboarding = false
                })
            } else {
                mainContent
            }
        }
        .onAppear {
            if profiles.isEmpty {
                showOnboarding = true
            }
        }
        .onChange(of: profiles.isEmpty) { _, isEmpty in
            if isEmpty {
                showOnboarding = true
            }
        }
    }

    private var mainContent: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selection: $selection)
        } detail: {
            detailView
                .animation(.easeInOut(duration: 0.2), value: selection)
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private var detailView: some View {
        switch selection {
        case .dashboard, nil:
            DashboardView()
        case .journal:
            FoodLogView()
        case .corps:
            BodyTrackingView()
        case .activite:
            ActivityView()
        case .planRepas:
            MealPlanView()
        case .coach:
            AICoachView()
        case .profil:
            ProfileView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            FoodItem.self, FoodEntry.self, BodyMetric.self,
            ActivityEntry.self, MealPlan.self, UserProfile.self
        ], inMemory: true)
        .frame(width: 1000, height: 700)
}
