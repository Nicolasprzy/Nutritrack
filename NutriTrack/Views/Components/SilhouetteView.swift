import SwiftUI

// MARK: - Paramètres de silhouette

struct BodyParams {
    let shoulderHW: CGFloat   // demi-largeur épaules (fraction de la largeur)
    let waistHW: CGFloat      // demi-largeur taille
    let hipHW: CGFloat        // demi-largeur hanches
    let armHW: CGFloat        // demi-largeur bras

    static func forType(_ objectif: SilhouetteObjectif, sexe: Sexe) -> BodyParams {
        switch sexe {
        case .homme:
            switch objectif {
            case .tresMince: return BodyParams(shoulderHW: 0.210, waistHW: 0.155, hipHW: 0.175, armHW: 0.042)
            case .mince:     return BodyParams(shoulderHW: 0.260, waistHW: 0.190, hipHW: 0.210, armHW: 0.062)
            case .tonique:   return BodyParams(shoulderHW: 0.365, waistHW: 0.210, hipHW: 0.240, armHW: 0.092)
            case .normal:    return BodyParams(shoulderHW: 0.295, waistHW: 0.250, hipHW: 0.260, armHW: 0.082)
            case .surpoids:  return BodyParams(shoulderHW: 0.305, waistHW: 0.330, hipHW: 0.318, armHW: 0.098) // ventre débordant
            case .obese:     return BodyParams(shoulderHW: 0.318, waistHW: 0.415, hipHW: 0.392, armHW: 0.122) // silhouette arrondie prononcée
            }
        case .femme:
            switch objectif {
            case .tresMince: return BodyParams(shoulderHW: 0.188, waistHW: 0.128, hipHW: 0.185, armHW: 0.036)
            case .mince:     return BodyParams(shoulderHW: 0.228, waistHW: 0.158, hipHW: 0.248, armHW: 0.052)
            case .tonique:   return BodyParams(shoulderHW: 0.278, waistHW: 0.178, hipHW: 0.295, armHW: 0.068)
            case .normal:    return BodyParams(shoulderHW: 0.258, waistHW: 0.208, hipHW: 0.318, armHW: 0.068)
            case .surpoids:  return BodyParams(shoulderHW: 0.268, waistHW: 0.288, hipHW: 0.385, armHW: 0.088) // hanches & ventre larges
            case .obese:     return BodyParams(shoulderHW: 0.285, waistHW: 0.368, hipHW: 0.448, armHW: 0.112) // silhouette très ronde
            }
        }
    }
}

// MARK: - Vue silhouette

struct SilhouetteView: View {
    let objectif: SilhouetteObjectif
    let sexe: Sexe
    var isSelected: Bool = false
    var width: CGFloat = 52
    var height: CGFloat = 108

    private var accentColor: Color {
        isSelected ? Color.nutriGreen : Color.secondary.opacity(0.60)
    }

    var body: some View {
        ZStack {
            if isSelected {
                Canvas { ctx, sz in drawSilhouette(ctx: ctx, size: sz) }
                    .frame(width: width, height: height)
                    .blur(radius: 7)
                    .opacity(0.40)
            }
            Canvas { ctx, sz in drawSilhouette(ctx: ctx, size: sz) }
                .frame(width: width, height: height)
        }
        .animation(.easeInOut(duration: 0.25), value: isSelected)
    }

    // MARK: - Dessin Canvas

