import Foundation

struct HealthDay: Codable, Identifiable {
    let date: String
    let steps: Int
    let dietaryEnergyKcal: Double
    let proteinG: Double
    let carbsG: Double
    let fatG: Double

    var id: String { date }
    var hasNutrition: Bool {
        dietaryEnergyKcal > 0 || proteinG > 0 || carbsG > 0 || fatG > 0
    }

    enum CodingKeys: String, CodingKey {
        case date
        case steps
        case dietaryEnergyKcal = "dietary_energy_kcal"
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
    }
}

struct HealthSyncPayload: Codable {
    let source: String
    let timezone: String
    let days: [HealthDay]
}

struct HealthSyncResponse: Decodable {
    let ok: Bool
    let rows: Int?
    let error: String?
}
