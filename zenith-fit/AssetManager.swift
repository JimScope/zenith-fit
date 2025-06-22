// AssetManager.swift (Reestructurado para descarga de imágenes)
import SwiftUI
import Combine

enum DownloadState: Equatable {
    case idle
    case downloadingJSON
    case downloadingImages
    case finished(Date)
    case error(ErrorType)
    
    enum ErrorType: Equatable {
        case network(String) // Fallo de conexión (ej. sin internet)
        case dataProcessing(String) // Fallo al decodificar JSON, etc.
    }
}

@MainActor
class AssetManager: ObservableObject {
    @Published var downloadState: DownloadState = .idle
    
    static let shared = AssetManager()
    private let urlSession = URLSession(configuration: .default)
    
    private init() { }

    func updateAssets() {
        guard !isDownloading() else { return }
        
        self.downloadState = .downloadingJSON

        Task {
            do {
                // FASE 1: Descargar los archivos JSON esenciales
                let jsonFiles = ["workouts.json", "definitions.json", "descriptions.json"]
                try await downloadFiles(named: jsonFiles, baseURL: "https://raw.githubusercontent.com/JimScope/zenith-fit-data/main/")
                
                // Una vez descargado el JSON, recargamos los datos para saber qué héroes existen
                DataManager.shared.reloadData()
                let heroes = DataManager.shared.getAvailableHeroes()
                
                // FASE 2: Descargar las imágenes para cada héroe
                self.downloadState = .downloadingImages
                let imageFilenames = heroes.map { "\($0).jpg" }
                try await downloadFiles(named: imageFilenames, baseURL: "https://raw.githubusercontent.com/JimScope/zenith-fit-data/main/images/")
                
                // ¡Todo ha terminado con éxito!
                self.downloadState = .finished(Date())
                print("Todos los assets, incluyendo imágenes, se han actualizado.")
                
            } catch let error as URLError where error.code == .notConnectedToInternet || error.code == .cannotFindHost {
                self.downloadState = .error(.network("Sin conexión a internet."))
            } catch {
                self.downloadState = .error(.dataProcessing("No se pudieron actualizar los archivos. \(error.localizedDescription)"))
            }
        }
    }
    
    // Función de ayuda genérica para descargar un conjunto de archivos
    private func downloadFiles(named filenames: [String], baseURL: String) async throws {
         try await withThrowingTaskGroup(of: Void.self) { group in
             for filename in filenames {
                 guard let url = URL(string: baseURL + filename.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!) else { continue }
                 
                 group.addTask {
                     let (data, response) = try await self.urlSession.data(from: url)
                     
                     guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                         // Si la respuesta no es 200, podría ser 304 (Not Modified), lo cual no es un error.
                         // O podría ser 404 (Not Found), lo cual es un error del lado del servidor.
                         if (response as? HTTPURLResponse)?.statusCode != 304 {
                             print("Respuesta no válida para \(filename): \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                             throw URLError(.badServerResponse)
                         }
                         // Si es 304, no hacemos nada. La caché es válida.
                         return
                     }
                     
                     await self.save(data: data, to: filename)
                 }
             }
             try await group.waitForAll()
         }
     }
     
     // Función privada para comprobar si está en un estado de descarga
     private func isDownloading() -> Bool {
         if case .downloadingJSON = downloadState { return true }
         if case .downloadingImages = downloadState { return true }
         return false
     }
    
    // Función privada para guardar los datos en el App Group container.
    private func save(data: Data, to filename: String) {
        // Las imágenes se guardan en una subcarpeta para mantener el orden.
        let isImage = filename.hasSuffix(".png") || filename.hasSuffix(".jpg")
        let subfolder = isImage ? "images/" : ""
        
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier) else { return }
        
        let destinationDirectory = appGroupURL.appendingPathComponent(subfolder)
        let destinationURL = destinationDirectory.appendingPathComponent(filename)

        do {
            // Asegurarse de que el directorio de imágenes exista
            if isImage {
                try FileManager.default.createDirectory(at: destinationDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            try data.write(to: destinationURL, options: .atomic)
        } catch {
            print("Error al guardar \(filename): \(error.localizedDescription)")
        }
    }
    
    // ¡NUEVO! Función para cargar una imagen desde el disco.
    func loadImage(forHero heroName: String) -> Image {
        // 1. Intenta cargar desde el App Group (archivos descargados)
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier) {
            let imageURL = appGroupURL.appendingPathComponent("images/\(heroName).png")
            if let nsImage = NSImage(contentsOf: imageURL) {
                return Image(nsImage: nsImage)
            }
        }
        
        // 2. Si falla, intenta cargar desde el Asset Catalog del Bundle (imágenes iniciales)
        // La inicialización `Image(heroName)` busca automáticamente en Assets.xcassets.
        // Usamos NSImage(named:) para comprobar si la imagen realmente existe antes de usarla.
        if NSImage(named: heroName) != nil {
            return Image(heroName)
        }
        
        // 3. Si todo lo demás falla, devuelve la imagen de respaldo.
        return Image("HeroPlaceholder")
    }
    
    // Función auxiliar para comprobar si el estado es de error
    private func isError(_ state: DownloadState) -> Bool {
        if case .error = state { return true }
        return false
    }
}

// Extensión para que getURL no necesite cambios
extension AssetManager {
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
