import SwiftUI

/// Section "Compte" — changer profil, créer profil, réinitialiser, supprimer.
/// Utilise NutriButton + .nutriConfirm pour les actions destructives.
struct ProfileDangerSection: View {
    var prenomProfil: String
    var onDeconnexion: () -> Void
    var onNouveauProfil: () -> Void
    var onReinitialiser: () -> Void
    var onSupprimer: () -> Void

    @State private var showResetConfirm = false
    @State private var showDeleteConfirm = false

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label("Compte", systemImage: "person.crop.circle")
                    .font(.nutriHeadline)
                    .foregroundStyle(Color.gray)
                Divider()

                // Changer de profil
                Button(action: onDeconnexion) {
                    Label("Changer de profil", systemImage: "person.2.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)

                Divider()

                // Ajouter un profil
                Button(action: onNouveauProfil) {
                    Label("Créer un nouveau profil", systemImage: "person.badge.plus")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)

                Divider()

                // Réinitialiser
                NutriButton(
                    "Réinitialiser ce profil",
                    icon: "person.crop.circle.badge.minus",
                    style: .destructive,
                    size: .regular
                ) {
                    showResetConfirm = true
                }
                .padding(.vertical, 4)

                Divider()

                // Supprimer
                NutriButton(
                    "Supprimer ce profil",
                    icon: "trash.fill",
                    style: .destructive,
                    size: .regular
                ) {
                    showDeleteConfirm = true
                }
                .padding(.vertical, 4)
            }
        }
        .nutriConfirm(
            title: "Réinitialiser le profil ?",
            message: "Votre profil sera supprimé et l'onboarding s'affichera à nouveau. Vos données alimentaires et corporelles seront conservées.",
            destructive: true,
            confirmLabel: "Réinitialiser",
            isPresented: $showResetConfirm,
            onConfirm: onReinitialiser
        )
        .nutriConfirm(
            title: "Supprimer ce profil ?",
            message: "Le profil de \(prenomProfil.isEmpty ? "cet utilisateur" : prenomProfil) sera définitivement supprimé. Les autres profils ne seront pas affectés.",
            destructive: true,
            confirmLabel: "Supprimer",
            isPresented: $showDeleteConfirm,
            onConfirm: onSupprimer
        )
    }
}
