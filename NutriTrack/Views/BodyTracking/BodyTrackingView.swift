import SwiftUI
import SwiftData
import Charts

struct BodyTrackingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.activeProfileID) private var activeProfileID
    @Query private var profiles: [UserProfile]

    @State private var viewModel = BodyTrackingViewModel()
    @State private var healthKitService = HealthKitService()
    @State private var ongletActif: OngletCorps = .poids

    var profil: UserProfile? { profiles.first(where: { $0.profileID.uuidString == activeProfileID }) }

    enum OngletCorps: String, CaseIterable {
        case poids        = "Poids"
        case mensurations = "Mensurations"
        case analyse      = "Analyse"
        case progression  = "Progression"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                carteResume
                ongletSelector
                switch ongletActif {
                case .poids:        contenuPoids
                case .mensurations: contenuMensurations
                case .analyse:      contenuAnalyse
                case .progression:  contenuProgression
                }
                historique
            }
            .padding(Spacing.md)
        }
        .navigationTitle("Corps & Forme")
        .background(Color.fondPrincipal)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { viewModel.showAddMetric = true }) {
                    Image(systemName: "plus.circle.fill").foregroundStyle(.blue)
                }
                .accessibilityLabel("Ajouter une mesure")
            }
        }
        .sheet(isPresented: $viewModel.showAddMetric, onDismiss: {
            viewModel.charger(context: modelContext, profileID: activeProfileID)
        }) {
            AddMetricView()
        }
        .onAppear {
            viewModel.charger(context: modelContext, profileID: activeProfileID)
        }
    }

    // MARK: - Carte résumé

    private var carteResume: some View {
        GlassCard {
            HStack(spacing: 0) {
                resumeItem(
                    valeur: viewModel.dernierPoids > 0 ? viewModel.dernierPoids.kg : "—",
                    label: "Poids",
                    icone: "scalemass.fill",
                    couleur: .blue
                )
                Divider().frame(height: 50)
                resumeItem(
                    valeur: viewModel.dernierIMC > 0 ? viewModel.dernierIMC.arrondi(1) : "—",
                    label: "IMC",
                    icone: "figure.stand",
                    couleur: imcCouleur
                )
                Divider().frame(height: 50)
                VStack(spacing: 4) {
                    Text(viewModel.evolutionPoidsFormatee)
                        .font(.nutriTitle2).foregroundStyle(evolutionCouleur)
                    Text("vs début")
                        .font(.nutriCaption).foregroundStyle(.secondary)
                    Image(systemName: evolutionIcone)
                        .foregroundStyle(evolutionCouleur)
                }
                .frame(maxWidth: .infinity)

                // Dernières mensurations (si disponibles)
                if let m = viewModel.derniereMensuration, m.waist > 0 {
                    Divider().frame(height: 50)
                    resumeItem(
                        valeur: "\(m.waist.arrondi(0)) cm",
                        label: "Taille",
                        icone: "ruler",
                        couleur: .purple
                    )
                }
            }
        }
    }

    private func resumeItem(valeur: String, label: String, icone: String, couleur: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icone).foregroundStyle(couleur)
            Text(valeur).font(.nutriTitle2)
            Text(label).font(.nutriCaption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Sélecteur d'onglet

    private var ongletSelector: some View {
        Picker("Onglet", selection: $ongletActif) {
            ForEach(OngletCorps.allCases, id: \.self) { o in
                Text(o.rawValue).tag(o)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Onglet Poids

    private var contenuPoids: some View {
        VStack(spacing: Spacing.md) {
            ChartCard(titre: "Évolution du poids", icone: "chart.line.uptrend.xyaxis", couleur: .blue) {
                VStack(spacing: Spacing.sm) {
                    Picker("Période", selection: $viewModel.periode) {
                        ForEach(BodyTrackingViewModel.Periode.allCases, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: viewModel.periode) { _, _ in
                        viewModel.charger(context: modelContext, profileID: activeProfileID)
                    }
                    WeightChartView(donnees: viewModel.donneesPoids)
                }
            }

            LazyVGrid(
                columns: [GridItem(.flexible(minimum: 160), spacing: 20), GridItem(.flexible(minimum: 160))],
                spacing: 20
            ) {
                MiniChartView(titre: "Masse grasse", donnees: viewModel.donneesMasseGrasse, couleur: .red, unite: "%")
                MiniChartView(titre: "IMC", donnees: viewModel.donneesIMC, couleur: imcCouleur, unite: "")
            }
        }
    }

    // MARK: - Onglet Mensurations

    private var contenuMensurations: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(minimum: 160), spacing: 20), GridItem(.flexible(minimum: 160))],
            spacing: 20
        ) {
            MiniChartView(titre: "Tour de taille",   donnees: viewModel.donneesTourDeTaille,   couleur: .orange, unite: "cm")
            MiniChartView(titre: "Tour de hanches",  donnees: viewModel.donneesTourDeHanches,  couleur: .purple, unite: "cm")
            MiniChartView(titre: "Poitrine",         donnees: viewModel.donneesPoitrine,        couleur: .teal,   unite: "cm")
            MiniChartView(titre: "Bras droit",       donnees: viewModel.donneesBras,            couleur: .blue,   unite: "cm")
            MiniChartView(titre: "Cuisse",           donnees: viewModel.donneesCuisse,          couleur: .indigo, unite: "cm")
            MiniChartView(titre: "Masse grasse",     donnees: viewModel.donneesMasseGrasse,     couleur: .red,    unite: "%")
        }
    }

    // MARK: - Onglet Analyse morphologique

    @ViewBuilder
    private var contenuAnalyse: some View {
        if let p = profil {
            BodyMorphoView(
                profil: p,
                metric: viewModel.derniereMensuration
            )
        } else {
            GlassCard {
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 40)).foregroundStyle(.secondary)
                    Text("Profil non chargé")
                        .font(.nutriBody)
                    Text("Créez un profil pour accéder à l'analyse morphologique.")
                        .font(.nutriCaption).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
            }
        }
    }

    // MARK: - Onglet Progression (silhouette)

    private var contenuProgression: some View {
        VStack(spacing: Spacing.md) {
            if let p = profil, !p.silhouetteObjectif.isEmpty,
               let cible = SilhouetteObjectif(rawValue: p.silhouetteObjectif) {
                silhouetteProgressCard(profil: p, cible: cible)
                comparaisonMesurationsCard(profil: p)
            } else {
                GlassCard {
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "figure.arms.open")
                            .font(.system(size: 40)).foregroundStyle(.secondary)
                        Text("Aucun objectif de silhouette défini")
                            .font(.nutriBody)
                        Text("Définissez votre objectif dans le Profil.")
                            .font(.nutriCaption).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                }
            }
        }
    }

    private func silhouetteProgressCard(profil: UserProfile, cible: SilhouetteObjectif) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Label("Objectif de silhouette", systemImage: "figure.arms.open")
                    .font(.nutriHeadline).foregroundStyle(.blue)

                HStack(spacing: 0) {
                    // Silhouette de départ (approximée par la silhouette "normale")
                    VStack(spacing: 6) {
                        SilhouetteView(
                            objectif: .normal,
                            sexe: profil.sexeEnum,
                            isSelected: false,
                            width: 50, height: 100
                        )
                        Text("Départ").font(.nutriCaption).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 4) {
                        Image(systemName: "arrow.right").foregroundStyle(Color.nutriGreen)
                        if let dateObj = Optional(profil.dateObjectif), dateObj > Date() {
                            let jours = Calendar.current.dateComponents([.day], from: Date(), to: dateObj).day ?? 0
                            Text("\(jours)j restants")
                                .font(.system(size: 9)).foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 6) {
                        SilhouetteView(
                            objectif: cible,
                            sexe: profil.sexeEnum,
                            isSelected: true,
                            width: 50, height: 100
                        )
                        Text(cible.label(sexe: profil.sexeEnum))
                            .font(.nutriCaption).foregroundStyle(Color.nutriGreen)
                    }
                    .frame(maxWidth: .infinity)
                }

                // Barre de progression temporelle
                let totalJours = max(1, Calendar.current.dateComponents([.day], from: profil.createdAt, to: profil.dateObjectif).day ?? 1)
                let joursEcoules = Calendar.current.dateComponents([.day], from: profil.createdAt, to: Date()).day ?? 0
                let progression = min(1.0, Double(joursEcoules) / Double(totalJours))

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Progression temporelle")
                            .font(.nutriCaption).foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(progression * 100))%")
                            .font(.nutriCaption).foregroundStyle(Color.nutriGreen)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.2))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.nutriGreen)
                                .frame(width: geo.size.width * progression, height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
    }

    private typealias LigneMensuration = (label: String, initial: Double, actuelle: Double, couleur: Color)

    private func lignesMensurations(profil: UserProfile) -> [LigneMensuration] {
        let derniere = viewModel.derniereMensuration
        let toutes: [LigneMensuration] = [
            ("Tour de taille",  profil.mensurationTailleCm,    derniere?.waist    ?? 0, .orange),
            ("Hanches",         profil.mensurationHanchesCm,   derniere?.hips     ?? 0, .purple),
            ("Poitrine",        profil.mensurationPoitrineCm,  derniere?.chest    ?? 0, .teal),
            ("Bras droit",      profil.mensurationBrasDroitCm, derniere?.armRight ?? 0, .blue),
            ("Cuisse",          profil.mensurationCuisseCm,    derniere?.thigh    ?? 0, .indigo),
        ]
        return toutes.filter { $0.initial > 0 || $0.actuelle > 0 }
    }

    private func comparaisonMesurationsCard(profil: UserProfile) -> some View {
        let initiales = lignesMensurations(profil: profil)

        return Group {
            if initiales.isEmpty {
                GlassCard {
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "ruler").font(.title2).foregroundStyle(.secondary)
                        Text("Aucune mensuration enregistrée")
                            .font(.nutriCaption).foregroundStyle(.secondary)
                        Text("Ajoutez une mesure avec le bouton + pour suivre votre progression.")
                            .font(.system(size: 10)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, Spacing.sm)
                }
            } else {
                GlassCard {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Label("Évolution des mensurations", systemImage: "ruler.fill")
                            .font(.nutriHeadline).foregroundStyle(.purple)

                        ForEach(initiales, id: \.label) { item in
                            HStack {
                                Text(item.label).font(.nutriCaption).frame(width: 90, alignment: .leading)
                                Spacer()
                                if item.initial > 0 {
                                    Text("\(item.initial.arrondi(1)) cm")
                                        .font(.nutriCaption).foregroundStyle(.secondary)
                                } else {
                                    Text("—").font(.nutriCaption).foregroundStyle(.secondary)
                                }
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 10)).foregroundStyle(.secondary)
                                if item.actuelle > 0 {
                                    let diff = item.actuelle - item.initial
                                    HStack(spacing: 3) {
                                        Text("\(item.actuelle.arrondi(1)) cm")
                                            .font(.nutriCaption).foregroundStyle(item.couleur)
                                        if item.initial > 0 && abs(diff) > 0.1 {
                                            Text(diff > 0 ? "+\(diff.arrondi(1))" : diff.arrondi(1))
                                                .font(.system(size: 9))
                                                .foregroundStyle(diff < 0 ? Color.nutriGreen : .orange)
                                        }
                                    }
                                } else {
                                    Text("—").font(.nutriCaption).foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                            if item.label != initiales.last?.label { Divider() }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Historique

    @ViewBuilder
    private var historique: some View {
        if !viewModel.metrics.isEmpty {
            GlassCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Label("Historique", systemImage: "list.bullet").font(.nutriHeadline)

                    ForEach(viewModel.metrics.reversed().prefix(10)) { metric in
                        HStack(spacing: Spacing.sm) {
                            Text(metric.date.formatCourt)
                                .font(.nutriCaption).foregroundStyle(.secondary)
                                .frame(width: 50, alignment: .leading)

                            VStack(alignment: .leading, spacing: 1) {
                                if metric.weight > 0 {
                                    HStack(spacing: 4) {
                                        Text(metric.weight.kg).font(.nutriBody)
                                        if metric.bmi > 0 {
                                            Text("IMC \(metric.bmi.arrondi(1))")
                                                .font(.nutriCaption).foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                if metric.aMensurations {
                                    let parts = [
                                        metric.waist > 0    ? "T:\(metric.waist.arrondi(0))" : nil,
                                        metric.hips > 0     ? "H:\(metric.hips.arrondi(0))" : nil,
                                        metric.chest > 0    ? "P:\(metric.chest.arrondi(0))" : nil,
                                        metric.armRight > 0 ? "B:\(metric.armRight.arrondi(0))" : nil,
                                        metric.thigh > 0    ? "C:\(metric.thigh.arrondi(0))" : nil,
                                    ].compactMap { $0 }
                                    Text(parts.joined(separator: "  "))
                                        .font(.system(size: 10)).foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            // Delta poids vs mesure précédente
                            if metric.weight > 0,
                               let prec = viewModel.metrics.reversed().first(where: { $0.date < metric.date && $0.weight > 0 }) {
                                let diff = metric.weight - prec.weight
                                Text(diff > 0 ? "+\(diff.arrondi(1))" : diff.arrondi(1))
                                    .font(.nutriCaption)
                                    .foregroundStyle(diff > 0 ? .orange : Color.nutriGreen)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.supprimer(metric, context: modelContext)
                            } label: {
                                Label("Supprimer", systemImage: "trash")
                            }
                        }

                        if metric.id != viewModel.metrics.reversed().prefix(10).last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var imcCouleur: Color {
        switch viewModel.dernierIMC {
        case ..<18.5: return .blue
        case 18.5..<25: return .nutriGreen
        case 25..<30: return .orange
        default: return .red
        }
    }

    private var evolutionCouleur: Color {
        if viewModel.evolutionPoids > 0.5 { return .orange }
        if viewModel.evolutionPoids < -0.5 { return .nutriGreen }
        return .primary
    }

    private var evolutionIcone: String {
        if viewModel.evolutionPoids > 0.5 { return "arrow.up" }
        if viewModel.evolutionPoids < -0.5 { return "arrow.down" }
        return "minus"
    }
}

// MARK: - MiniChartView

struct MiniChartView: View {
    let titre: String
    let donnees: [(date: Date, valeur: Double)]
    let couleur: Color
    let unite: String

    @State private var chartProgress: Double = 0

    var body: some View {
        GlassCard(padding: Spacing.sm) {
            VStack(alignment: .leading, spacing: 4) {
                Text(titre)
                    .font(.nutriCaption).foregroundStyle(.secondary)

                if donnees.isEmpty {
                    Text("—")
                        .font(.nutriTitle2).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
                } else {
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(donnees.last!.valeur.arrondi(1))\(unite)")
                                .font(.nutriTitle2).foregroundStyle(couleur)
                            if donnees.count >= 2 {
                                let diff = donnees.last!.valeur - donnees.first!.valeur
                                Text(diff > 0 ? "+\(diff.arrondi(1))" : diff.arrondi(1))
                                    .font(.nutriCaption)
                                    .foregroundStyle(diff < 0 ? Color.nutriGreen : .orange)
                            }
                        }
                        Spacer()
                        if donnees.count > 1 {
                            Chart(donnees, id: \.date) { pt in
                                LineMark(
                                    x: .value("Date", pt.date),
                                    y: .value("Val", pt.valeur)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(couleur)
                            }
                            .chartXAxis(.hidden)
                            .chartYAxis(.hidden)
                            .frame(width: 60, height: 40)
                            .opacity(chartProgress)
                            .scaleEffect(CGSize(width: 1.0, height: chartProgress), anchor: .bottom)
                            .onAppear {
                                chartProgress = 0
                                withAnimation(.easeOut(duration: 0.6).delay(0.1)) { chartProgress = 1.0 }
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        BodyTrackingView()
            .modelContainer(for: [BodyMetric.self, UserProfile.self], inMemory: true)
    }
}
