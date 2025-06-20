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
                    Label(viewType.rawValue, systemImage: icon(for: viewType))
                        .tag(viewType)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Menú") // Título visible en la parte superior de la barra lateral.
            
            Spacer()
            
            // Pie de página con información de la semana.
            VStack(alignment: .leading) {
                Text("Semana \(currentPlan.week)")
                    .font(.headline)
                Text(currentPlan.phase)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}
