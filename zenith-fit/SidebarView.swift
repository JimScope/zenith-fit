//
//  SidebarView.swift
//
//  Created by Jimmy Angel Pérez Díaz on 6/14/25.
//

import SwiftUI

// MARK: - Barra Lateral Estilo "Notas"

struct SidebarView: View {
    @Binding var selection: ContentView.ViewType
    let currentPlan: WeeklyPlan
    
    private func icon(for viewType: ContentView.ViewType) -> String {
        switch viewType {
        case .route: return "map.fill"
        case .definitions: return "book.fill"
        case .charts: return "chart.bar.xaxis"
        case .settings: return "gearshape.fill"
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            // List con estilo .sidebar para un look and feel nativo de macOS.
            List(selection: $selection) {
                ForEach(ContentView.ViewType.allCases, id: \.self) { viewType in
                    Label(NSLocalizedString(viewType.rawValue.lowercased(), comment: "View type name"), systemImage: icon(for: viewType))
                        .tag(viewType)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle(NSLocalizedString("menu_title", comment: "Menu title")) // Título visible en la parte superior de la barra lateral.
            
            Spacer()
            
            // Pie de página con información de la semana.
            VStack(alignment: .leading) {
                Text(String(format: NSLocalizedString("week_number", comment: "Week number format"), currentPlan.week))
                    .font(.headline)
                Text(currentPlan.phase) // Assuming phase is already localized or doesn't need to be
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}
