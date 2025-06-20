// Models.swift
import Foundation

// Corresponde a definitions.json
struct Definition: Codable, Identifiable, Hashable {
    var id: String { term }
    let term: String
    let definition: String
}

// Corresponde a un objeto dentro del array de plan.json
struct WeeklyPlan: Codable, Identifiable {
    var id: Int { week }
    let week: Int
    let phase: String
    let workouts: [Workout]
    let diet: Diet
}

struct Workout: Codable, Identifiable, Hashable {
    var id: String { name }
    let name: String
    let reps: Int
}

struct Diet: Codable, Hashable {
    let calories: Int
    let protein: Double
    let carbs: Double
    let fats: Double
}
