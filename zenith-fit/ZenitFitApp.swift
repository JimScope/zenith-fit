//
//  zenith_fitApp.swift
//
//  Created by Jimmy Angel Pérez Díaz on 6/14/25.
//

import SwiftUI

@main
struct ZenitFitApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .sheet(isPresented: .constant(!hasCompletedOnboarding), onDismiss: {
                    // Si el usuario cierra la hoja sin completar, forzamos la app a cerrarse
                    // o podrías manejarlo de otra forma, pero no debe poder usar la app sin un plan.
                    if !hasCompletedOnboarding {
                        NSApplication.shared.terminate(nil)
                    }
                }) {
                    // Muestra la WelcomeView si la bienvenida no ha sido completada
                    WelcomeView()
                        .interactiveDismissDisabled() // Evita que se cierre deslizando
                        .frame(minWidth: 500, minHeight: 600)
                }
        }
    }
}
