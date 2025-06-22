import BackgroundAssets
import os.log

// Modelos para decodificar el manifest.json
struct Manifest: Codable {
    let assets: [AssetInfo]
}
struct AssetInfo: Codable {
    let id: String
    let url: String
}

@main
struct BackgroundDownloadHandler: BADownloaderExtension {
    
    // Este es el único método donde se define la lógica de descarga.
    func downloads(for request: BAContentRequest, manifestURL: URL, extensionInfo: BAAppExtensionInfo) -> Set<BADownload> {
        var downloadsToSchedule = Set<BADownload>()
        let oneMB = 1024 * 1024
        
        do {
            // 1. Leer y decodificar el manifest.json completo.
            let manifestData = try Data(contentsOf: manifestURL)
            let manifest = try JSONDecoder().decode(Manifest.self, from: manifestData)
            
            // 2. Iterar sobre CADA asset (JSONs e imágenes) y crear una descarga.
            for assetInfo in manifest.assets {
                guard let assetURL = URL(string: assetInfo.url) else { continue }
                
                let download = BAURLDownload(
                    identifier: assetInfo.id,
                    request: URLRequest(url: assetURL),
                    essential: request == .install || request == .update,
                    fileSize: oneMB,
                    applicationGroupIdentifier: AppConstants.appGroupIdentifier,
                    priority: .default
                )
                downloadsToSchedule.insert(download)
            }
        } catch {
            Logger().error("Fallo al procesar el manifiesto: \(error.localizedDescription)")
            return []
        }
        
        Logger().log("Extensión: Programando \(downloadsToSchedule.count) descargas desde el manifiesto.")
        return downloadsToSchedule // Devuelve la lista completa al sistema.
    }

    // Este método solo se encarga de mover archivos, sin lógica adicional.
    func backgroundDownload(_ finishedDownload: BADownload, finishedWithFileURL fileURL: URL) {
        guard let appGroupContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier) else {
            Logger().error("No se pudo obtener el contenedor del App Group.")
            return
        }
        
        guard let destinationURL = destinationURL(for: finishedDownload.identifier, in: appGroupContainer) else {
            Logger().error("Descarga finalizada con un identificador desconocido: \(finishedDownload.identifier)")
            return
        }
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: fileURL, to: destinationURL)
            Logger().log("Archivo para ID \(finishedDownload.identifier) movido exitosamente.")
        } catch {
            Logger().error("Fallo al mover el archivo descargado: \(error.localizedDescription)")
        }
    }
    
    // Función de ayuda para determinar la ruta final (sin cambios).
    private func destinationURL(for identifier: String, in container: URL) -> URL? {
        let imageIDPrefix = "com.jimscope.zenith-fit.image."
        if identifier.hasPrefix(imageIDPrefix) {
            let heroName = identifier.dropFirst(imageIDPrefix.count)
            let imageDirectory = container.appendingPathComponent("images")
            try? FileManager.default.createDirectory(at: imageDirectory, withIntermediateDirectories: true, attributes: nil)
            return imageDirectory.appendingPathComponent("\(heroName).jpg")
        } else {
            switch identifier {
            case AppConstants.workoutsID: return container.appendingPathComponent("workouts.json")
            case AppConstants.definitionsID: return container.appendingPathComponent("definitions.json")
            case AppConstants.descriptionsID: return container.appendingPathComponent("descriptions.json")
            default: return nil
            }
        }
    }

    func backgroundDownload(_ failedDownload: BADownload, failedWithError error: Error) {
        Logger().error("Descarga en segundo plano fallida para \(failedDownload.identifier): \(error.localizedDescription)")
    }
}