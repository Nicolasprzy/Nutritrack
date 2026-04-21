import SwiftUI
import SwiftData

struct ProgressPhotosView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.activeProfileID) private var activeProfileID
    @Query(sort: \ProgressPhoto.date, order: .reverse) private var toutesPhotos: [ProgressPhoto]

    @State private var showAdd = false
    @State private var selectionCompare: [ProgressPhoto] = []
    @State private var showCompare = false

    private var photos: [ProgressPhoto] {
        toutesPhotos.filter { $0.profileID == activeProfileID }
    }

    private func photosAngle(_ angle: PhotoAngle) -> [ProgressPhoto] {
        photos.filter { $0.angleEnum == angle }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                LuminaSectionHeader(
                    eyebrow: "Acte IV · Mémoire",
                    title: "Photos",
                    emphasis: "de progression."
                )
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)

                entete
                if photos.isEmpty {
                    ContentUnavailableView(
                        "Aucune photo de progression",
                        systemImage: "photo.stack",
                        description: Text("Prenez votre première session photo pour suivre votre transformation.")
                    )
                    .padding(.top, Spacing.xl)
                } else {
                    grilleTrois
                    if selectionCompare.count == 2 {
                        NutriButton(
                            "Comparer les 2 photos sélectionnées",
                            icon: "rectangle.split.2x1",
                            style: .primary,
                            size: .regular
                        ) {
                            showCompare = true
                        }
                    }
                }
            }
            .padding(Spacing.md)
        }
        .navigationTitle("")
        .background(Color.fondPrincipal.opacity(0.70))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.purple)
                }
                .accessibilityLabel("Nouvelle session photo")
            }
        }
        .nutriSheet(title: "Nouvelle session photo", size: .standard, isPresented: $showAdd) {
            AddProgressPhotoView()
        }
        .sheet(isPresented: $showCompare) {
            if selectionCompare.count == 2 {
                ComparePhotosView(photoA: selectionCompare[0], photoB: selectionCompare[1])
            }
        }
    }

    // MARK: - En-tête

    private var entete: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Label("Progression photo", systemImage: "photo.stack.fill")
                    .font(.nutriHeadline)
                    .foregroundStyle(.purple)
                Text("Tap sur 2 photos pour comparer. Historique par angle : face, profil, dos.")
                    .font(.nutriCaption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Grille 3 colonnes

    private var grilleTrois: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            ForEach(PhotoAngle.allCases, id: \.self) { angle in
                colonneAngle(angle)
            }
        }
    }

    private func colonneAngle(_ angle: PhotoAngle) -> some View {
        let liste = photosAngle(angle)
        return GlassCard(padding: Spacing.sm) {
            VStack(spacing: Spacing.sm) {
                Label(angle.label, systemImage: angle.icon)
                    .font(.nutriHeadline)
                    .foregroundStyle(.purple)
                if liste.isEmpty {
                    Text("—")
                        .font(.nutriCaption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, Spacing.md)
                } else {
                    ForEach(liste) { photo in
                        photoVignette(photo)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func photoVignette(_ photo: ProgressPhoto) -> some View {
        let estSelectionnee = selectionCompare.contains(where: { $0.id == photo.id })
        return Button {
            toggleSelection(photo)
        } label: {
            VStack(spacing: Spacing.xs) {
                PhotoImage(data: photo.imageData)
                    .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 160)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.sm)
                            .strokeBorder(estSelectionnee ? Color.purple : Color.clear, lineWidth: 3)
                    )
                Text(photo.dateFormatted)
                    .font(.nutriCaption2)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                modelContext.delete(photo)
                try? modelContext.save()
            } label: {
                Label("Supprimer", systemImage: "trash")
            }
        }
    }

    private func toggleSelection(_ photo: ProgressPhoto) {
        if let idx = selectionCompare.firstIndex(where: { $0.id == photo.id }) {
            selectionCompare.remove(at: idx)
        } else {
            if selectionCompare.count >= 2 {
                selectionCompare.removeFirst()
            }
            selectionCompare.append(photo)
        }
    }
}

// MARK: - Vue image cross-platform

struct PhotoImage: View {
    let data: Data?

    var body: some View {
        #if os(macOS)
        if let data, let ns = NSImage(data: data) {
            Image(nsImage: ns).resizable().scaledToFill()
        } else {
            placeholder
        }
        #else
        if let data, let ui = UIImage(data: data) {
            Image(uiImage: ui).resizable().scaledToFill()
        } else {
            placeholder
        }
        #endif
    }

    private var placeholder: some View {
        ZStack {
            Color.secondary.opacity(0.1)
            Image(systemName: "photo")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        ProgressPhotosView()
            .modelContainer(for: [ProgressPhoto.self, UserProfile.self], inMemory: true)
    }
}
