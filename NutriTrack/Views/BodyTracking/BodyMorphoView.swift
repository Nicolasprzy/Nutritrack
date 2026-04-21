import SwiftUI

// MARK: - Vue principale d'analyse morphologique

struct BodyMorphoView: View {
    let profil: UserProfile
    let metric: BodyMetric?

    private var analyse: AnalyseMorpho {
        let m = metric
        let poids = m?.weight ?? profil.poidsActuel
        let bmi   = m?.bmi   ?? (profil.taille > 0
                                  ? NutritionCalculator.imc(poids: poids, taille: profil.taille)
                                  : 0)
        return MorphoCalculator.analyser(
            taille:      profil.taille,
            sexe:        profil.sexe,
            poids:       poids,
            waist:       m?.waist      ?? profil.mensurationTailleCm,
            hips:        m?.hips       ?? profil.mensurationHanchesCm,
            chest:       m?.chest      ?? profil.mensurationPoitrineCm,
            arm:         m?.armRight   ?? profil.mensurationBrasDroitCm,
            thigh:       m?.thigh      ?? profil.mensurationCuisseCm,
            masseGrasse: m?.bodyFatPercentage ?? profil.masseGraisseuse,
            bmi:         bmi
        )
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.md) {

                // ── En-tête ──────────────────────────────────────────────
                HStack(alignment: .center) {
                    Label("Analyse morphologique", systemImage: "figure.arms.open")
                        .font(.nutriHeadline).foregroundStyle(.indigo)
                    Spacer()
                    scoreBadge
                }

                Divider()

                // ── Corps + légende ──────────────────────────────────────
                #if os(iOS)
                VStack(alignment: .leading, spacing: Spacing.md) {
                    BodyMorphoCanvas(analyse: analyse, sexe: profil.sexeEnum)
                        .frame(maxWidth: .infinity)
                    legendeZones
                }
                #else
                HStack(alignment: .top, spacing: Spacing.lg) {
                    BodyMorphoCanvas(analyse: analyse, sexe: profil.sexeEnum)
                        .frame(width: 90, height: 180)
                    legendeZones
                }
                #endif

                Divider()

                // ── Barre de score ───────────────────────────────────────
                scoreBar

                // ── Légende des couleurs ─────────────────────────────────
                legendeCouleurs
            }
        }
    }

    // MARK: - Sous-vues

    private var scoreBadge: some View {
        let score = analyse.scoreGlobal
        return VStack(spacing: 1) {
            Text("\(score)")
                .font(.nutriTitle2)
                .foregroundStyle(analyse.couleurScore)
            Text(analyse.labelScore)
                .font(.system(size: 9, weight: .medium)) // micro-label data viz <11pt
                .foregroundStyle(analyse.couleurScore)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(analyse.couleurScore.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: Radius.sm))
    }

    private var legendeZones: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(analyse.zones) { zone in
                zoneRow(zone)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func zoneRow(_ zone: AnalyseZone) -> some View {
        HStack(spacing: 6) {
            Image(systemName: zone.statut.icone)
                .font(.system(size: 9)) // micro-icone data viz <11pt
                .foregroundStyle(zone.statut.couleur)
                .frame(width: 12)

            Text(zone.zone.rawValue)
                .font(.nutriCaption2)
                .foregroundStyle(.primary)
                .frame(width: 85, alignment: .leading)

            Text(zone.valeurAffichee)
                .font(.nutriCaption2)
                .fontWeight(.semibold)
                .foregroundStyle(zone.statut.couleur)
                .frame(width: 48, alignment: .trailing)

            Text(zone.conseil)
                .font(.system(size: 9)) // micro-label data viz <11pt
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var scoreBar: some View {
        let score = analyse.scoreGlobal
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Score de forme globale")
                    .font(.nutriCaption).foregroundStyle(.secondary)
                Spacer()
                Text("\(score) / 100")
                    .font(.nutriCaption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(analyse.couleurScore)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 8)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [analyse.couleurScore.opacity(0.7), analyse.couleurScore],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, geo.size.width * Double(score) / 100), height: 8)
                }
            }
            .frame(height: 8)
        }
    }

    private var legendeCouleurs: some View {
        HStack(spacing: Spacing.sm) {
            ForEach([StatutZone.optimal, .attention, .exces, .insuffisant, .nonMesure], id: \.label) { s in
                HStack(spacing: 3) {
                    Circle().fill(s.couleur).frame(width: 7, height: 7)
                    Text(s.label)
                        .font(.system(size: 9)) // micro-label légende <11pt
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Canvas de silhouette colorée par zone

struct BodyMorphoCanvas: View {
    let analyse: AnalyseMorpho
    let sexe: Sexe
    var width: CGFloat = 90
    var height: CGFloat = 180

    var body: some View {
        Canvas { ctx, sz in
            drawBody(ctx: ctx, size: sz)
        }
        .frame(width: width, height: height)
    }

    // MARK: - Dessin principal

    private func drawBody(ctx: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let cx = w / 2

        // Paramètres morpho normaux (silhouette de référence)
        let shoulderHW = w * (sexe == .homme ? 0.295 : 0.258)
        let waistHW    = w * (sexe == .homme ? 0.218 : 0.185)
        let hipHW      = w * (sexe == .homme ? 0.245 : 0.305)
        let armHW      = w * (sexe == .homme ? 0.078 : 0.065)

        let headRx  = w * 0.155
        let headRy  = w * 0.178
        let headCY  = h * 0.090
        let neckHW  = w * 0.052
        let neckTop = headCY + headRy - 2
        let neckBot = neckTop + h * 0.048
        let shoulderY = neckBot
        let waistY  = h * 0.558
        let hipY    = h * 0.648
        let armTopY = shoulderY + 1
        let armBotY = h * 0.488
        let drift   = w * 0.028
        let legBot  = h * 0.988
        let legGap  = w * 0.022
        let legTopW = (hipHW - legGap) * 0.90
        let legBotW = legTopW * 0.80
        let dL = legBot - hipY

        // ── Tête (couleur IMC) ──────────────────────────────────────────
        let shadeIMC = shading(pour: .imc)
        ctx.fill(
            Path(ellipseIn: CGRect(x: cx - headRx, y: headCY - headRy,
                                   width: headRx * 2, height: headRy * 2)),
            with: shadeIMC
        )

        // ── Cou (neutre) ────────────────────────────────────────────────
        let shadeNeutre = GraphicsContext.Shading.color(Color.secondary.opacity(0.25))
        ctx.fill(
            Path(CGRect(x: cx - neckHW, y: neckTop, width: neckHW * 2, height: neckBot - neckTop)),
            with: shadeNeutre
        )

        // ── Bras gauche & droit (couleur bras) ─────────────────────────
        let shadeBras = shading(pour: .bras)
        var la = Path()
        la.move(to:    CGPoint(x: cx - shoulderHW,            y: armTopY))
        la.addLine(to: CGPoint(x: cx - shoulderHW - armHW,    y: armTopY))
        la.addLine(to: CGPoint(x: cx - shoulderHW - armHW - drift, y: armBotY))
        la.addLine(to: CGPoint(x: cx - shoulderHW - drift * 0.3,   y: armBotY))
        la.closeSubpath()
        ctx.fill(la, with: shadeBras)

        var ra = Path()
        ra.move(to:    CGPoint(x: cx + shoulderHW,            y: armTopY))
        ra.addLine(to: CGPoint(x: cx + shoulderHW + armHW,    y: armTopY))
        ra.addLine(to: CGPoint(x: cx + shoulderHW + armHW + drift, y: armBotY))
        ra.addLine(to: CGPoint(x: cx + shoulderHW + drift * 0.3,   y: armBotY))
        ra.closeSubpath()
        ctx.fill(ra, with: shadeBras)

        // ── Torse supérieur — épaules→taille (couleur poitrine) ─────────
        let shadePoitrine = shading(pour: .poitrine)
        let dV = waistY - shoulderY
        var torsoHaut = Path()
        torsoHaut.move(to: CGPoint(x: cx - shoulderHW, y: shoulderY))
        torsoHaut.addLine(to: CGPoint(x: cx + shoulderHW, y: shoulderY))
        torsoHaut.addCurve(
            to:       CGPoint(x: cx + waistHW, y: waistY),
            control1: CGPoint(x: cx + shoulderHW,     y: shoulderY + dV * 0.55),
            control2: CGPoint(x: cx + waistHW * 1.28, y: waistY - dV * 0.20)
        )
        torsoHaut.addLine(to: CGPoint(x: cx - waistHW, y: waistY))
        torsoHaut.addCurve(
            to:       CGPoint(x: cx - shoulderHW, y: shoulderY),
            control1: CGPoint(x: cx - waistHW * 1.28, y: waistY - dV * 0.20),
            control2: CGPoint(x: cx - shoulderHW,     y: shoulderY + dV * 0.55)
        )
        torsoHaut.closeSubpath()
        ctx.fill(torsoHaut, with: shadePoitrine)

        // ── Torse inférieur — taille→hanches (couleur taille/hanches) ───
        let shadeTaille  = shading(pour: .taille)
        let shadeHanches = shading(pour: .hanches)
        // Mélange visuel : on dessine la zone taille en premier, puis hanches par-dessus
        let dH = hipY - waistY
        var torsoBase = Path()
        torsoBase.move(to: CGPoint(x: cx - waistHW, y: waistY))
        torsoBase.addLine(to: CGPoint(x: cx + waistHW, y: waistY))
        torsoBase.addCurve(
            to:       CGPoint(x: cx + hipHW, y: hipY),
            control1: CGPoint(x: cx + waistHW * 1.10, y: waistY + dH * 0.35),
            control2: CGPoint(x: cx + hipHW,           y: hipY - dH * 0.25)
        )
        torsoBase.addLine(to: CGPoint(x: cx - hipHW, y: hipY))
        torsoBase.addCurve(
            to:       CGPoint(x: cx - waistHW, y: waistY),
            control1: CGPoint(x: cx - hipHW,           y: hipY - dH * 0.25),
            control2: CGPoint(x: cx - waistHW * 1.10, y: waistY + dH * 0.35)
        )
        torsoBase.closeSubpath()

        // Zone taille : moitié supérieure de la région ventre→hanche
        let shadeMixTaille: GraphicsContext.Shading
        let shadeMixHanches: GraphicsContext.Shading

        // Utilise le dégradé taille pour le haut, hanches pour le bas
        shadeMixTaille  = shadeTaille
        shadeMixHanches = shadeHanches

        // On dessine en deux passes (haut = taille, bas = hanches) via clip
        ctx.drawLayer { inner in
            inner.clip(to: Path(CGRect(x: 0, y: waistY, width: w, height: (hipY - waistY) / 2)))
            inner.fill(torsoBase, with: shadeMixTaille)
        }
        ctx.drawLayer { inner in
            inner.clip(to: Path(CGRect(x: 0, y: waistY + (hipY - waistY) / 2,
                                       width: w, height: (hipY - waistY) / 2 + 2)))
            inner.fill(torsoBase, with: shadeMixHanches)
        }

        // ── Jambes (couleur cuisse) ──────────────────────────────────────
        let shadeCuisse = shading(pour: .cuisse)

        var ll = Path()
        ll.move(to: CGPoint(x: cx - legGap,                y: hipY))
        ll.addLine(to: CGPoint(x: cx - legGap - legTopW * 2, y: hipY))
        ll.addCurve(
            to:       CGPoint(x: cx - legGap - legBotW * 2, y: legBot),
            control1: CGPoint(x: cx - legGap - legTopW * 2 - w * 0.016, y: hipY + dL * 0.40),
            control2: CGPoint(x: cx - legGap - legBotW * 2,              y: legBot - dL * 0.30)
        )
        ll.addLine(to: CGPoint(x: cx - legGap, y: legBot))
        ll.closeSubpath()
        ctx.fill(ll, with: shadeCuisse)

        var rl = Path()
        rl.move(to: CGPoint(x: cx + legGap,                y: hipY))
        rl.addLine(to: CGPoint(x: cx + legGap + legTopW * 2, y: hipY))
        rl.addCurve(
            to:       CGPoint(x: cx + legGap + legBotW * 2, y: legBot),
            control1: CGPoint(x: cx + legGap + legTopW * 2 + w * 0.016, y: hipY + dL * 0.40),
            control2: CGPoint(x: cx + legGap + legBotW * 2,              y: legBot - dL * 0.30)
        )
        rl.addLine(to: CGPoint(x: cx + legGap, y: legBot))
        rl.closeSubpath()
        ctx.fill(rl, with: shadeCuisse)

        // ── Contour subtil sur la tête (masse grasse) ────────────────────
        // Petit badge masse grasse dans la tête (cercle légèrement teinté)
        let mgStatut = analyse.statut(pour: .masseGrasse)
        if mgStatut != .nonMesure && mgStatut != .optimal {
            let mgColor = mgStatut.couleur.opacity(0.30)
            ctx.fill(
                Path(ellipseIn: CGRect(x: cx - headRx * 0.55, y: headCY - headRy * 0.55,
                                       width: headRx * 1.10, height: headRy * 1.10)),
                with: .color(mgColor)
            )
        }
    }

    // MARK: - Helper couleur

    private func shading(pour zone: ZoneCorporelle) -> GraphicsContext.Shading {
        .color(analyse.statut(pour: zone).couleur.opacity(0.80))
    }
}

// MARK: - Preview

private func previewProfil(sexe: String, taille: Double, poids: Double,
                            waist: Double, hips: Double, chest: Double,
                            arm: Double, thigh: Double, mg: Double) -> UserProfile {
    let p = UserProfile(prenom: "Test", sexe: sexe, taille: taille,
                        objectifPoids: poids - 5, niveauActivite: "modere")
    p.poidsActuel            = poids
    p.silhouetteObjectif     = "normal"
    p.mensurationTailleCm    = waist
    p.mensurationHanchesCm   = hips
    p.mensurationPoitrineCm  = chest
    p.mensurationBrasDroitCm = arm
    p.mensurationCuisseCm    = thigh
    p.masseGraisseuse        = mg
    return p
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            BodyMorphoView(
                profil: previewProfil(sexe: "homme", taille: 178, poids: 78,
                                      waist: 85, hips: 95, chest: 98,
                                      arm: 34, thigh: 56, mg: 18),
                metric: nil
            )

            HStack(spacing: 24) {
                VStack {
                    BodyMorphoCanvas(analyse: MorphoCalculator.analyser(
                        taille: 178, sexe: "homme", poids: 78,
                        waist: 85, hips: 95, chest: 98, arm: 34, thigh: 56,
                        masseGrasse: 18,
                        bmi: NutritionCalculator.imc(poids: 78, taille: 178)
                    ), sexe: .homme, width: 80, height: 160)
                    Text("Homme normal").font(.caption2)
                }
                VStack {
                    BodyMorphoCanvas(analyse: MorphoCalculator.analyser(
                        taille: 165, sexe: "femme", poids: 70,
                        waist: 90, hips: 100, chest: 88, arm: 30, thigh: 65,
                        masseGrasse: 32,
                        bmi: NutritionCalculator.imc(poids: 70, taille: 165)
                    ), sexe: .femme, width: 80, height: 160)
                    Text("Femme surpoids").font(.caption2)
                }
            }
        }
        .padding()
    }
    .background(Color.fondPrincipal)
}
