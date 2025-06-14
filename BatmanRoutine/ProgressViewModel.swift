// ProgressViewModel.swift
import SwiftUI
import Combine

class ProgressViewModel: ObservableObject {
    @Published var progress: [String: Int] = [:]

    private let progressKey = "batmanProgress"
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadProgress()
        
        // Guarda el progreso automáticamente cada vez que cambia
        $progress
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main) // Evita escrituras excesivas
            .sink { [weak self] newProgress in
                self?.saveProgress(newProgress)
            }
            .store(in: &cancellables)
    }

    // Genera la clave única para un ejercicio en una semana específica
    private func key(for workoutName: String, week: Int) -> String {
        return "w\(week)_\(workoutName)"
    }
    
    // Obtiene el progreso para un ejercicio
    func getProgress(for workout: Workout, in week: Int) -> Int {
        return progress[key(for: workout.name, week: week)] ?? 0
    }

    // Actualiza el progreso para un ejercicio
    func updateProgress(for workout: Workout, in week: Int, value: Int) {
        let progressKey = key(for: workout.name, week: week)
        progress[progressKey] = max(0, value)
    }

    // Calcula el porcentaje completado para la semana actual
    func percentComplete(for plan: WeeklyPlan) -> Double {
        let totalReps = plan.workouts.reduce(0) { $0 + $1.reps }
        guard totalReps > 0 else { return 0.0 }

        let completedReps = plan.workouts.reduce(0) {
            $0 + getProgress(for: $1, in: plan.week)
        }

        return min(1.0, Double(completedReps) / Double(totalReps))
    }

    // Carga el progreso desde UserDefaults
    private func loadProgress() {
        if let data = UserDefaults.standard.data(forKey: progressKey) {
            if let decodedProgress = try? JSONDecoder().decode([String: Int].self, from: data) {
                self.progress = decodedProgress
                return
            }
        }
        self.progress = [:]
    }

    // Guarda el progreso en UserDefaults
    private func saveProgress(_ newProgress: [String: Int]) {
        if let data = try? JSONEncoder().encode(newProgress) {
            UserDefaults.standard.set(data, forKey: progressKey)
        }
    }
    
    // Resetar el progreso
    func resetProgress() {
        // Borra el diccionario de progreso en memoria
        progress = [:]
        
        // Elimina el progreso guardado en UserDefaults
        UserDefaults.standard.removeObject(forKey: progressKey)
    }
}
