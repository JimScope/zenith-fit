// DataManager.swift (Corregido)
import Foundation

// CORREGIDO: Marcamos toda la clase para que se ejecute en el Main Actor.
// Esto resuelve todos los problemas de concurrencia al llamar a AssetManager.
@MainActor
class DataManager {
    static let shared = DataManager()
    private let assetManager = AssetManager.shared

    private(set) var workoutPlans: [String: [WeeklyPlan]] = [:]
    private(set) var definitions: [Definition] = []
    private(set) var descriptions: [String: String] = [:]
    
    private init() {
        reloadData()
    }

    func reloadData() {
        // Ahora las llamadas a assetManager son seguras.
        workoutPlans = load(from: assetManager.getURL(for: "workouts.json")) ?? [:]
        definitions = load(from: assetManager.getURL(for: "definitions.json")) ?? []
        descriptions = load(from: assetManager.getURL(for: "descriptions.json")) ?? [:]
    }

    func plan(for hero: String) -> [WeeklyPlan] {
        return workoutPlans[hero] ?? []
    }
    
    func getAvailableHeroes() -> [String] {
        return workoutPlans.keys.sorted()
    }

    private func load<T: Decodable>(from url: URL) -> T? {
        do {
            let data = try Data(contentsOf: url)
            let decodedData = try JSONDecoder().decode(T.self, from: data)
            return decodedData
        } catch {
            print("Failed to load or decode file from \(url): \(error)")
            return nil
        }
    }
}
