import SwiftUI
import SwiftData
import UniformTypeIdentifiers
#if os(iOS)
import PhotosUI
#endif

struct AddProgressPhotoView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.activeProfileID) private var activeProfileID
    @Environment(\.dismiss) private var dismiss

    @State private var angle: PhotoAngle = .front
    @State private var date: Date = Date()
    @State private var notes: String = ""
    @State private var imageParAngle: [PhotoAngle: Data] = [:]

    #if os(iOS)
    @State private var selectionPickerParAngle: [PhotoAngle: PhotosPickerItem] = [:]
    #else
    @State private var showFileImporter = false
    @State private var angleEnCoursImport: PhotoAngle = .front
    #endif

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {

            // ── Date ─────────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: Spacing.sm) {
                NutriSectionHeader("Date", icon: "calendar")
                NutriDatePicker(title: "", date: $date)
            }

            // ── Photos ───────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: Spacing.sm) {
                NutriSectionHeader("Photos (1 à 3 angles)", icon: "camera.fill")

                ForEach(PhotoAngle.allCases, id: \.self) { ang in
                    angleRow(ang)
                }
            }

            // ── Notes ────────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: Spacing.sm) {
                NutriSectionHeader("Notes", icon: "note.text")
                NutriField("", text: $notes, variant: .multiline(minLines: 2, maxLines: 5),
                           placeholder: "Commentaires sur la session…")
            }

            // ── Bouton d'action ──────────────────────────────────────────
            NutriButton("Enregistrer",
                        icon: "checkmark.circle.fill",
                        style: .primary,
                        isDisabled: imageParAngle.isEmpty) {
                enregistrer()
            }
            .padding(.top, Spacing.sm)
        }
        #if os(macOS)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        #endif
    }

    // MARK: - Row par angle

    @ViewBuilder
    private func angleRow(_ ang: PhotoAngle) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Label(ang.label, systemImage: ang.icon)
                    .font(.nutriBody)
                    .foregroundStyle(.purple)
                Spacer()
                if imageParAngle[ang] != nil {
                    Label("Prête", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(Color.nutriGreen)
                        .font(.nutriCaption)
                }
            }

            if let data = imageParAngle[ang] {
                PhotoImage(data: data)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            }

            #if os(iOS)
            PhotosPicker(
                selection: Binding(
                    get: { selectionPickerParAngle[ang] },
                    set: { newValue in
                        selectionPickerParAngle[ang] = newValue
                        if let newValue {
                            Task {
                                if let data = try? await newValue.loadTransferable(type: Data.self) {
                                    imageParAngle[ang] = data
                                }
                            }
                        }
                    }
                ),
                matching: .images
            ) {
                Label(imageParAngle[ang] == nil ? "Choisir" : "Remplacer",
                      systemImage: "photo.on.rectangle.angled")
                    .font(.nutriCaption)
            }
            #else
            NutriButton(
                imageParAngle[ang] == nil ? "Importer" : "Remplacer",
                icon: "photo.on.rectangle.angled",
                style: .secondary,
                size: .small
            ) {
                angleEnCoursImport = ang
                showFileImporter = true
            }
            #endif
        }
        .padding(.vertical, Spacing.xs)
    }

    #if os(macOS)
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let didStart = url.startAccessingSecurityScopedResource()
            defer { if didStart { url.stopAccessingSecurityScopedResource() } }
            if let data = try? Data(contentsOf: url) {
                imageParAngle[angleEnCoursImport] = data
            }
        case .failure(let error):
            print("Erreur import photo : \(error)")
        }
    }
    #endif

    private func enregistrer() {
        for (ang, data) in imageParAngle {
            let photo = ProgressPhoto(
                profileID: activeProfileID,
                date: date,
                angle: ang.rawValue,
                imageData: data,
                notes: notes
            )
            modelContext.insert(photo)
        }
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    AddProgressPhotoView()
        .modelContainer(for: ProgressPhoto.self, inMemory: true)
}
