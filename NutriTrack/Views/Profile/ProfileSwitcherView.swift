import SwiftUI
import SwiftData

struct ProfileSwitcherView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]

    @Binding var activeProfileID: String
    var onNouveauProfil: () -> Void

    @State private var profilASupprimer: UserProfile?

    var body: some View {
        ZStack {
            // Fond dégradé
            LinearGradient(
                colors: [Color.nutriGreen.opacity(0.18), Color.blue.opacity(0.10), Color.fondPrincipal],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                entete

                // Grille de profils
                if profiles.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 160, maximum: 200))],
                        spacing: Spacing.md
                    ) {
                        ForEach(profiles, id: \.profileID) { profil in
                            ProfilCard(profil: profil) {
                                withAnimation(.spring(response: 0.35)) {
                                    activeProfileID = profil.profileID.uuidString
                                }
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    profilASupprimer = profil
                                } label: {
                                    Label("Supprimer ce profil", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.xl)

                    Text("Clic droit sur un profil pour le supprimer")
                        .font(.caption)
                        .foregroundStyle(Color.secondary.opacity(0.5))
                }

                // Bouton nouveau profil
                NutriButton(
                    "Créer un nouveau profil",
                    icon: "plus.circle.fill",
                    style: .primary,
                    size: .large,
                    action: onNouveauProfil
                )
                .padding(.bottom, Spacing.xl)
            }
            .frame(maxWidth: NutriLayout.sheetCompactWidth)
        }
        .frame(minWidth: 400, minHeight: 400)
        .nutriConfirm(
            title: "Supprimer \(profilASupprimer?.prenom ?? "ce profil") ?",
            message: profilASupprimer.map {
                "Le profil de \($0.prenom) sera définitivement supprimé. Cette action est irréversible."
            } ?? "",
            destructive: true,
            confirmLabel: "Supprimer",
            isPresented: Binding(
                get: { profilASupprimer != nil },
                set: { if !$0 { profilASupprimer = nil } }
            ),
            onConfirm: {
                supprimerProfil(profilASupprimer)
            }
        )
    }

    // MARK: - En-tête

    private var entete: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.nutriGreen, Color.nutriGreen.opacity(0.7)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 72, height: 72)
                    .shadow(color: Color.nutriGreen.opacity(0.35), radius: 14, x: 0, y: 7)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 28)) // icône hero
                    .foregroundStyle(.white)
            }

            Text("NutriTrack")
                .font(.nutriTitle)

            Text(profiles.isEmpty ? "Créez votre premier profil" : "Choisissez votre profil")
                .font(.nutriBody)
                .foregroundStyle(.secondary)
        }
        .padding(.top, Spacing.xl)
    }

    // MARK: - État vide

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 48)) // icône hero ≥ 40 — conservée
                .foregroundStyle(Color.secondary.opacity(0.4))
            Text("Aucun profil pour l'instant")
                .font(.nutriBody)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, Spacing.xl)
    }

    // MARK: - Suppression

    private func supprimerProfil(_ profil: UserProfile?) {
        guard let p = profil else { return }
        let pid = p.profileID.uuidString

        // Supprimer toutes les données liées à ce profil
        let foodEntries = (try? modelContext.fetch(FetchDescriptor<FoodEntry>(
            predicate: #Predicate { $0.profileID == pid }
        ))) ?? []
        foodEntries.forEach { modelContext.delete($0) }

        let metrics = (try? modelContext.fetch(FetchDescriptor<BodyMetric>(
            predicate: #Predicate { $0.profileID == pid }
        ))) ?? []
        metrics.forEach { modelContext.delete($0) }

        let activites = (try? modelContext.fetch(FetchDescriptor<ActivityEntry>(
            predicate: #Predicate { $0.profileID == pid }
        ))) ?? []
        activites.forEach { modelContext.delete($0) }

        if activeProfileID == pid { activeProfileID = "" }
        modelContext.delete(p)
        try? modelContext.save()
        profilASupprimer = nil
    }
}

// MARK: - Carte profil

private struct ProfilCard: View {
    let profil: UserProfile
    let onSelect: () -> Void

    @State private var isHovered = false

    private var initiales: String {
        let parts = profil.prenom.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        if letters.isEmpty { return "?" }
        return String(letters.map { String($0) }.joined()).uppercased()
    }

    private var couleurAvatar: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .red, .teal, .indigo, .cyan]
        let index = abs(profil.prenom.hashValue) % colors.count
        return colors[index]
    }

    var body: some View {
        Button(action: onSelect) {
            GlassCard(padding: Spacing.md) {
                VStack(spacing: Spacing.sm) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [couleurAvatar, couleurAvatar.opacity(0.7)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .frame(width: 64, height: 64)
                            .shadow(color: couleurAvatar.opacity(0.3), radius: 8, x: 0, y: 4)
                        Text(initiales)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                    }

                    // Nom
                    Text(profil.prenom.isEmpty ? "Profil sans nom" : profil.prenom)
                        .font(.nutriHeadline)
                        .lineLimit(1)

                    // Infos
                    Text("\(profil.age) ans · \(profil.sexeEnum.label)")
                        .font(.nutriCaption)
                        .foregroundStyle(.secondary)

                    if profil.aUnObjectifSilhouette, let silhouette = profil.silhouetteEnum {
                        Text(silhouette.label(sexe: profil.sexeEnum))
                            .font(.nutriCaption)
                            .foregroundStyle(Color.nutriGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background { Capsule().fill(Color.nutriGreen.opacity(0.12)) }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .scaleEffect(isHovered ? 1.03 : 1.0)
            .shadow(color: couleurAvatar.opacity(isHovered ? 0.2 : 0), radius: 12, x: 0, y: 6)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

#Preview {
    ProfileSwitcherView(activeProfileID: .constant(""), onNouveauProfil: {})
        .modelContainer(for: [UserProfile.self], inMemory: true)
        .frame(width: 600, height: 500)
}
