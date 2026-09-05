//
//  OpenMeteoClient.swift
//  Weather
//

import Foundation

enum OpenMeteoClient {
    enum ClientError: LocalizedError {
        case badURL
        case server(String)
        case empty

        var errorDescription: String? {
            switch self {
            case .badURL: "Could not build the weather request."
            case .server(let reason): reason
            case .empty: "No weather data was returned."
            }
        }
    }

    private static let forecastBase = URL(string: "https://api.open-meteo.com/v1/forecast")!
    private static let airQualityBase = URL(string: "https://air-quality-api.open-meteo.com/v1/air-quality")!
    private static let geocodeBase = URL(string: "https://geocoding-api.open-meteo.com/v1/search")!

    static func forecast(latitude: Double, longitude: Double, units: UnitSystem) async throws -> ForecastResponse {
        var components = URLComponents(url: forecastBase, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "timeformat", value: "unixtime"),
            URLQueryItem(name: "forecast_days", value: "10"),
            URLQueryItem(name: "forecast_minutely_15", value: "24"),
            URLQueryItem(name: "temperature_unit", value: units == .metric ? "celsius" : "fahrenheit"),
            URLQueryItem(name: "wind_speed_unit", value: units == .metric ? "kmh" : "mph"),
            URLQueryItem(name: "precipitation_unit", value: units == .metric ? "mm" : "inch"),
            URLQueryItem(name: "current", value: [
                "temperature_2m", "relative_humidity_2m", "apparent_temperature", "is_day",
                "precipitation", "rain", "showers", "snowfall", "weather_code", "cloud_cover",
                "pressure_msl", "surface_pressure", "wind_speed_10m", "wind_direction_10m",
                "wind_gusts_10m", "visibility", "dew_point_2m", "cape", "snow_depth", "freezing_level_height"
            ].joined(separator: ",")),
            URLQueryItem(name: "hourly", value: [
                "temperature_2m", "relative_humidity_2m", "dew_point_2m", "apparent_temperature",
                "precipitation_probability", "precipitation", "rain", "showers", "snowfall",
                "weather_code", "pressure_msl", "cloud_cover", "visibility", "wind_speed_10m",
                "wind_direction_10m", "wind_gusts_10m", "uv_index", "cape", "is_day"
            ].joined(separator: ",")),
            URLQueryItem(name: "daily", value: [
                "weather_code", "temperature_2m_max", "temperature_2m_min",
                "apparent_temperature_max", "apparent_temperature_min", "sunrise", "sunset",
                "daylight_duration", "sunshine_duration", "uv_index_max", "precipitation_sum",
                "rain_sum", "showers_sum", "snowfall_sum", "precipitation_hours",
                "precipitation_probability_max", "wind_speed_10m_max", "wind_gusts_10m_max",
                "wind_direction_10m_dominant"
            ].joined(separator: ",")),
            URLQueryItem(name: "minutely_15", value: [
                "precipitation", "rain", "snowfall", "weather_code", "cape", "lightning_potential"
            ].joined(separator: ","))
        ]
        return try await get(components?.url, as: ForecastResponse.self)
    }

    static func airQuality(latitude: Double, longitude: Double) async throws -> AirQuality {
        var components = URLComponents(url: airQualityBase, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "current", value: "us_aqi,european_aqi,pm2_5,pm10,ozone,nitrogen_dioxide,alder_pollen,birch_pollen,grass_pollen,mugwort_pollen,olive_pollen,ragweed_pollen")
        ]
        let response = try await get(components?.url, as: AirQualityResponse.self)
        guard let current = response.current else { throw ClientError.empty }
        return AirQuality(
            usAqi: current.usAqi,
            europeanAqi: current.europeanAqi,
            pm25: current.pm25,
            pm10: current.pm10,
            ozone: current.ozone,
            nitrogenDioxide: current.nitrogenDioxide,
            alderPollen: current.alderPollen,
            birchPollen: current.birchPollen,
            grassPollen: current.grassPollen,
            mugwortPollen: current.mugwortPollen,
            olivePollen: current.olivePollen,
            ragweedPollen: current.ragweedPollen
        )
    }

    static func searchPlaces(_ query: String) async throws -> [GeocodingResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }
        var components = URLComponents(url: geocodeBase, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "name", value: trimmed),
            URLQueryItem(name: "count", value: "8"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json")
        ]
        let response = try await get(components?.url, as: GeocodingResponse.self)
        return response.results ?? []
    }

    private static func get<T: Decodable>(_ url: URL?, as type: T.Type) async throws -> T {
        guard let url else { throw ClientError.badURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            let body = try? JSONDecoder().decode(APIErrorBody.self, from: data)
            throw ClientError.server(body?.reason ?? "Weather service returned \(http.statusCode).")
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            if let body = try? JSONDecoder().decode(APIErrorBody.self, from: data), let reason = body.reason {
                throw ClientError.server(reason)
            }
            throw error
        }
    }
}
