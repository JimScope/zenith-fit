// WelcomeView.swift (Corregido para altura correcta)
import SwiftUI


struct WelcomeView: View {
    @StateObject private var assetManager = AssetManager.shared
    @AppStorage("selectedHero") private var selectedHero: String = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showHeroSelectionPage = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                WelcomePageTwo(onComplete: { hero in
                    selectedHero = hero
                    hasCompletedOnboarding = true
                })
                .frame(width: geometry.size.width)
                .offset(x: showHeroSelectionPage ? 0 : geometry.size.width)

                WelcomePageOne(action: {
                    showHeroSelectionPage = true
                })
                .frame(width: geometry.size.width)
                .offset(x: showHeroSelectionPage ? -geometry.size.width : 0)
            }
            .animation(.easeInOut(duration: 0.4), value: showHeroSelectionPage)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            assetManager.updateAssets()
        }
    }
}


// Subvista para la primera página
struct WelcomePageOne: View {
    var action: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: "figure.run.square.stack.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.tint)
                Text("Bienvenido a Zenith Fit")
                    .font(.largeTitle.bold())
                Text("Forja tu leyenda. Sigue los entrenamientos de los héroes más grandes.")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            
            Spacer()
            
            Button("Continuar", action: action)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding()
        }
    }
}

// ¡WelcomePageTwo es la que cambia significativamente!
struct WelcomePageTwo: View {
    @StateObject private var assetManager = AssetManager.shared
    
    @State private var localSelectedHero: String = ""
    @State private var availableHeroes: [String] = []
    
    var onComplete: (String) -> Void
    
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 20)]
    
    var body: some View {
        VStack {
            Text("Elige tu Camino")
                .font(.largeTitle.bold())
                .padding(.top, 60)
            
            // ¡NUEVO! Vista de estado de la red.
            NetworkStatusView(status: assetManager.downloadState)
            
            Spacer()
            
            // La cuadrícula de héroes ahora es la vista principal,
            // y siempre intenta mostrarse usando los datos disponibles.
            if availableHeroes.isEmpty {
                // Si la lista está vacía, puede ser que se esté cargando
                // o que no haya datos ni en el disco ni en el bundle.
                VStack {
                    Spacer()
                    ProgressView()
                    Text("Buscando planes de entrenamiento...")
                        .foregroundStyle(.secondary)
                        .padding(.top)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(availableHeroes, id: \.self) { hero in
                            HeroSelectionCard(
                                heroName: hero,
                                isSelected: localSelectedHero == hero
                            )
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    localSelectedHero = hero
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            
            Spacer()
            
            Button("Comenzar Entrenamiento") {
                onComplete(localSelectedHero)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
            .disabled(localSelectedHero.isEmpty)
        }
        .onAppear(perform: reloadData) // Carga los datos del bundle inmediatamente al aparecer.
        .onChange(of: assetManager.downloadState) { oldValue, newValue in
            // Recarga los datos cuando la descarga finaliza con éxito.
            if case .finished = newValue {
                reloadData()
            }
        }
    }
    
    private func reloadData() {
        // Esta función ahora se llama al aparecer la vista,
        // por lo que carga los datos del bundle inmediatamente.
        DataManager.shared.reloadData()
        availableHeroes = DataManager.shared.getAvailableHeroes()
        if localSelectedHero.isEmpty, let firstHero = availableHeroes.first {
            localSelectedHero = firstHero
        }
    }
}

// ¡NUEVO! Una vista sutil para mostrar el estado de la conexión.
struct NetworkStatusView: View {
    let status: DownloadState
    
    // Función de ayuda privada para obtener los datos de la vista.
    // Esto mueve TODA la lógica del switch fuera del body.
    private func statusInfo() -> (label: String, systemImage: String, color: Color)? {
        switch status {
        case .idle:
            return nil // Si está idle, no devolvemos nada, así no se muestra la vista.
        case .downloadingJSON:
            return ("Actualizando datos...", "arrow.down.circle", .secondary)
        case .downloadingImages:
            return ("Actualizando imágenes...", "arrow.down.circle", .secondary)
        case .finished(let date):
            // La lógica del formateador está ahora segura dentro de esta función.
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            let dateString = formatter.localizedString(for: date, relativeTo: Date())
            return ("Actualizado \(dateString)", "checkmark.circle.fill", .green)
        case .error(let errorType):
            switch errorType {
            case .network:
                return ("Modo offline. Mostrando contenido local.", "wifi.slash", .orange)
            case .dataProcessing:
                return ("No se pudo actualizar el contenido.", "exclamationmark.triangle.fill", .red)
            }
        }
    }
    
    var body: some View {
        // El body ahora es 100% declarativo.
        // Llama a la función de ayuda y solo construye la vista si obtiene un resultado.
        if let info = statusInfo() {
            Label(info.label, systemImage: info.systemImage)
                .font(.caption)
                .foregroundStyle(info.color)
                .padding(8)
                .background(Material.thin)
                .clipShape(Capsule())
                .transition(.opacity.animation(.easeInOut))
        }
    }
}

// ... (WelcomePageOne y HeroSelectionCard no cambian) ...
// Tarjeta de selección de héroe
struct HeroSelectionCard: View {
    let heroName: String
    let isSelected: Bool
    
    var body: some View {
        VStack {
            // ¡ACTUALIZADO! Llama a la nueva función para cargar la imagen.
            AssetManager.shared.loadImage(forHero: heroName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.bottom, 8)
            
            Text(heroName)
                .font(.headline)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
        )
    }
}
