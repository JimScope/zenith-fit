// BackgroundDownloadHandler.swift (Modificado para funcionar con Zenith Fit)
import BackgroundAssets
import os.log

// Modelo para decodificar el manifest.json que viene de tu repo de GitHub
struct Manifest: Codable {
    let assets: [AssetInfo]
}

struct AssetInfo: Codable {
    let id: String // Debe coincidir con los IDs en AppConstants (ej. "com.jimscope.zenith-fit.workouts")
    let url: String
}

@main
struct BackgroundDownloadHandler: BADownloaderExtension {
    
    // Función de ayuda para mapear un ID de descarga a un nombre de archivo final.
    private func filename(for identifier: String) -> String? {
        switch identifier {
        case AppConstants.workoutsID: return "workouts.json"
        case AppConstants.definitionsID: return "definitions.json"
        case AppConstants.descriptionsID: return "descriptions.json"
        default: return nil
        }
    }
    
    // Este método se invoca cuando el sistema decide buscar actualizaciones.
    func downloads(for request: BAContentRequest, manifestURL: URL, extensionInfo: BAAppExtensionInfo) -> Set<BADownload> {
        
        var downloadsToSchedule = Set<BADownload>()
        let oneMB = 1024 * 1024
        
        do {
            // 1. Leemos y decodificamos el manifest.json que el sistema ya ha descargado para nosotros.
            let manifestData = try Data(contentsOf: manifestURL)
            let manifest = try JSONDecoder().decode(Manifest.self, from: manifestData)
            
            // 2. Iteramos sobre los assets definidos en el manifest.
            for assetInfo in manifest.assets {
                guard let assetURL = URL(string: assetInfo.url) else { continue }
                
                // 3. Creamos un objeto BAURLDownload para cada asset.
                // Usamos el inicializador moderno y correcto.
                let download = BAURLDownload(
                    identifier: assetInfo.id,
                    request: URLRequest(url: assetURL),
                    // Durante una instalación/actualización desde la App Store, los assets son esenciales.
                    // Para una actualización periódica en segundo plano, no lo son.
                    essential: request == .install || request == .update,
                    fileSize: oneMB, // Tamaño estimado
                    applicationGroupIdentifier: AppConstants.appGroupIdentifier,
                    priority: .default
                )
                downloadsToSchedule.insert(download)
            }
        } catch {
            Logger().error("Fallo al procesar el manifiesto: \(error.localizedDescription)")
            return [] // Si hay un error, no programamos ninguna descarga.
        }
        
        Logger().log("La extensión de segundo plano ha programado \(downloadsToSchedule.count) descargas.")
        return downloadsToSchedule
    }

    func backgroundDownload(_ failedDownload: BADownload, failedWithError error: Error) {
        // El sistema nos informa si una de las descargas en segundo plano falló.
        Logger().error("Descarga en segundo plano fallida para \(failedDownload.identifier): \(error.localizedDescription)")
    }

    func backgroundDownload(_ finishedDownload: BADownload, finishedWithFileURL fileURL: URL) {
        // El sistema nos informa que una descarga ha terminado y nos da la ubicación del archivo temporal.
        
        // 1. Obtenemos la URL de nuestro contenedor compartido (App Group).
        guard let appGroupContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier) else {
            Logger().error("No se pudo obtener el contenedor del App Group.")
            return
        }
        
        // 2. Obtenemos el nombre de archivo final que corresponde a esta descarga.
        guard let destinationFilename = filename(for: finishedDownload.identifier) else {
            Logger().error("Descarga finalizada con un identificador desconocido: \(finishedDownload.identifier)")
            return
        }
        
        let destinationURL = appGroupContainer.appendingPathComponent(destinationFilename)
        
        // 3. Movemos el archivo desde la ubicación temporal a nuestro contenedor.
        do {
            // Si ya existe una versión antigua del archivo, la eliminamos primero.
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: fileURL, to: destinationURL)
            Logger().log("Archivo \(destinationFilename) movido exitosamente al App Group.")
            
            // NOTA: En este punto, el archivo está listo. La próxima vez que el usuario abra la app,
            // el DataManager cargará automáticamente este nuevo archivo.
            
        } catch {
            Logger().error("Fallo al mover el archivo descargado: \(error.localizedDescription)")
        }
    }
}
