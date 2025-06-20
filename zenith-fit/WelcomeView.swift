import SwiftUI

struct WelcomeView: View {
    // Variables para gestionar el estado de la bienvenida
    @AppStorage("selectedHero") private var selectedHero: String = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    // Estado local para la selección en esta vista
    @State private var localSelectedHero: String
    
    // Lista de héroes disponibles desde el DataManager
    private let availableHeroes = DataManager.shared.getAvailableHeroes()
    
    init() {
        // Inicializa la selección local con el primer héroe disponible
        _localSelectedHero = State(initialValue: availableHeroes.first ?? "")
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Título y Descripción
            Image(systemName: "figure.strengthtraining.functional")
                .font(.system(size: 60))
                .foregroundStyle(.tint)
            
            Text("Bienvenido a Hero Routine")
                .font(.largeTitle).bold()
            
            Text("Escoge tu camino. Selecciona el plan de entrenamiento del héroe que quieres seguir.")
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
            
            // Selector de Héroe
            Picker("Elige tu Héroe", selection: $localSelectedHero) {
                ForEach(availableHeroes, id: \.self) { hero in
                    Text(hero).tag(hero)
                }
            }
            .pickerStyle(.segmented) // Un estilo de selector muy claro
            .padding(.horizontal, 40)

            Spacer()
            
            // Botón para continuar
            Button(action: {
                // Guarda la selección y marca la bienvenida como completada
                selectedHero = localSelectedHero
                hasCompletedOnboarding = true
            }) {
                Text("Comenzar Entrenamiento")
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
            .disabled(localSelectedHero.isEmpty) // Deshabilitado si no hay héroes
        }
    }
}