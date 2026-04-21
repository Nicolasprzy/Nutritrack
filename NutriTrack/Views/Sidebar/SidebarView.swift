import SwiftUI
import SwiftData

struct SidebarView: View {
    @Binding var selection: SidebarItem?
    @Environment(\.activeProfileID) private var activeProfileID
    @Query private var profiles: [UserProfile]

    var profil: UserProfile? {
        profiles.first(where: { $0.profileID.uuidString == activeProfileID })
    }

    var body: some View {
        VStack(spacing: 0) {

            // ── Logo ────────────────────────────────────────────────────────
            logoArea
                .padding(.top, 28)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)

            // ── Navigation ──────────────────────────────────────────────────
            List(selection: $selection) {
                ForEach(Array(SidebarItem.allCases.enumerated()), id: \.element) { idx, item in
                    navRow(item: item, index: idx)
                        .tag(item)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 3, leading: 12, bottom: 3, trailing: 12))
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)

            Spacer(minLength: 0)

            // ── Pied de page — profil ────────────────────────────────────────
            if let profil {
                profilFooter(profil: profil)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
            }
        }
        .frame(minWidth: 220)
        .background {
            ZStack {
                // Fond brun sombre très chaud
                Color(red: 0.118, green: 0.086, blue: 0.063)
                    .ignoresSafeArea()
                // Léger voile blanc pour adoucir
                Color.white.opacity(0.03)
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - Logo

    private var logoArea: some View {
        HStack(spacing: 10) {
            // Glyph "N" dans un cercle corail
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.luminaEmberHot, Color.luminaEmber],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 34, height: 34)
                    .shadow(color: Color.luminaEmber.opacity(0.5), radius: 8, y: 3)

                Text("N")
                    .font(.luminaDisplay(18, weight: .regular))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("NUTRITRACK")
                    .font(.luminaMono(12, weight: .medium))
                    .tracking(3)
                    .foregroundStyle(Color.white.opacity(0.88))
                Text("v.1 · 2026")
                    .font(.luminaMono(9))
                    .tracking(2)
                    .foregroundStyle(Color.white.opacity(0.32))
            }

            Spacer()
        }
    }

    // MARK: - Nav Row

    private func navRow(item: SidebarItem, index: Int) -> some View {
        let isActive = selection == item
        return HStack(spacing: 10) {
            // Numéro
            Text(String(format: "%02d", index + 1))
                .font(.luminaMono(9))
                .tracking(1)
                .foregroundStyle(
                    isActive
                        ? Color.luminaEmberHot.opacity(0.8)
                        : Color.white.opacity(0.20)
                )
                .frame(width: 22, alignment: .trailing)

            // Icône
            Image(systemName: item.icon)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(
                    isActive
                        ? Color.luminaEmberHot
                        : Color.white.opacity(0.45)
                )
                .frame(width: 18)

            // Label
            Text(item.label)
                .font(
                    isActive
                        ? .luminaDisplay(14, weight: .regular)
                        : Font.system(size: 13, weight: .regular, design: .rounded)
                )
                .foregroundStyle(
                    isActive
                        ? Color.white.opacity(0.95)
                        : Color.white.opacity(0.55)
                )
                .lineLimit(1)

            Spacer()

            // Indicateur actif
            if isActive {
                Circle()
                    .fill(Color.luminaEmber)
                    .frame(width: 4, height: 4)
                    .shadow(color: Color.luminaEmber, radius: 3)
            }
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 10)
        .background {
            if isActive {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.luminaEmberHot.opacity(0.18),
                                Color.luminaEmber.opacity(0.08)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.luminaEmber.opacity(0.22), lineWidth: 0.5)
                    )
            } else {
                Color.clear
            }
        }
        .animation(.easeOut(duration: 0.2), value: isActive)
        .contentShape(Rectangle())
    }

    // MARK: - Pied de page profil

    private func profilFooter(profil: UserProfile) -> some View {
        HStack(spacing: 10) {
            // Avatar circulaire avec initiale
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.luminaEmberHot.opacity(0.7), Color.luminaEmber.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                    )
                    .frame(width: 34, height: 34)

                Text(String(profil.prenom.prefix(1)).uppercased())
                    .font(.luminaDisplay(16, weight: .regular))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(profil.prenom.isEmpty ? "Mon profil" : profil.prenom)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.80))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.luminaEmber)
                        .frame(width: 5, height: 5)
                        .shadow(color: Color.luminaEmber, radius: 2)
                    Text("En transformation")
                        .font(.luminaMono(9))
                        .tracking(1)
                        .foregroundStyle(Color.luminaInkDim)
                }
            }

            Spacer()
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        }
    }
}

#Preview {
    NavigationSplitView {
        SidebarView(selection: .constant(.dashboard))
            .modelContainer(for: UserProfile.self, inMemory: true)
    } detail: {
        ZStack {
            AmbientBackground()
            Text("Contenu")
                .font(.luminaDisplay(24))
                .foregroundStyle(Color.luminaInkPrimary)
        }
    }
    .frame(width: 780, height: 560)
}
