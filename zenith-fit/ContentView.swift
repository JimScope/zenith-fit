// ContentView.swift (Versión Final Corregida)

import SwiftUI

// Vista principal que organiza la navegación de la aplicación.
struct ContentView: View {
    // Lee el héroe seleccionado de forma persistente. La vista se actualizará si cambia.
    @AppStorage("selectedHero") private var selectedHero: String = ""
    
    enum ViewType: String, CaseIterable, Hashable {
        case route = "Ruta"
        case definitions = "Definiciones"
        case charts = "Gráficos"
        case settings = "Configuración"
    }

    // --- State Management ---
    @State private var weekIndex = 0
    @State private var currentView: ViewType = .route
    @StateObject private var progressVM = ProgressViewModel()
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    // --- Data Source ---
    private let data = DataManager.shared
    
    // Propiedad computada para obtener el plan de entrenamiento completo del héroe actual.
    private var currentHeroPlan: [WeeklyPlan] {
        return data.plan(for: selectedHero)
    }
    
    // Propiedad computada segura para obtener el plan de la semana actual.
    private var currentWeeklyPlan: WeeklyPlan {
        let plan = currentHeroPlan
        guard !plan.isEmpty, weekIndex < plan.count else {
            return WeeklyPlan(week: 0, phase: "Plan no disponible", workouts: [], diet: Diet(calories: 0, protein: 0, carbs: 0, fats: 0))
        }
        return plan[weekIndex]
    }
    
    private var routeViewTitle: String {
        "Semana \(currentWeeklyPlan.week) - \(currentWeeklyPlan.phase)"
    }

    // --- Body ---
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selection: $currentView, currentPlan: currentWeeklyPlan)
                .navigationSplitViewColumnWidth(min: 220, ideal: 250)
            
        } detail: {
            VStack {
                switch currentView {
                case .route:
                    RouteView(
                        weekIndex: Binding<Int>(
                            get: { weekIndex },
                            set: { newIndex in
                                if newIndex >= 0 && newIndex < currentHeroPlan.count {
                                    weekIndex = newIndex
                                }
                            }
                        ),
                        progressVM: progressVM,
                        title: routeViewTitle,
                        // ¡CORREGIDO! Se añade el parámetro 'fullPlan' que faltaba.
                        fullPlan: currentHeroPlan
                    )
                case .definitions:
                    DefinitionsView()
                case .charts:
                    // ¡CORREGIDO! Se añade el parámetro 'selectedHero' que faltaba.
                    ChartsView(progressVM: progressVM, selectedHero: selectedHero)
                case .settings:
                    SettingsView(progressVM: progressVM)
                }
            }
            .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.3), value: currentView)
        .onAppear {
            progressVM.setActiveHero(selectedHero)
        }
        .onChange(of: selectedHero) { oldHero, newHero in
            progressVM.setActiveHero(newHero)
            weekIndex = 0
        }
    }
}
