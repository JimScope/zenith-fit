// AssetManager.swift (Versión Final con async/await para corregir el error de concurrencia)
import Foundation
import Combine

// ¡Recuerda tener AppConstants.swift compartido entre ambos targets!

enum DownloadState: Equatable {
    case idle
    case downloading
    case finished
    case error(String)
}

@MainActor
class AssetManager: ObservableObject {
    @Published var downloadState: DownloadState = .idle
    
    static let shared = AssetManager()
    
    // Usaremos una sesión de URL estándar para las descargas.
    private let urlSession = URLSession(configuration: .default)
    
    private init() { }

    func updateAssets() {
        // Marcamos el estado como descargando.
        // Como estamos en un @MainActor, esto es seguro.
        self.downloadState = .downloading
        
        // Creamos una Tarea de Swift Concurrency para manejar todo en segundo plano.
        Task {
            let assetURLs: [String: URL] = [
                "workouts.json": URL(string: "https://raw.githubusercontent.com/JimScope/zenith-fit-data/main/workouts.json")!,
                "definitions.json": URL(string: "https://raw.githubusercontent.com/JimScope/zenith-fit-data/main/definitions.json")!,
                "descriptions.json": URL(string: "https://raw.githubusercontent.com/JimScope/zenith-fit-data/main/descriptions.json")!
            ]
            
            do {
                // Usamos un TaskGroup para ejecutar todas las descargas en paralelo.
                try await withThrowingTaskGroup(of: Void.self) { group in
                    for (filename, url) in assetURLs {
                        group.addTask {
                            // ¡CORRECCIÓN! Usamos la versión async de data(from:)
                            let (data, response) = try await self.urlSession.data(from: url)
                            
                            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                                throw URLError(.badServerResponse)
                            }
                            
                            // Ahora llamamos a save, que es un método del MainActor.
                            // Como todo el Task se ejecuta dentro de un @MainActor,
                            // esta llamada es segura y no necesita "await" extra.
                            await self.save(data: data, to: filename)
                        }
                    }
                    // Esperamos a que todas las tareas del grupo terminen.
                    try await group.waitForAll()
                }
                
                // Si llegamos aquí, todas las descargas fueron exitosas.
                print("All assets downloaded and saved successfully.")
                self.downloadState = .finished
                // Recargamos los datos en el DataManager
                DataManager.shared.reloadData()
                
            } catch {
                // Si cualquier tarea del grupo lanza un error, se captura aquí.
                print("Failed to download assets: \(error.localizedDescription)")
                self.downloadState = .error(error.localizedDescription)
            }
        }
    }
    
    // Esta función, al ser parte de un @MainActor, se ejecuta en el hilo principal.
    private func save(data: Data, to filename: String) {
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier) else {
            print("Error: Could not get app group container.")
            return
        }
        
        let destinationURL = appGroupURL.appendingPathComponent(filename)
        
        do {
            try data.write(to: destinationURL, options: .atomic)
            print("Successfully saved \(filename) to \(destinationURL.path)")
        } catch {
            print("Error saving \(filename): \(error.localizedDescription)")
        }
    }
    
    // La función getURL no cambia.
    func getURL(for filename: String) -> URL {
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier) else {
            return Bundle.main.url(forResource: filename, withExtension: nil)!
        }
        
        let downloadedFileURL = appGroupURL.appendingPathComponent(filename)
        
        if FileManager.default.fileExists(atPath: downloadedFileURL.path) {
            return downloadedFileURL
        } else {
            return Bundle.main.url(forResource: filename, withExtension: nil)!
        }
    }
}
