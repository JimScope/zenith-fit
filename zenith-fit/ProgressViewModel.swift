// ProgressViewModel.swift (Corregido y Dinámico)

import SwiftUI
import Combine

class ProgressViewModel: ObservableObject {
    @Published var progress: [String: Int] = [:]

    // Esta propiedad almacenará el nombre del héroe activo. Es privada.
    private var activeHero: String = ""
    private var cancellables = Set<AnyCancellable>()

    init() {
        // El inicializador ahora solo configura el guardado automático.
        // Ya no carga el progreso aquí, porque aún no sabe qué héroe está activo.
        $progress
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] newProgress in
                // Solo guarda si hay un héroe activo.
                guard let self = self, !self.activeHero.isEmpty else { return }
                self.saveProgress(newProgress)
            }
            .store(in: &cancellables)
    }

    // --- MÉTODOS PÚBLICOS DE GESTIÓN ---

    // NUEVO: Este es el método clave. La vista llamará a esto para decirle al ViewModel qué héroe está activo.
    func setActiveHero(_ hero: String) {
        // Evita recargas innecesarias si el héroe no ha cambiado.
        guard hero != self.activeHero, !hero.isEmpty else { return }
        
        // Actualiza el héroe activo.
        self.activeHero = hero
        
        // Carga el progreso para este nuevo héroe.
        self.loadProgress()
    }
    
    // Obtiene el progreso para un ejercicio (sin cambios en la lógica interna).
    func getProgress(for workout: Workout, in week: Int) -> Int {
        return progress[key(for: workout.name, week: week)] ?? 0
    }

    // Actualiza el progreso para un ejercicio (sin cambios en la lógica interna).
    func updateProgress(for workout: Workout, in week: Int, value: Int) {
        let progressKey = key(for: workout.name, week: week)
        progress[progressKey] = max(0, value)
    }

    // Resetea el progreso DEL HÉROE ACTUAL.
    func resetProgress() {
        progress = [:]
        // Solo borra de UserDefaults si hay un héroe activo.
        guard !activeHero.isEmpty else { return }
        UserDefaults.standard.removeObject(forKey: getProgressKey())
    }

    // --- MÉTODOS PRIVADOS DE PERSISTENCIA ---

    // NUEVO: Genera una clave de UserDefaults única para el héroe activo.
    private func getProgressKey() -> String {
        return "progress_\(activeHero)"
    }
    
    // Genera la clave para un ejercicio dentro del diccionario de progreso (sin cambios).
    private func key(for workoutName: String, week: Int) -> String {
        return "w\(week)_\(workoutName)"
    }

    // Carga el progreso usando la clave dinámica.
    private func loadProgress() {
        guard !activeHero.isEmpty else {
            self.progress = [:]
            return
        }
        
        let key = getProgressKey()
        if let data = UserDefaults.standard.data(forKey: key) {
            if let decodedProgress = try? JSONDecoder().decode([String: Int].self, from: data) {
                self.progress = decodedProgress
                return
            }
        }
        // Si no hay datos guardados para este héroe, el progreso es un diccionario vacío.
        self.progress = [:]
    }

    // Guarda el progreso usando la clave dinámica.
    private func saveProgress(_ newProgress: [String: Int]) {
        let key = getProgressKey()
        if let data = try? JSONEncoder().encode(newProgress) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

// Re-añado la lógica de percentComplete para que el archivo esté completo.
extension ProgressViewModel {
    func percentComplete(for plan: WeeklyPlan) -> Double {
        let totalReps = plan.workouts.reduce(0) { $0 + $1.reps }
        guard totalReps > 0 else { return 0.0 }

        let completedReps = plan.workouts.reduce(0) {
            $0 + getProgress(for: $1, in: plan.week)
        }

        return min(1.0, Double(completedReps) / Double(totalReps))
    }
}
