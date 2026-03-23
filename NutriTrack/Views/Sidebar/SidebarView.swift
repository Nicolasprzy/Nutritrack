import SwiftUI
import SwiftData

struct SidebarView: View {
    @Binding var selection: SidebarItem?
    @Query private var profiles: [UserProfile]

    var profil: UserProfile? { profiles.first }

    var body: some View {
        List(selection: $selection) {
            ForEach(SidebarItem.allCases) { item in
                Label(item.label, systemImage: item.icon)
                    .tag(item)
                    .accessibilityLabel(item.label)
            }
        }
        .navigationTitle("NutriTrack")
        #if os(macOS)
        .listStyle(.sidebar)
        #endif
        .safeAreaInset(edge: .bottom) {
            if let profil {
                profilResume(profil: profil)
                    .padding()
            }
        }
    }

    @ViewBuilder
    private func profilResume(profil: UserProfile) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(profil.prenom.isEmpty ? "Mon profil" : profil.prenom)
                    .font(.nutriHeadline)
                Text("\(profil.objectifCalorique.arrondi(0)) kcal/jour")
                    .font(.nutriCaption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(Spacing.sm)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.md))
    }
}

#Preview {
    NavigationSplitView {
        SidebarView(selection: .constant(.dashboard))
            .modelContainer(for: UserProfile.self, inMemory: true)
    } detail: {
        Text("Contenu")
    }
    .frame(width: 700, height: 500)
}
