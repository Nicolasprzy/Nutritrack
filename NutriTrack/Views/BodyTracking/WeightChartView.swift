import SwiftUI
import Charts

struct WeightChartView: View {
    let donnees: [(date: Date, poids: Double)]
    var showArea: Bool = true

    private var minPoids: Double {
        (donnees.min(by: { $0.poids < $1.poids })?.poids ?? 60) - 2
    }

    private var maxPoids: Double {
        (donnees.max(by: { $0.poids < $1.poids })?.poids ?? 80) + 2
    }

    var body: some View {
        if donnees.isEmpty {
            ContentUnavailableView(
                "Aucune donnée",
                systemImage: "chart.line.uptrend.xyaxis",
                description: Text("Ajoutez votre première mesure.")
            )
            .frame(height: 200)
        } else {
            Chart(donnees, id: \.date) { point in
                if showArea {
                    AreaMark(
                        x: .value("Date", point.date),
                        yStart: .value("Bas", minPoids),
                        yEnd: .value("Poids", point.poids)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue.opacity(0.4), .blue.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }

                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Poids", point.poids)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 2.5))

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Poids", point.poids)
                )
                .foregroundStyle(.blue)
                .symbolSize(30)
            }
            .chartYScale(domain: minPoids...maxPoids)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: donnees.count > 30 ? 7 : 3)) { value in
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("\(v.arrondi(1)) kg")
                                .font(.caption2)
                        }
                    }
                    AxisGridLine()
                }
            }
            .frame(height: 200)
            .animation(.easeInOut(duration: 0.5), value: donnees.count)
        }
    }
}

// MARK: - Mini graphique (pour la grille 2x2)

struct MiniChartView: View {
    let titre: String
    let donnees: [(date: Date, valeur: Double)]
    let couleur: Color
    let unite: String

    var body: some View {
        GlassCard(padding: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(titre)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if donnees.isEmpty {
                    Text("—")
                        .font(.nutriTitle2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                } else {
                    Text("\(donnees.last!.valeur.arrondi(1)) \(unite)")
                        .font(.nutriTitle2)
                        .foregroundStyle(couleur)

                    Chart(donnees, id: \.date) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Valeur", point.valeur)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(couleur)
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .frame(height: 50)
                }
            }
        }
    }
}

#Preview {
    let donnees: [(date: Date, poids: Double)] = (0..<30).map { i in
        let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
        let poids = 82.0 - Double(i) * 0.08 + Double.random(in: -0.3...0.3)
        return (date: date, poids: poids)
    }.reversed()

    return WeightChartView(donnees: donnees)
        .padding()
}
