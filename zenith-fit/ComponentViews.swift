// ComponentViews.swift (Versión Final Corregida)

import SwiftUI
import Charts

// MARK: - Vistas de Detalle

struct RouteView: View {
    @Binding var weekIndex: Int
    @ObservedObject var progressVM: ProgressViewModel
    let title: String
    let fullPlan: [WeeklyPlan]
    
    private var currentPlan: WeeklyPlan {
        guard weekIndex < fullPlan.count else {
            return WeeklyPlan(week: 0, phase: "Error", workouts: [], diet: Diet(calories: 0, protein: 0, carbs: 0, fats: 0))
        }
        return fullPlan[weekIndex]
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(currentPlan.workouts) { workout in
                    let progressBinding = Binding<Int>(
                        get: { progressVM.getProgress(for: workout, in: currentPlan.week) },
                        set: { progressVM.updateProgress(for: workout, in: currentPlan.week, value: $0) }
                    )
                    GroupBox {
                        ExerciseItemView(
                            workout: workout,
                            // CORREGIDO: El typo 'curren' ha sido reemplazado por 'DataManager.shared'.
                            description: DataManager.shared.descriptions[workout.name] ?? "Sin descripción.",
                            completedReps: progressBinding
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItemGroup {
                Button("Anterior", systemImage: "arrow.left") { weekIndex -= 1 }
                    .disabled(weekIndex <= 0)
                
                VStack {
                    ProgressView(value: progressVM.percentComplete(for: currentPlan))
                    Text("\(Int(progressVM.percentComplete(for: currentPlan) * 100))%")
                        .font(.caption.bold())
                }.frame(width: 50)
                
                Button("Siguiente", systemImage: "arrow.right") { weekIndex += 1 }
                    .disabled(weekIndex >= fullPlan.count - 1)
            }
        }
    }
}

struct DefinitionsView: View {
    private let definitions = DataManager.shared.definitions
    private let columns = [GridItem(.adaptive(minimum: 350), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(definitions) { definition in
                    GroupBox {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(definition.term)
                                .font(.headline)
                            Text(definition.definition)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Definiciones")
    }
}

struct ChartsView: View {
    @ObservedObject var progressVM: ProgressViewModel
    let selectedHero: String // <-- CORREGIDO: Recibe el héroe actual

    private let allExercises: [String]
    @State private var selectedExercise: String
    
    private struct ExerciseProgressPoint: Identifiable {
        var id: Int { week }
        let week: Int
        let completedReps: Int
        let plannedReps: Int
    }
    
    private struct WeeklyVolume: Identifiable {
        var id: Int { week }
        let week: Int
        let totalReps: Int
    }

    // CORREGIDO: El inicializador ahora acepta el héroe seleccionado.
    init(progressVM: ProgressViewModel, selectedHero: String) {
        self.progressVM = progressVM
        self.selectedHero = selectedHero
        
        // CORREGIDO: Obtiene el plan para el héroe específico.
        let heroPlan = DataManager.shared.plan(for: selectedHero)
        let allWorkoutNames = heroPlan.flatMap { $0.workouts.map { $0.name } }
        let uniqueNames = Array(Set(allWorkoutNames)).sorted()
        
        self.allExercises = uniqueNames
        self._selectedExercise = State(initialValue: uniqueNames.first ?? "")
    }

    private var progressChartData: [ExerciseProgressPoint] {
        // CORREGIDO: Usa el plan del héroe específico.
        DataManager.shared.plan(for: selectedHero).compactMap { weekPlan in
            if let workout = weekPlan.workouts.first(where: { $0.name == selectedExercise }) {
                let completed = progressVM.getProgress(for: workout, in: weekPlan.week)
                return ExerciseProgressPoint(
                    week: weekPlan.week,
                    completedReps: completed,
                    plannedReps: workout.reps
                )
            }
            return nil
        }
    }
    
    private var volumeChartData: [WeeklyVolume] {
        // CORREGIDO: Usa el plan del héroe específico.
        DataManager.shared.plan(for: selectedHero).map { weekPlan in
            let totalCompletedReps = weekPlan.workouts.reduce(0) { sum, workout in
                sum + progressVM.getProgress(for: workout, in: weekPlan.week)
            }
            return WeeklyVolume(week: weekPlan.week, totalReps: totalCompletedReps)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GroupBox {
                    VStack(alignment: .leading) {
                        Text("Progreso por Ejercicio").font(.title3).bold()
                        Picker("Selecciona un ejercicio:", selection: $selectedExercise) {
                            ForEach(allExercises, id: \.self) { exerciseName in
                                Text(exerciseName).tag(exerciseName)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.bottom, 10)
                        
                        Chart(progressChartData) { dataPoint in
                            LineMark(
                                x: .value("Semana", dataPoint.week),
                                y: .value("Completadas", dataPoint.completedReps)
                            )
                            .foregroundStyle(by: .value("Tipo", "Completadas"))
                            .symbol(by: .value("Tipo", "Completadas"))

                            LineMark(
                                x: .value("Semana", dataPoint.week),
                                y: .value("Planeadas", dataPoint.plannedReps)
                            )
                            .foregroundStyle(by: .value("Tipo", "Planeadas"))
                            .symbol(by: .value("Tipo", "Planeadas"))
                            .lineStyle(StrokeStyle(dash: [5, 5]))
                        }
                        .chartForegroundStyleScale(["Completadas": .blue, "Planeadas": .gray])
                        .frame(height: 250)
                    }
                }
                
                GroupBox {
                    VStack(alignment: .leading) {
                        Text("Volumen Semanal Total (Reps Completadas)").font(.title3).bold()
                        Chart(volumeChartData) { dataPoint in
                            BarMark(
                                x: .value("Semana", dataPoint.week),
                                y: .value("Total Reps", dataPoint.totalReps)
                            )
                            .foregroundStyle(.green.gradient)
                        }
                        .frame(height: 250)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Gráficas de Progreso")
    }
}

// MARK: - Componentes Reutilizables

struct ExerciseItemView: View {
    let workout: Workout
    let description: String
    @Binding var completedReps: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading) {
                Text(workout.name).font(.headline)
                Text("Objetivo: \(workout.reps) reps").font(.subheadline).foregroundStyle(.secondary)
            }
            
            if !description.isEmpty {
                Text(description).font(.callout).foregroundStyle(.secondary).lineLimit(2)
            }
            
            Divider()
            
            HStack {
                Text("Progreso:").font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 15) {
                    Button(action: { if completedReps > 0 { completedReps -= 1 } }) {
                        Image(systemName: "minus.circle.fill")
                    }
                    Text("\(completedReps)").font(.title3.bold().monospacedDigit()).frame(minWidth: 35)
                    Button(action: { completedReps += 1 }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
                .font(.title2)
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
            }
        }
    }
}

struct SettingsView: View {
    @ObservedObject var progressVM: ProgressViewModel
    @AppStorage("selectedHero") private var selectedHero: String = ""

    // CORREGIDO: El @StateObject se declara aquí, como propiedad de la vista.
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    @StateObject private var assetManager = AssetManager.shared
    
    @State private var showingResetAlert = false
    private let availableHeroes = DataManager.shared.getAvailableHeroes()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GroupBox {
                    VStack(alignment: .leading) {
                        Text("Actualización de Contenido").font(.title3).bold()
                        Divider()

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Comprueba si hay nuevos planes o actualizaciones.")
                                switch assetManager.downloadState {
                                case .idle:
                                    Text("Estado: Listo").font(.caption).foregroundStyle(.secondary)
                                case .downloadingJSON:
                                    Text("Estado: Descargando Planes...").font(.caption).foregroundStyle(.blue)
                                case .downloadingImages:
                                    Text("Descargando imágenes...").font(.caption).foregroundStyle(.blue)
                                case .finished:
                                    Text("Estado: Contenido actualizado").font(.caption).foregroundStyle(.green)
                                case .error(let msg):
                                    Text("Estado: Error - \(msg)").font(.caption).foregroundStyle(.red)
                                }
                            }
                            Spacer()
                            Button("Actualizar") {
                                assetManager.updateAssets()
                            }
                            .disabled(assetManager.downloadState == .downloadingJSON && assetManager.downloadState == .downloadingImages)
                        }
                    }
                }
                GroupBox {
                    VStack(alignment: .leading) {
                        Text("Plan de Entrenamiento").font(.title3).bold()
                        Divider()
                        Picker("Héroe Actual:", selection: $selectedHero) {
                            ForEach(availableHeroes, id: \.self) { hero in
                                Text(hero).tag(hero)
                            }
                        }
                        Text("Aviso: Cambiar el plan de entrenamiento reiniciará todo tu progreso y estadísticas actuales.").font(.caption).foregroundStyle(.secondary).padding(.top, 5)
                    }
                }
                
                GroupBox {
                    VStack(alignment: .leading) {
                        Text("Gestión de Datos").font(.title3).bold()
                        Divider()
                        Text("Esta acción eliminará permanentemente todo tu progreso registrado en los entrenamientos. Las estadísticas en las gráficas también se reiniciarán. Esta acción no se puede deshacer.").font(.callout).foregroundStyle(.secondary).padding(.vertical, 5)
                        Button("Reiniciar Progreso y Estadísticas", role: .destructive) {
                            showingResetAlert = true
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                
                GroupBox {
                    VStack(alignment: .leading) {
                        Text("Opciones de Depuración")
                            .font(.title3.bold())
                        Divider()
                        
                        Text("Esta opción forzará a que la pantalla de bienvenida se muestre la próxima vez que la app se reinicie, o inmediatamente si es posible.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 5)
                        
                        Button("Reiniciar Bienvenida") {
                            // La acción es simple: ponemos la bandera en false.
                            hasCompletedOnboarding = false
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                
                GroupBox {
                    VStack(alignment: .leading) {
                        Text("Acerca de").font(.title3).bold()
                        Divider()
                        HStack {
                            Text("Versión de la App")
                            Spacer()
                            Text("1.0.0").foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Configuración")
        .alert("¿Estás seguro?", isPresented: $showingResetAlert) {
            Button("Reiniciar", role: .destructive) {
                progressVM.resetProgress()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Todo tu progreso de entrenamiento se eliminará de forma permanente.")
        }
    }
}
