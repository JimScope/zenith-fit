// ContentView.swift (Versión Final)

import SwiftUI

// Vista principal que organiza la navegación de la aplicación.
struct ContentView: View {
    
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

    private var currentPlan: WeeklyPlan { data.plan[weekIndex] }
    
    private var routeViewTitle: String {
        "Semana \(currentPlan.week) - \(currentPlan.phase)"
    }

    // --- Body ---
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // --- Columna de la Barra Lateral (SIN CAMBIOS) ---
            SidebarView(selection: $currentView, currentPlan: currentPlan)
                .navigationSplitViewColumnWidth(min: 220, ideal: 250)

        } detail: {
            // --- Columna de Detalle (Contenido Principal) ---
            // Cada vista ahora gestiona su propia toolbar y título.
            VStack {
                switch currentView {
                case .route:
                    // Pasamos el título dinámico a la RouteView
                    RouteView(weekIndex: $weekIndex, progressVM: progressVM, title: routeViewTitle)
                case .definitions:
                    DefinitionsView()
                case .charts:
                    ChartsView(progressVM: progressVM)
                case .settings:
                    SettingsView(progressVM: progressVM)
                }
            }
            .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.3), value: currentView)
    }
}
