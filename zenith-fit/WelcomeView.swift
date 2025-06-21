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
                // ¡CORRECCIÓN! Solo forzamos el ANCHO, dejamos que la ALTURA sea automática.
                .frame(width: geometry.size.width)
                .offset(x: showHeroSelectionPage ? 0 : geometry.size.width)

                WelcomePageOne(action: {
                    showHeroSelectionPage = true
                })
                // ¡CORRECCIÓN! Solo forzamos el ANCHO.
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


// ===================================================================
// LAS SUBVISTAS NO NECESITAN NINGÚN CAMBIO.
// ... (El código de WelcomePageOne, WelcomePageTwo, y HeroSelectionCard
// permanece exactamente igual que en la versión anterior)
// ===================================================================

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

// Subvista para la segunda página
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
            
            Text("Selecciona un plan para comenzar.")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Group {
                switch assetManager.downloadState {
                case .idle, .downloading:
                    ProgressView("Descargando planes...")
                        .padding(.top, 50)
                case .finished:
                    if availableHeroes.isEmpty {
                        Text("Cargando héroes...")
                            .onAppear(perform: reloadData)
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
                case .error(let message):
                    Text("Error al descargar: \(message)")
                        .foregroundStyle(.red)
                        .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Button("Comenzar Entrenamiento") {
                onComplete(localSelectedHero)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
            .disabled(localSelectedHero.isEmpty)
        }
        .onAppear(perform: reloadData)
        .onChange(of: assetManager.downloadState) { oldValue, newValue in
            if case .finished = newValue {
                reloadData()
            }
        }
    }
    
    private func reloadData() {
        DataManager.shared.reloadData()
        availableHeroes = DataManager.shared.getAvailableHeroes()
        if localSelectedHero.isEmpty, let firstHero = availableHeroes.first {
            localSelectedHero = firstHero
        }
    }
}

// Tarjeta de selección de héroe
struct HeroSelectionCard: View {
    let heroName: String
    let isSelected: Bool
    
    var body: some View {
        VStack {
            Image(heroName)
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
