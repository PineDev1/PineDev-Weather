//
//  APIModels.swift
//  Weather
//

import Foundation

struct ForecastResponse: Decodable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let utcOffsetSeconds: Int
    let current: CurrentBlock
    let hourly: HourlyBlock
    let daily: DailyBlock
    let minutely15: MinutelyBlock?

    enum CodingKeys: String, CodingKey {
        case latitude, longitude, timezone, current, hourly, daily
        case utcOffsetSeconds = "utc_offset_seconds"
        case minutely15 = "minutely_15"
    }
}

struct CurrentBlock: Decodable {
    let time: Int
    let temperature2m: Double
    let relativeHumidity2m: Double?
    let apparentTemperature: Double?
    let isDay: Int
    let precipitation: Double?
    let rain: Double?
    let showers: Double?
    let snowfall: Double?
    let weatherCode: Int
    let cloudCover: Double?
    let pressureMsl: Double?
    let surfacePressure: Double?
    let windSpeed10m: Double?
    let windDirection10m: Double?
    let windGusts10m: Double?
    let visibility: Double?
    let dewPoint2m: Double?
    let cape: Double?
    let snowDepth: Double?
    let freezingLevelHeight: Double?

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case relativeHumidity2m = "relative_humidity_2m"
        case apparentTemperature = "apparent_temperature"
        case isDay = "is_day"
        case precipitation, rain, showers, snowfall
        case weatherCode = "weather_code"
        case cloudCover = "cloud_cover"
        case pressureMsl = "pressure_msl"
        case surfacePressure = "surface_pressure"
        case windSpeed10m = "wind_speed_10m"
        case windDirection10m = "wind_direction_10m"
        case windGusts10m = "wind_gusts_10m"
        case visibility
        case dewPoint2m = "dew_point_2m"
        case cape
        case snowDepth = "snow_depth"
        case freezingLevelHeight = "freezing_level_height"
    }
}

