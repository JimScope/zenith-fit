// ComponentViews.swift (Versión Final Corregida)

import SwiftUI
import Charts

// MARK: - Vistas de Detalle (Rediseñadas con Toolbar y GroupBox)

struct RouteView: View {
    @Binding var weekIndex: Int
    @ObservedObject var progressVM: ProgressViewModel
    let title: String
    
    private let data = DataManager.shared
    private var currentPlan: WeeklyPlan { data.plan[weekIndex] }
    
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
                            description: data.descriptions[workout.name] ?? "Sin descripción.",
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
                    .disabled(weekIndex == 0)
                
                VStack {
                    ProgressView(value: progressVM.percentComplete(for: currentPlan))
                    Text("\(Int(progressVM.percentComplete(for: currentPlan) * 100))%")
                        .font(.caption.bold())
                }.frame(width: 50)
                
                Button("Siguiente", systemImage: "arrow.right") { weekIndex += 1 }
                    .disabled(weekIndex == data.plan.count - 1)
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
    // Recibimos el ViewModel para acceder a los datos de progreso del usuario.
    @ObservedObject var progressVM: ProgressViewModel
    
    // Lista de todos los ejercicios únicos disponibles en el plan.
    private let allExercises: [String]
    
    // Estado para saber qué ejercicio está seleccionado actualmente.
    @State private var selectedExercise: String
    
    // Estructura para los puntos de datos del gráfico de progreso.
    private struct ExerciseProgressPoint: Identifiable {
        var id: Int { week }
        let week: Int
        let completedReps: Int
        let plannedReps: Int
    }
    
    // Estructura para los puntos de datos del gráfico de volumen.
    private struct WeeklyVolume: Identifiable {
        var id: Int { week }
        let week: Int
        let totalReps: Int
    }

    // Inicializador para configurar la lista de ejercicios y la selección inicial.
    init(progressVM: ProgressViewModel) {
        self.progressVM = progressVM
        
        let allWorkoutNames = DataManager.shared.plan.flatMap { $0.workouts.map { $0.name } }
        let uniqueNames = Array(Set(allWorkoutNames)).sorted()
        
        self.allExercises = uniqueNames
        self._selectedExercise = State(initialValue: uniqueNames.first ?? "")
    }

    // Calcula los datos para el gráfico de progreso del ejercicio seleccionado.
    private var progressChartData: [ExerciseProgressPoint] {
        DataManager.shared.plan.compactMap { weekPlan in
            // Buscamos si el ejercicio seleccionado está en esta semana.
            if let workout = weekPlan.workouts.first(where: { $0.name == selectedExercise }) {
                // Obtenemos las repeticiones completadas desde el ViewModel.
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
    
    // Calcula el volumen total (suma de todas las repeticiones completadas) por semana.
    private var volumeChartData: [WeeklyVolume] {
        DataManager.shared.plan.map { weekPlan in
            let totalCompletedReps = weekPlan.workouts.reduce(0) { sum, workout in
                sum + progressVM.getProgress(for: workout, in: weekPlan.week)
            }
            return WeeklyVolume(week: weekPlan.week, totalReps: totalCompletedReps)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // GRÁFICO 1: PROGRESO POR EJERCICIO
                GroupBox {
                    VStack(alignment: .leading) {
                        Text("Progreso por Ejercicio").font(.title3).bold()
                        
                        // Selector para que el usuario elija el ejercicio.
                        Picker("Selecciona un ejercicio:", selection: $selectedExercise) {
                            ForEach(allExercises, id: \.self) { exerciseName in
                                Text(exerciseName).tag(exerciseName)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.bottom, 10)
                        
                        Chart(progressChartData) { dataPoint in
                            // Línea para las repeticiones completadas (real).
                            LineMark(
                                x: .value("Semana", dataPoint.week),
                                y: .value("Completadas", dataPoint.completedReps)
                            )
                            .foregroundStyle(by: .value("Tipo", "Completadas"))
                            .symbol(by: .value("Tipo", "Completadas"))

                            // Línea para las repeticiones planeadas (objetivo).
                            LineMark(
                                x: .value("Semana", dataPoint.week),
                                y: .value("Planeadas", dataPoint.plannedReps)
                            )
                            .foregroundStyle(by: .value("Tipo", "Planeadas"))
                            .symbol(by: .value("Tipo", "Planeadas"))
                            .lineStyle(StrokeStyle(dash: [5, 5])) // Línea discontinua para el objetivo
                        }
                        .chartForegroundStyleScale([
                            "Completadas": .blue,
                            "Planeadas": .gray
                        ])
                        .frame(height: 250)
                    }
                }
                
                // GRÁFICO 2: VOLUMEN TOTAL SEMANAL
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
    // Recibimos el ViewModel para poder llamar a sus funciones.
    @ObservedObject var progressVM: ProgressViewModel
    
    // Estado para mostrar la alerta de confirmación.
    @State private var showingResetAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Sección de Gestión de Datos
                GroupBox {
                    VStack(alignment: .leading) {
                        Text("Gestión de Datos")
                            .font(.title3.bold())
                        
                        Divider()
                        
                        Text("Esta acción eliminará permanentemente todo tu progreso registrado en los entrenamientos. Las estadísticas en las gráficas también se reiniciarán. Esta acción no se puede deshacer.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 5)
                        
                        // Botón para iniciar el reseteo
                        Button("Reiniciar Progreso y Estadísticas", role: .destructive) {
                            // Al pulsar, mostramos la alerta de confirmación
                            showingResetAlert = true
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                
                // (Opcional) Puedes añadir más secciones aquí en el futuro
                GroupBox {
                    VStack(alignment: .leading) {
                        Text("Acerca de")
                            .font(.title3.bold())
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
        // Alerta de confirmación para una acción destructiva
        .alert("¿Estás seguro?", isPresented: $showingResetAlert) {
            Button("Reiniciar", role: .destructive) {
                // Si el usuario confirma, llamamos a la función del ViewModel
                progressVM.resetProgress()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Todo tu progreso de entrenamiento se eliminará de forma permanente.")
        }
    }
}
