import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @AppStorage("activeProfileID") private var activeProfileID: String = ""
    @State private var showNouvelOnboarding = false
    @State private var selection: SidebarItem? = .dashboard
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    private var activeProfile: UserProfile? {
        profiles.first(where: { $0.profileID.uuidString == activeProfileID })
    }

    var body: some View {
        Group {
            if showNouvelOnboarding {
                // Création d'un nouveau profil supplémentaire
                OnboardingView(onComplete: { showNouvelOnboarding = false })

            } else if activeProfileID.isEmpty || activeProfile == nil {
                // Aucun profil actif → sélecteur
                ProfileSwitcherView(
                    activeProfileID: $activeProfileID,
                    onNouveauProfil: { showNouvelOnboarding = true }
                )

            } else if activeProfile?.onboardingV2Complete == false {
                // Profil existant mais onboarding non terminé
                OnboardingView(onComplete: {})

            } else {
                mainContent
                    .environment(\.activeProfileID, activeProfileID)
            }
        }
    }

    private var mainContent: some View {
        ZStack {
            // ── Fond ambiant Lumina ──────────────────────────────────────────
            AmbientBackground()
                .ignoresSafeArea()

            // ── Grain film subtil ────────────────────────────────────────────
            GrainOverlay()
                .ignoresSafeArea()

            // ── Navigation principale ────────────────────────────────────────
            NavigationSplitView(columnVisibility: $columnVisibility) {
                SidebarView(selection: $selection)
                    .environment(\.activeProfileID, activeProfileID)
            } detail: {
                detailView
                    .animation(.easeInOut(duration: 0.2), value: selection)
                    .environment(\.activeProfileID, activeProfileID)
            }
            .navigationSplitViewStyle(.balanced)
            // Fond transparent pour laisser l'ambient background visible
            .background(.clear)
        }
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
        case .photos:
            ProgressPhotosView()
        case .activite:
            ActivityView()
        case .profil:
            ProfileView(onDeconnexion: {
                activeProfileID = ""
            }, onNouveauProfil: {
                showNouvelOnboarding = true
            })
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            FoodItem.self, FoodEntry.self, BodyMetric.self,
            ActivityEntry.self, UserProfile.self
        ], inMemory: true)
        .frame(width: 1000, height: 700)
}
