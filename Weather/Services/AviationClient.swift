//
//  AviationClient.swift
//  Weather
//

import Foundation

enum AviationClient {
    enum ClientError: LocalizedError {
        case badURL
        case notFound(String)
        case server

        var errorDescription: String? {
            switch self {
            case .badURL: "Could not build the aviation request."
            case .notFound(let icao): "No METAR found for \(icao)."
            case .server: "Aviation Weather Center is unavailable."
            }
        }
    }

    private static let metarURL = URL(string: "https://aviationweather.gov/api/data/metar")!
    private static let tafURL = URL(string: "https://aviationweather.gov/api/data/taf")!

    static func briefing(icao raw: String) async throws -> AviationBriefing {
        let candidates = identifiers(for: raw)
        var lastError: Error = ClientError.notFound(raw)
        for code in candidates {
            do {
                async let metarTask = get([MetarJSON].self, url: metarURL, ids: code)
                async let tafTask = get([TafJSON].self, url: tafURL, ids: code)
                let metars = try await metarTask
                let tafs = (try? await tafTask) ?? []
                if let metar = metars.first, let rawMetar = metar.rawOb, !rawMetar.isEmpty {
                    return map(icao: code, metar: metar, taf: tafs.first)
                }
                lastError = ClientError.notFound(code)
            } catch {
                lastError = error
            }
        }
        throw lastError
    }

    private static func identifiers(for raw: String) -> [String] {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if trimmed.count == 3, trimmed.allSatisfy(\.isLetter) {
            return [trimmed, "K\(trimmed)"]
        }
        return [trimmed]
    }

    static func nearest(latitude: Double, longitude: Double) async throws -> AviationBriefing {
        let delta = 0.85
        let bbox = "\(latitude - delta),\(longitude - delta),\(latitude + delta),\(longitude + delta)"
        var components = URLComponents(url: metarURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "bbox", value: bbox),
            URLQueryItem(name: "format", value: "json")
        ]
        let metars = try await fetch([MetarJSON].self, from: components?.url)
        let closest = metars.min { lhs, rhs in
            distance(latitude, longitude, lhs.lat ?? latitude, lhs.lon ?? longitude)
                < distance(latitude, longitude, rhs.lat ?? latitude, rhs.lon ?? longitude)
        }
        guard let closest, let icao = closest.icaoId else {
            throw ClientError.notFound("nearby")
        }
        return try await briefing(icao: icao)
    }

    private static func map(icao: String, metar: MetarJSON, taf: TafJSON?) -> AviationBriefing {
        let windDir = metar.wdir?.text ?? "VRB"
        let speed = metar.wspd.map { "\(Int($0.rounded())) kt" } ?? "calm"
        let gust = metar.wgst.map { " gusting \(Int($0.rounded())) kt" } ?? ""
        let wind = metar.wspd == nil ? "Calm" : "\(windDir == "0" ? "Variable" : "\(windDir)°") at \(speed)\(gust)"

        let altimeter: String
        if let hPa = metar.altim {
            let inches = hPa * 0.02953
            altimeter = String(format: "%.2f inHg · %.0f hPa", inches, hPa)
        } else {
            altimeter = "—"
        }

        let clouds = (metar.clouds ?? []).map(\.summary)
        let observed = metar.obsTime.map { Date(timeIntervalSince1970: $0) }

        return AviationBriefing(
            icao: metar.icaoId ?? icao,
            name: metar.name ?? taf?.name ?? icao,
            latitude: metar.lat,
            longitude: metar.lon,
            observedAt: observed,
            flightCategory: FlightCategory(rawValue: metar.fltCat ?? "") ?? .unknown,
            temperatureC: metar.temp,
            dewpointC: metar.dewp,
            wind: wind,
            visibility: "\(metar.visib?.text ?? "—") SM",
            altimeter: altimeter,
            weather: metar.wxString?.isEmpty == false ? (metar.wxString ?? "Nil") : "No significant weather",
            clouds: clouds.isEmpty ? ["Clear / no ceiling"] : clouds,
            rawMetar: metar.rawOb ?? "",
            rawTaf: taf?.rawTAF,
            tafPeriods: taf?.fcsts ?? [],
            validFrom: taf?.validTimeFrom.map { Date(timeIntervalSince1970: $0) },
            validTo: taf?.validTimeTo.map { Date(timeIntervalSince1970: $0) }
        )
    }

    private static func get<T: Decodable>(_ type: T.Type, url: URL, ids: String) async throws -> T {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "ids", value: ids),
            URLQueryItem(name: "format", value: "json")
        ]
        return try await fetch(type, from: components?.url)
    }

    private static func fetch<T: Decodable>(_ type: T.Type, from url: URL?) async throws -> T {
        guard let url else { throw ClientError.badURL }
        var request = URLRequest(url: url)
        request.setValue("PineDevWeather/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode == 204 || data.isEmpty {
            throw ClientError.notFound("station")
        }
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            throw ClientError.server
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private static func distance(_ lat1: Double, _ lon1: Double, _ lat2: Double, _ lon2: Double) -> Double {
        let dLat = lat1 - lat2
        let dLon = lon1 - lon2
        return dLat * dLat + dLon * dLon
    }
}