struct HourlyBlock: Decodable {
    let time: [Int]
    let temperature2m: [Double]
    let relativeHumidity2m: [Double]
    let dewPoint2m: [Double]
    let apparentTemperature: [Double]
    let precipitationProbability: [Double]
    let precipitation: [Double]
    let rain: [Double]
    let showers: [Double]
    let snowfall: [Double]
    let weatherCode: [Int]
    let pressureMsl: [Double]
    let cloudCover: [Double]
    let visibility: [Double]
    let windSpeed10m: [Double]
    let windDirection10m: [Double]
    let windGusts10m: [Double]
    let uvIndex: [Double]
    let cape: [Double]
    let isDay: [Int]

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case relativeHumidity2m = "relative_humidity_2m"
        case dewPoint2m = "dew_point_2m"
        case apparentTemperature = "apparent_temperature"
        case precipitationProbability = "precipitation_probability"
        case precipitation, rain, showers, snowfall
        case weatherCode = "weather_code"
        case pressureMsl = "pressure_msl"
        case cloudCover = "cloud_cover"
        case visibility
        case windSpeed10m = "wind_speed_10m"
        case windDirection10m = "wind_direction_10m"
        case windGusts10m = "wind_gusts_10m"
        case uvIndex = "uv_index"
        case cape
        case isDay = "is_day"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        time = try container.decode([Int].self, forKey: .time)
        temperature2m = Self.doubles(container, .temperature2m)
        relativeHumidity2m = Self.doubles(container, .relativeHumidity2m)
        dewPoint2m = Self.doubles(container, .dewPoint2m)
        apparentTemperature = Self.doubles(container, .apparentTemperature)
        precipitationProbability = Self.doubles(container, .precipitationProbability)
        precipitation = Self.doubles(container, .precipitation)
        rain = Self.doubles(container, .rain)
        showers = Self.doubles(container, .showers)
        snowfall = Self.doubles(container, .snowfall)
        weatherCode = Self.ints(container, .weatherCode)
        pressureMsl = Self.doubles(container, .pressureMsl)
        cloudCover = Self.doubles(container, .cloudCover)
        visibility = Self.doubles(container, .visibility)
        windSpeed10m = Self.doubles(container, .windSpeed10m)
        windDirection10m = Self.doubles(container, .windDirection10m)
        windGusts10m = Self.doubles(container, .windGusts10m)
        uvIndex = Self.doubles(container, .uvIndex)
        cape = Self.doubles(container, .cape)
        isDay = Self.ints(container, .isDay)
    }

    private static func doubles(_ container: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> [Double] {
        (try? container.decode([Double?].self, forKey: key))?.map { $0 ?? .nan } ?? []
    }

    private static func ints(_ container: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> [Int] {
        if let values = try? container.decode([Int?].self, forKey: key) {
            return values.map { $0 ?? 0 }
        }
        if let values = try? container.decode([Double?].self, forKey: key) {
            return values.map { Int($0 ?? 0) }
        }
        return []
    }
}

struct DailyBlock: Decodable {
    let time: [Int]
    let weatherCode: [Int]
    let temperature2mMax: [Double]
    let temperature2mMin: [Double]
    let apparentTemperatureMax: [Double]
    let apparentTemperatureMin: [Double]
    let sunrise: [Int]
    let sunset: [Int]
    let daylightDuration: [Double]
    let sunshineDuration: [Double]
    let uvIndexMax: [Double]
    let precipitationSum: [Double]
    let rainSum: [Double]
    let showersSum: [Double]
    let snowfallSum: [Double]
    let precipitationHours: [Double]
    let precipitationProbabilityMax: [Double]
    let windSpeed10mMax: [Double]
    let windGusts10mMax: [Double]
    let windDirection10mDominant: [Double]

    enum CodingKeys: String, CodingKey {
        case time
        case weatherCode = "weather_code"
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
        case apparentTemperatureMax = "apparent_temperature_max"
        case apparentTemperatureMin = "apparent_temperature_min"
        case sunrise, sunset
        case daylightDuration = "daylight_duration"
        case sunshineDuration = "sunshine_duration"
        case uvIndexMax = "uv_index_max"
        case precipitationSum = "precipitation_sum"
        case rainSum = "rain_sum"
        case showersSum = "showers_sum"
        case snowfallSum = "snowfall_sum"
        case precipitationHours = "precipitation_hours"
        case precipitationProbabilityMax = "precipitation_probability_max"
        case windSpeed10mMax = "wind_speed_10m_max"
        case windGusts10mMax = "wind_gusts_10m_max"
        case windDirection10mDominant = "wind_direction_10m_dominant"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        time = try container.decode([Int].self, forKey: .time)
        weatherCode = Self.ints(container, .weatherCode)
        temperature2mMax = Self.doubles(container, .temperature2mMax)
        temperature2mMin = Self.doubles(container, .temperature2mMin)
        apparentTemperatureMax = Self.doubles(container, .apparentTemperatureMax)
        apparentTemperatureMin = Self.doubles(container, .apparentTemperatureMin)
        sunrise = Self.ints(container, .sunrise)
        sunset = Self.ints(container, .sunset)
        daylightDuration = Self.doubles(container, .daylightDuration)
        sunshineDuration = Self.doubles(container, .sunshineDuration)
        uvIndexMax = Self.doubles(container, .uvIndexMax)
        precipitationSum = Self.doubles(container, .precipitationSum)
        rainSum = Self.doubles(container, .rainSum)
        showersSum = Self.doubles(container, .showersSum)
        snowfallSum = Self.doubles(container, .snowfallSum)
        precipitationHours = Self.doubles(container, .precipitationHours)
        precipitationProbabilityMax = Self.doubles(container, .precipitationProbabilityMax)
        windSpeed10mMax = Self.doubles(container, .windSpeed10mMax)
        windGusts10mMax = Self.doubles(container, .windGusts10mMax)
        windDirection10mDominant = Self.doubles(container, .windDirection10mDominant)
    }

    private static func doubles(_ container: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> [Double] {
        (try? container.decode([Double?].self, forKey: key))?.map { $0 ?? .nan } ?? []
    }

    private static func ints(_ container: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> [Int] {
        if let values = try? container.decode([Int?].self, forKey: key) {
            return values.map { $0 ?? 0 }
        }
        if let values = try? container.decode([Double?].self, forKey: key) {
            return values.map { Int($0 ?? 0) }
        }
        return []
    }
}

struct MinutelyBlock: Decodable {
    let time: [Int]
    let precipitation: [Double]
    let rain: [Double]
    let snowfall: [Double]
    let weatherCode: [Int]
    let cape: [Double]
    let lightningPotential: [Double]

    enum CodingKeys: String, CodingKey {
        case time, precipitation, rain, snowfall
        case weatherCode = "weather_code"
        case cape
        case lightningPotential = "lightning_potential"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        time = try container.decode([Int].self, forKey: .time)
        precipitation = Self.doubles(container, .precipitation)
        rain = Self.doubles(container, .rain)
        snowfall = Self.doubles(container, .snowfall)
        weatherCode = Self.ints(container, .weatherCode)
        cape = Self.doubles(container, .cape)
        lightningPotential = Self.doubles(container, .lightningPotential)
    }

    private static func doubles(_ container: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> [Double] {
        (try? container.decode([Double?].self, forKey: key))?.map { $0 ?? .nan } ?? []
    }

    private static func ints(_ container: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> [Int] {
        if let values = try? container.decode([Int?].self, forKey: key) {
            return values.map { $0 ?? 0 }
        }
        if let values = try? container.decode([Double?].self, forKey: key) {
            return values.map { Int($0 ?? 0) }
        }
        return []
    }
}

struct AirQualityResponse: Decodable {
    let current: AirQualityCurrent?
}

struct AirQualityCurrent: Decodable {
    let usAqi: Double?
    let europeanAqi: Double?
    let pm25: Double?
    let pm10: Double?
    let ozone: Double?
    let nitrogenDioxide: Double?
    let alderPollen: Double?
    let birchPollen: Double?
    let grassPollen: Double?
    let mugwortPollen: Double?
    let olivePollen: Double?
    let ragweedPollen: Double?

    enum CodingKeys: String, CodingKey {
        case usAqi = "us_aqi"
        case europeanAqi = "european_aqi"
        case pm25 = "pm2_5"
        case pm10
        case ozone
        case nitrogenDioxide = "nitrogen_dioxide"
        case alderPollen = "alder_pollen"
        case birchPollen = "birch_pollen"
        case grassPollen = "grass_pollen"
        case mugwortPollen = "mugwort_pollen"
        case olivePollen = "olive_pollen"
        case ragweedPollen = "ragweed_pollen"
    }
}

struct GeocodingResponse: Decodable {
    let results: [GeocodingResult]?
}

struct GeocodingResult: Decodable, Identifiable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String?
    let countryCode: String?
    let admin1: String?
    let timezone: String?

    enum CodingKeys: String, CodingKey {
        case id, name, latitude, longitude, country, timezone, admin1
        case countryCode = "country_code"
    }

    var subtitle: String {
        [admin1, country].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
    }
}

struct APIErrorBody: Decodable {
    let reason: String?
}

struct RadarMapsResponse: Decodable {
    let host: String
    let radar: RadarPayload
}

struct RadarPayload: Decodable {
    let past: [RadarFrame]
    let nowcast: [RadarFrame]?
}

struct RadarFrame: Decodable, Identifiable, Hashable {
    let time: Int
    let path: String

    var id: Int { time }
    var date: Date { Date(timeIntervalSince1970: TimeInterval(time)) }
}
