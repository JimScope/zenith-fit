//
//  DataManager.swift
//  batman
//
//  Created by Jimmy Angel Pérez Díaz on 6/14/25.
//

import Foundation

class DataManager {
    static let shared = DataManager()

    // Carga un archivo JSON del bundle y lo decodifica en un tipo genérico T
    private func load<T: Decodable>(_ filename: String) -> T {
        guard let file = Bundle.main.url(forResource: filename, withExtension: nil) else {
            fatalError("No se pudo encontrar el archivo \(filename) en el bundle.")
        }
        guard let data = try? Data(contentsOf: file) else {
            fatalError("No se pudo cargar el archivo \(filename) del bundle.")
        }
        guard let decodedData = try? JSONDecoder().decode(T.self, from: data) else {
            fatalError("No se pudo decodificar el archivo \(filename).")
        }
        return decodedData
    }

    // Propiedades para acceder a los datos ya decodificados
    lazy var definitions: [Definition] = load("definitions.json")
    lazy var descriptions: [String: String] = load("descriptions.json")
    lazy var plan: [WeeklyPlan] = load("plan.json")
}
