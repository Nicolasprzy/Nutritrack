import SwiftUI
import SwiftData
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Section "Export iCloud Drive" — export automatique, chemin, déclenchement manuel.
struct ProfileExportSection: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.activeProfileID) private var activeProfileID
    @Query private var profiles: [UserProfile]

    @State private var exportService = iCloudExportService.shared
    @State private var exportEnCours = false
    @State private var exportMessage: String?
    @AppStorage("exportAutomatiqueActive") private var exportAutoActive: Bool = true

    private var profilActif: UserProfile? {
        profiles.first(where: { $0.profileID.uuidString == activeProfileID })
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label("Export iCloud Drive", systemImage: "icloud.and.arrow.up.fill")
                    .font(.nutriHeadline)
                    .foregroundStyle(Color.cyan)
                Divider()

                ProfileRowHelper.row("Dernier export") {
                    Text(formatDernierExport())
                        .font(.nutriCaption)
                        .foregroundStyle(.secondary)
                }
                Divider()

                ProfileRowHelper.row("Export automatique") {
                    Toggle("", isOn: $exportAutoActive).labelsHidden()
                }
                Divider()

                if exportService.iCloudAvailable {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dossier")
                            .font(.nutriCaption2)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        HStack(spacing: 6) {
                            Text(exportService.iCloudPathAffichable())
                                .font(.system(size: 10, design: .monospaced)) // chemin mono compact — justifié
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .truncationMode(.middle)
                            Spacer()
                            Button {
                                copierPath()
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .foregroundStyle(.cyan)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                    Divider()

                    Button {
                        Task { await exporterMaintenant() }
                    } label: {
                        HStack {
                            if exportEnCours {
                                ProgressView().controlSize(.small)
                                Text("Export en cours…")
                            } else {
                                Label("Exporter maintenant", systemImage: "arrow.up.to.line")
                            }
                            Spacer()
                        }
                        .foregroundStyle(.cyan)
                    }
                    .buttonStyle(.plain)
                    .disabled(exportEnCours)
                    .padding(.vertical, 4)

                    if let msg = exportMessage {
                        Text(msg)
                            .font(.nutriCaption)
                            .foregroundStyle(msg.hasPrefix("✓") ? Color.nutriGreen : .orange)
                    }
                } else {
                    Text("iCloud Drive non configuré sur cet appareil. Activez iCloud Drive dans Réglages Système pour exporter vos données.")
                        .font(.nutriCaption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func formatDernierExport() -> String {
        guard let date = exportService.derniereExportDate else { return "Jamais" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func copierPath() {
        let path = exportService.iCloudPathAffichable()
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(path, forType: .string)
        #else
        UIPasteboard.general.string = path
        #endif
        exportMessage = "✓ Chemin copié"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if exportMessage == "✓ Chemin copié" { exportMessage = nil }
        }
    }

    private func exporterMaintenant() async {
        guard let p = profilActif else { return }
        exportEnCours = true
        exportMessage = nil
        do {
            try await exportService.exportAll(context: modelContext, profile: p)
            exportMessage = "✓ Export terminé"
        } catch {
            exportMessage = "Échec : \(error.localizedDescription)"
        }
        exportEnCours = false
    }
}
