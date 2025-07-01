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
            // Ensure "Error" is a key in Localizable.strings or handle appropriately
            return WeeklyPlan(week: 0, phase: NSLocalizedString("error", comment: "Error phase for plan"), workouts: [], diet: Diet(calories: 0, protein: 0, carbs: 0, fats: 0))
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
                            description: DataManager.shared.descriptions[workout.name] ?? NSLocalizedString("no_description_available", comment: "No description available"),
                            completedReps: progressBinding
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle(title) // Title is dynamic, localization handled where `title` is set
        .toolbar {
            ToolbarItemGroup {
                Button(NSLocalizedString("previous_button", comment: "Previous button"), systemImage: "arrow.left") { weekIndex -= 1 }
                    .disabled(weekIndex <= 0)
                
                VStack {
                    ProgressView(value: progressVM.percentComplete(for: currentPlan))
                    Text("\(Int(progressVM.percentComplete(for: currentPlan) * 100))%")
                        .font(.caption.bold())
                }.frame(width: 50)
                
                Button(NSLocalizedString("next_button", comment: "Next button"), systemImage: "arrow.right") { weekIndex += 1 }
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
        .navigationTitle(NSLocalizedString("definitions_title", comment: "Definitions view title"))
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
                        Text(NSLocalizedString("progress_by_exercise_title", comment: "Progress by exercise chart title")).font(.title3).bold()
                        Picker(NSLocalizedString("select_exercise_picker_label", comment: "Select exercise picker label"), selection: $selectedExercise) {
                            ForEach(allExercises, id: \.self) { exerciseName in
                                Text(exerciseName).tag(exerciseName) // Exercise names might need localization if they are not codes
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.bottom, 10)
                        
                        Chart(progressChartData) { dataPoint in
                            LineMark(
                                x: .value(NSLocalizedString("chart_week_axis_label", comment: "Chart week axis label"), dataPoint.week),
                                y: .value(NSLocalizedString("chart_completed_reps_label", comment: "Chart completed reps label"), dataPoint.completedReps)
                            )
                            .foregroundStyle(by: .value(NSLocalizedString("chart_type_legend_label", comment: "Chart type legend label"), NSLocalizedString("chart_completed_legend_value", comment: "Chart completed legend value")))
                            .symbol(by: .value(NSLocalizedString("chart_type_legend_label", comment: "Chart type legend label"), NSLocalizedString("chart_completed_legend_value", comment: "Chart completed legend value")))

                            LineMark(
                                x: .value(NSLocalizedString("chart_week_axis_label", comment: "Chart week axis label"), dataPoint.week),
                                y: .value(NSLocalizedString("chart_planned_reps_label", comment: "Chart planned reps label"), dataPoint.plannedReps)
                            )
                            .foregroundStyle(by: .value(NSLocalizedString("chart_type_legend_label", comment: "Chart type legend label"), NSLocalizedString("chart_planned_legend_value", comment: "Chart planned legend value")))
                            .symbol(by: .value(NSLocalizedString("chart_type_legend_label", comment: "Chart type legend label"), NSLocalizedString("chart_planned_legend_value", comment: "Chart planned legend value")))
                            .lineStyle(StrokeStyle(dash: [5, 5]))
                        }
                        .chartForegroundStyleScale([NSLocalizedString("chart_completed_legend_value", comment: "Chart completed legend value"): .blue, NSLocalizedString("chart_planned_legend_value", comment: "Chart planned legend value"): .gray])
                        .frame(height: 250)
                    }
                }
                
                GroupBox {
                    VStack(alignment: .leading) {
                        Text(NSLocalizedString("weekly_volume_chart_title", comment: "Weekly volume chart title")).font(.title3).bold()
                        Chart(volumeChartData) { dataPoint in
                            BarMark(
                                x: .value(NSLocalizedString("chart_week_axis_label", comment: "Chart week axis label"), dataPoint.week),
                                y: .value(NSLocalizedString("chart_total_reps_label", comment: "Chart total reps label"), dataPoint.totalReps)
                            )
                            .foregroundStyle(.green.gradient)
                        }
                        .frame(height: 250)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(NSLocalizedString("progress_charts_title", comment: "Progress charts view title"))
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
                Text(workout.name).font(.headline) // Workout names might need localization if they are not codes
                Text(String(format: NSLocalizedString("target_reps_label", comment: "Target reps label"), workout.reps)).font(.subheadline).foregroundStyle(.secondary)
            }
            
            if !description.isEmpty {
                Text(description).font(.callout).foregroundStyle(.secondary).lineLimit(2) // Description is already localized or fetched
            }
            
            Divider()
            
            HStack {
                Text(NSLocalizedString("progress_label", comment: "Progress label")).font(.subheadline).foregroundStyle(.secondary)
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
                        Text(NSLocalizedString("content_update_title", comment: "Content update section title")).font(.title3).bold()
                        Divider()

                        HStack {
                            VStack(alignment: .leading) {
                                Text(NSLocalizedString("content_update_description", comment: "Content update description"))
                                switch assetManager.downloadState {
                                case .idle:
                                    Text(NSLocalizedString("status_idle", comment: "Status: Idle")).font(.caption).foregroundStyle(.secondary)
                                case .downloadingJSON:
                                    Text(NSLocalizedString("status_downloading_plans", comment: "Status: Downloading plans")).font(.caption).foregroundStyle(.blue)
                                case .downloadingImages:
                                    Text(NSLocalizedString("status_downloading_images", comment: "Status: Downloading images")).font(.caption).foregroundStyle(.blue)
                                case .finished:
                                    Text(NSLocalizedString("status_content_updated", comment: "Status: Content updated")).font(.caption).foregroundStyle(.green)
                                case .error(let msg): // Assuming msg is an error description not needing localization here
                                    Text(String(format: NSLocalizedString("status_error_format", comment: "Status: Error format"), msg.localizedDescription)).font(.caption).foregroundStyle(.red)
                                }
                            }
                            Spacer()
                            Button(NSLocalizedString("update_button", comment: "Update button")) {
                                assetManager.updateAssets()
                            }
                            .disabled(assetManager.downloadState == .downloadingJSON && assetManager.downloadState == .downloadingImages)
                        }
                    }
                }
                GroupBox {
                    VStack(alignment: .leading) {
                        Text(NSLocalizedString("training_plan_title", comment: "Training plan section title")).font(.title3).bold()
                        Divider()
                        Picker(NSLocalizedString("current_hero_picker_label", comment: "Current hero picker label"), selection: $selectedHero) {
                            ForEach(availableHeroes, id: \.self) { hero in
                                Text(NSLocalizedString(hero.lowercased() + "_name", comment: "Hero name")).tag(hero)
                            }
                        }
                        Text(NSLocalizedString("change_plan_warning", comment: "Change plan warning")).font(.caption).foregroundStyle(.secondary).padding(.top, 5)
                    }
                }
                
                GroupBox {
                    VStack(alignment: .leading) {
                        Text(NSLocalizedString("data_management_title", comment: "Data management section title")).font(.title3).bold()
                        Divider()
                        Text(NSLocalizedString("reset_progress_warning", comment: "Reset progress warning")).font(.callout).foregroundStyle(.secondary).padding(.vertical, 5)
                        Button(NSLocalizedString("reset_progress_button", comment: "Reset progress button"), role: .destructive) {
                            showingResetAlert = true
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                
                GroupBox {
                    VStack(alignment: .leading) {
                        Text(NSLocalizedString("debugging_options_title", comment: "Debugging options section title"))
                            .font(.title3.bold())
                        Divider()
                        
                        Text(NSLocalizedString("reset_onboarding_description", comment: "Reset onboarding description"))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 5)
                        
                        Button(NSLocalizedString("reset_onboarding_button", comment: "Reset onboarding button")) {
                            // La acción es simple: ponemos la bandera en false.
                            hasCompletedOnboarding = false
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                
                GroupBox {
                    VStack(alignment: .leading) {
                        Text(NSLocalizedString("about_title", comment: "About section title")).font(.title3).bold()
                        Divider()
                        HStack {
                            Text(NSLocalizedString("app_version_label", comment: "App version label"))
                            Spacer()
                            Text("1.0.0").foregroundStyle(.secondary) // Version number might not need localization
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(NSLocalizedString("settings_title", comment: "Settings view title"))
        .alert(NSLocalizedString("are_you_sure_alert_title", comment: "Are you sure alert title"), isPresented: $showingResetAlert) {
            Button(NSLocalizedString("reset_button", comment: "Reset button"), role: .destructive) {
                progressVM.resetProgress()
            }
            Button(NSLocalizedString("cancel_button", comment: "Cancel button"), role: .cancel) {}
        } message: {
            Text(NSLocalizedString("reset_progress_alert_message", comment: "Reset progress alert message"))
        }
    }
}
