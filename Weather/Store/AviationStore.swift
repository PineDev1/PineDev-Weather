//
//  AviationStore.swift
//  Weather
//

import Foundation

@Observable
final class AviationStore {
    var query = ""
    var briefing: AviationBriefing?
    var recents: [String] = []
    var isLoading = false
    var errorMessage: String?

    private let defaults = UserDefaults.standard

    init() {
        recents = defaults.stringArray(forKey: Keys.recents) ?? ["KDEN", "KJFK", "KLAX", "EGLL"]
        query = recents.first ?? "KDEN"
    }

    func lookup(_ raw: String) async {
        let code = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard code.count >= 3 else { return }
        isLoading = briefing == nil
        errorMessage = nil
        do {
            let result = try await AviationClient.briefing(icao: code)
            briefing = result
            query = result.icao
            remember(result.icao)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func lookupNearest(latitude: Double, longitude: Double) async {
        isLoading = briefing == nil
        errorMessage = nil
        do {
            let result = try await AviationClient.nearest(latitude: latitude, longitude: longitude)
            briefing = result
            query = result.icao
            remember(result.icao)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func remember(_ icao: String) {
        recents.removeAll { $0 == icao }
        recents.insert(icao, at: 0)
        recents = Array(recents.prefix(8))
        defaults.set(recents, forKey: Keys.recents)
    }

    private enum Keys {
        static let recents = "pinedev.weather.aviation.recents"
    }
}
