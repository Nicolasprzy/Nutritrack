import Foundation

struct PlanSemaineTypeModel: Codable {
    let title: String
    let subtitle: String
    let targets: Targets
    let petitDejeuner: Repas
    let dejeuners: [RepasRotation]
    let collationPostEntrainement: Repas
    let diners: [RepasRotation]
    let weekEnd: WeekEnd

    struct Targets: Codable {
        let kcal: Double
        let proteines_g: Double
        let glucides_g: Double
        let lipides_g: Double
    }

    struct Macros: Codable {
        let kcal: Double
        let proteines_g: Double
        let glucides_g: Double
        let lipides_g: Double
    }

    struct Repas: Codable {
        let titre: String
        let items: [String]
        let macros: Macros
    }

    struct RepasRotation: Codable {
        let jours: [String]
        let titre: String
        let items: [String]
        let macros: Macros
    }

    struct WeekEnd: Codable {
        let note: String
    }

    static func charger() -> PlanSemaineTypeModel? {
        guard let url = Bundle.main.url(forResource: "plan_semaine_type", withExtension: "json") else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(PlanSemaineTypeModel.self, from: data)
        } catch {
            print("Erreur chargement plan_semaine_type.json : \(error)")
            return nil
        }
    }
}