    private func drawSilhouette(ctx: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let cx = w / 2
        let shade = GraphicsContext.Shading.color(accentColor)
        let p = BodyParams.forType(objectif, sexe: sexe)

        // ── Tête ──
        let headRx = w * 0.155
        let headRy = w * 0.178
        let headCY = h * 0.090
        ctx.fill(
            Path(ellipseIn: CGRect(
                x: cx - headRx, y: headCY - headRy,
                width: headRx * 2, height: headRy * 2
            )),
            with: shade
        )

        // ── Cou ──
        let neckHW = w * 0.052
        let neckTop = headCY + headRy - 2
        let neckBot = neckTop + h * 0.050
        ctx.fill(
            Path(CGRect(x: cx - neckHW, y: neckTop, width: neckHW * 2, height: neckBot - neckTop)),
            with: shade
        )

        // Layout
        let shoulderY = neckBot
        let shoulderHW = w * p.shoulderHW
        let waistY = h * 0.558
        let waistHW = w * p.waistHW
        let hipY = h * 0.648
        let hipHW = w * p.hipHW
        let armHW = w * p.armHW
        let armTopY = shoulderY + 1
        let armBotY = h * 0.488
        let drift = w * 0.030

        // ── Bras gauche ──
        var la = Path()
        la.move(to:    CGPoint(x: cx - shoulderHW,           y: armTopY))
        la.addLine(to: CGPoint(x: cx - shoulderHW - armHW,   y: armTopY))
        la.addLine(to: CGPoint(x: cx - shoulderHW - armHW - drift, y: armBotY))
        la.addLine(to: CGPoint(x: cx - shoulderHW - drift * 0.3, y: armBotY))
        la.closeSubpath()
        ctx.fill(la, with: shade)

        // ── Bras droit ──
        var ra = Path()
        ra.move(to:    CGPoint(x: cx + shoulderHW,           y: armTopY))
        ra.addLine(to: CGPoint(x: cx + shoulderHW + armHW,   y: armTopY))
        ra.addLine(to: CGPoint(x: cx + shoulderHW + armHW + drift, y: armBotY))
        ra.addLine(to: CGPoint(x: cx + shoulderHW + drift * 0.3,   y: armBotY))
        ra.closeSubpath()
        ctx.fill(ra, with: shade)

        // ── Torse ──
        let dV = waistY - shoulderY
        let dH = hipY - waistY
        var torso = Path()
        torso.move(to: CGPoint(x: cx - shoulderHW, y: shoulderY))
        torso.addLine(to: CGPoint(x: cx + shoulderHW, y: shoulderY))
        torso.addCurve(
            to:       CGPoint(x: cx + waistHW, y: waistY),
            control1: CGPoint(x: cx + shoulderHW,     y: shoulderY + dV * 0.55),
            control2: CGPoint(x: cx + waistHW * 1.28, y: waistY - dV * 0.20)
        )
        torso.addCurve(
            to:       CGPoint(x: cx + hipHW, y: hipY),
            control1: CGPoint(x: cx + waistHW * 1.10, y: waistY + dH * 0.35),
            control2: CGPoint(x: cx + hipHW,           y: hipY - dH * 0.25)
        )
        torso.addLine(to: CGPoint(x: cx - hipHW, y: hipY))
        torso.addCurve(
            to:       CGPoint(x: cx - waistHW, y: waistY),
            control1: CGPoint(x: cx - hipHW,           y: hipY - dH * 0.25),
            control2: CGPoint(x: cx - waistHW * 1.10, y: waistY + dH * 0.35)
        )
        torso.addCurve(
            to:       CGPoint(x: cx - shoulderHW, y: shoulderY),
            control1: CGPoint(x: cx - waistHW * 1.28, y: waistY - dV * 0.20),
            control2: CGPoint(x: cx - shoulderHW,     y: shoulderY + dV * 0.55)
        )
        torso.closeSubpath()
        ctx.fill(torso, with: shade)

        // ── Jambes ──
        let legBot  = h * 0.988
        let legGap  = w * 0.024
        let legTopW = (hipHW - legGap) * 0.90
        let legBotW = legTopW * 0.80
        let dL = legBot - hipY

        // Jambe gauche
        var ll = Path()
        ll.move(to: CGPoint(x: cx - legGap,              y: hipY))
        ll.addLine(to: CGPoint(x: cx - legGap - legTopW * 2, y: hipY))
        ll.addCurve(
            to:       CGPoint(x: cx - legGap - legBotW * 2, y: legBot),
            control1: CGPoint(x: cx - legGap - legTopW * 2 - w * 0.018, y: hipY + dL * 0.40),
            control2: CGPoint(x: cx - legGap - legBotW * 2,              y: legBot - dL * 0.30)
        )
        ll.addLine(to: CGPoint(x: cx - legGap, y: legBot))
        ll.closeSubpath()
        ctx.fill(ll, with: shade)

        // Jambe droite
        var rl = Path()
        rl.move(to: CGPoint(x: cx + legGap,              y: hipY))
        rl.addLine(to: CGPoint(x: cx + legGap + legTopW * 2, y: hipY))
        rl.addCurve(
            to:       CGPoint(x: cx + legGap + legBotW * 2, y: legBot),
            control1: CGPoint(x: cx + legGap + legTopW * 2 + w * 0.018, y: hipY + dL * 0.40),
            control2: CGPoint(x: cx + legGap + legBotW * 2,              y: legBot - dL * 0.30)
        )
        rl.addLine(to: CGPoint(x: cx + legGap, y: legBot))
        rl.closeSubpath()
        ctx.fill(rl, with: shade)
    }
}

// MARK: - Sélecteur de silhouette

struct SilhouettePicker: View {
    let sexe: Sexe
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(SilhouetteObjectif.allCases, id: \.self) { type in
                let selected = selection == type.rawValue
                Button(action: { withAnimation(.spring(duration: 0.3)) { selection = type.rawValue } }) {
                    VStack(spacing: 6) {
                        SilhouetteView(
                            objectif: type,
                            sexe: sexe,
                            isSelected: selected
                        )

                        Text(type.label(sexe: sexe))
                            .font(.system(size: 9, weight: selected ? .semibold : .regular, design: .rounded)) // micro-label silhouette — <11pt donc hors tokens
                            .foregroundStyle(selected ? Color.nutriGreen : Color.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(height: 26)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(selected
                                  ? Color.nutriGreen.opacity(0.12)
                                  : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview("Homme") {
    HStack(spacing: 8) {
        ForEach(SilhouetteObjectif.allCases, id: \.self) { type in
            VStack {
                SilhouetteView(objectif: type, sexe: .homme, isSelected: type == .normal)
                Text(type.label(sexe: .homme)).font(.caption2)
            }
        }
    }
    .padding()
}

#Preview("Femme") {
    HStack(spacing: 8) {
        ForEach(SilhouetteObjectif.allCases, id: \.self) { type in
            VStack {
                SilhouetteView(objectif: type, sexe: .femme, isSelected: type == .tonique)
                Text(type.label(sexe: .femme)).font(.caption2)
            }
        }
    }
    .padding()
}
