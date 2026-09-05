//
//  DomainModels.swift
//  Weather
//

import Foundation

enum UnitSystem: String, CaseIterable, Codable {
    case imperial
    case metric

    static var fromLocale: UnitSystem {
        Locale.current.measurementSystem == .metric ? .metric : .imperial
    }

    var temperatureSymbol: String { self == .metric ? "C" : "F" }
    var speedSymbol: String { self == .metric ? "km/h" : "mph" }
    var precipSymbol: String { self == .metric ? "mm" : "in" }
}

struct Place: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var detail: String
    var latitude: Double
    var longitude: Double
    var isCurrentLocation: Bool

    static let currentID = "current"

    static func current(name: String, detail: String, latitude: Double, longitude: Double) -> Place {
        Place(
            id: currentID,
            name: name,
            detail: detail,
            latitude: latitude,
            longitude: longitude,
            isCurrentLocation: true
        )
    }

    static func fromGeocoding(_ result: GeocodingResult) -> Place {
        Place(
            id: String(result.id),
            name: result.name,
            detail: result.subtitle,
            latitude: result.latitude,
            longitude: result.longitude,
            isCurrentLocation: false
        )
    }
}

struct CurrentConditions {
    var date: Date
    var temperature: Double
    var apparentTemperature: Double
    var humidity: Double
    var isDay: Bool
    var precipitation: Double
    var rain: Double
    var snowfall: Double
    var weatherCode: Int
    var cloudCover: Double
    var pressure: Double
    var windSpeed: Double
    var windDirection: Double
    var windGusts: Double
    var visibility: Double
    var dewPoint: Double
    var cape: Double
    var snowDepth: Double?
    var freezingLevel: Double?

    var summary: String { WeatherCode.summary(weatherCode) }
    var symbolName: String { WeatherCode.symbol(weatherCode, isDay: isDay) }
}

struct HourlyForecast: Identifiable {
    var date: Date
    var temperature: Double
    var apparentTemperature: Double
    var humidity: Double
    var dewPoint: Double
    var precipProbability: Double
    var precipitation: Double
    var rain: Double
    var snowfall: Double
    var weatherCode: Int
    var pressure: Double
    var cloudCover: Double
    var visibility: Double
    var windSpeed: Double
    var windDirection: Double
    var windGusts: Double
    var uvIndex: Double
    var cape: Double
    var isDay: Bool

    var id: TimeInterval { date.timeIntervalSince1970 }
    var symbolName: String { WeatherCode.symbol(weatherCode, isDay: isDay) }
}

struct DailyForecast: Identifiable {
    var date: Date
    var weatherCode: Int
    var high: Double
    var low: Double
    var apparentHigh: Double
    var apparentLow: Double
    var sunrise: Date
    var sunset: Date
    var daylight: TimeInterval
    var sunshine: TimeInterval
    var uvIndexMax: Double
    var precipitation: Double
    var rain: Double
    var snowfall: Double
    var precipHours: Double
    var precipProbability: Double
    var windMax: Double
    var gustMax: Double
    var windDirection: Double

    var id: TimeInterval { date.timeIntervalSince1970 }
    var symbolName: String { WeatherCode.symbol(weatherCode, isDay: true) }
}

struct MinutelyPrecip: Identifiable {
    var date: Date
    var precipitation: Double
    var rain: Double
    var snowfall: Double
    var weatherCode: Int
    var cape: Double
    var lightningPotential: Double

    var id: TimeInterval { date.timeIntervalSince1970 }
}

struct AirQuality {
    var usAqi: Double?
    var europeanAqi: Double?
    var pm25: Double?
    var pm10: Double?
    var ozone: Double?
    var nitrogenDioxide: Double?
    var alderPollen: Double?
    var birchPollen: Double?
    var grassPollen: Double?
    var mugwortPollen: Double?
    var olivePollen: Double?
    var ragweedPollen: Double?

    var displayIndex: Double? { usAqi ?? europeanAqi }

    var category: String {
        guard let value = displayIndex else { return "—" }
        switch value {
        case ..<51: return "Good"
        case ..<101: return "Moderate"
        case ..<151: return "Unhealthy for sensitive"
        case ..<201: return "Unhealthy"
        case ..<301: return "Very unhealthy"
        default: return "Hazardous"
        }
    }

    var pollenLevel: (name: String, value: Double)? {
        let grains = [
            ("Alder", alderPollen), ("Birch", birchPollen), ("Grass", grassPollen),
            ("Mugwort", mugwortPollen), ("Olive", olivePollen), ("Ragweed", ragweedPollen)
        ].compactMap { name, value -> (String, Double)? in
            guard let value, value.isFinite, value > 0 else { return nil }
            return (name, value)
        }
        return grains.max(by: { $0.1 < $1.1 })
    }

    var pollenCategory: String {
        guard let value = pollenLevel?.value else { return "None reported" }
        switch value {
        case ..<10: return "Low"
        case ..<50: return "Moderate"
        case ..<100: return "High"
        default: return "Very high"
        }
    }
}

struct WeatherSnapshot {
    var place: Place
    var timezone: TimeZone
    var units: UnitSystem
    var current: CurrentConditions
    var hourly: [HourlyForecast]
    var daily: [DailyForecast]
    var minutely: [MinutelyPrecip]
    var airQuality: AirQuality?
    var fetchedAt: Date

    var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = timezone
        return value
    }

    var today: DailyForecast? {
        daily.first { calendar.isDate($0.date, inSameDayAs: Date()) } ?? daily.first
    }

    var upcomingHourly: [HourlyForecast] {
        let start = Date().addingTimeInterval(-30 * 60)
        return Array(hourly.filter { $0.date >= start }.prefix(48))
    }

    var next24Hours: [HourlyForecast] {
        Array(upcomingHourly.prefix(24))
    }

    var activeStorm: Bool {
        WeatherCode.isThunderstorm(current.weatherCode)
    }

    var upcomingStorm: HourlyForecast? {
        upcomingHourly.prefix(18).first { WeatherCode.isThunderstorm($0.weatherCode) }
    }

    var stormRisk: String? {
        if activeStorm { return "Thunderstorms in the area" }
        if let storm = upcomingStorm {
            return "Thunderstorms around \(Self.hourFormatter.string(from: storm.date))"
        }
        let maxCape = upcomingHourly.prefix(12).map(\.cape).max() ?? 0
        if maxCape >= 1500 { return "High thunderstorm potential" }
        if maxCape >= 800 { return "Elevated thunderstorm risk" }
        return nil
    }

    var rainStory: String {
        let nowPrecip = current.precipitation
        if nowPrecip > 0.05 {
            if WeatherCode.isSnow(current.weatherCode) { return "Snow is falling now." }
            if WeatherCode.isThunderstorm(current.weatherCode) { return "Storms are producing rain now." }
            return "Rain is falling now."
        }

        if let next = minutely.first(where: { $0.date > Date() && $0.precipitation > 0.05 }) {
            let minutes = max(1, Int(next.date.timeIntervalSinceNow / 60))
            if WeatherCode.isSnow(next.weatherCode) {
                return minutes < 60 ? "Snow expected in \(minutes) min." : "Snow expected later this hour."
            }
            return minutes < 60 ? "Rain expected in \(minutes) min." : "Rain expected soon."
        }

        if let hour = upcomingHourly.prefix(12).first(where: { $0.precipitation > 0.1 || $0.precipProbability >= 50 }) {
            let label = Self.hourFormatter.string(from: hour.date)
            if WeatherCode.isSnow(hour.weatherCode) { return "Snow likely around \(label)." }
            if WeatherCode.isThunderstorm(hour.weatherCode) { return "Storms likely around \(label)." }
            return "Rain likely around \(label)."
        }

        if daily.prefix(3).contains(where: { $0.precipProbability >= 40 || $0.precipitation > 0.1 }) {
            return "Dry for now, rain returns later in the forecast."
        }

        return "No rain expected for the next 12 hours."
    }

    var alerts: [WeatherAlert] {
        var items: [WeatherAlert] = []
        if activeStorm {
            items.append(.init(id: "storm-now", title: "Thunderstorms", detail: "Lightning in the area. Limit outdoor exposure.", severity: .warning))
        } else if let storm = upcomingStorm {
            items.append(.init(id: "storm-soon", title: "Storm watch", detail: "Thunderstorms possible around \(Self.hourFormatter.string(from: storm.date)).", severity: .watch))
        }
        let gust = current.windGusts
        if gust >= (units == .metric ? 70 : 45) {
            items.append(.init(id: "wind", title: "High wind", detail: "Gusts \(Int(gust.rounded())) \(units.speedSymbol). Secure loose objects.", severity: .advisory))
        }
        if current.visibility.isFinite, current.visibility < 1600 {
            items.append(.init(id: "fog", title: "Low visibility", detail: "\(Formatters.visibility(current.visibility, units: units)). Slow down if driving.", severity: .advisory))
        }
        let freeze = units == .metric ? 0.0 : 32.0
        if let today, today.low <= freeze {
            items.append(.init(id: "freeze", title: "Freeze possible", detail: "Low \(Formatters.temperature(today.low)) overnight. Watch for icy surfaces.", severity: .advisory))
        }
        let heat = units == .metric ? 33.0 : 92.0
        if current.temperature >= heat {
            items.append(.init(id: "heat", title: "Heat", detail: "It's \(Formatters.temperature(current.temperature)) outside. Hydrate and limit midday sun.", severity: .advisory))
        }
        if let uv = today?.uvIndexMax, uv >= 8 {
            items.append(.init(id: "uv", title: "Very high UV", detail: "UV \(Int(uv.rounded())). Sunscreen and shade this afternoon.", severity: .advisory))
        }
        if WeatherCode.isSnow(current.weatherCode), current.snowfall > 0.05 {
            items.append(.init(id: "snow", title: "Snow", detail: "Snow is falling. Allow extra travel time.", severity: .watch))
        }
        return items
    }

    var moon: MoonPhase { MoonPhase.at(Date()) }

    var comfort: String {
        if current.humidity >= 80, current.temperature >= (units == .metric ? 22 : 72) {
            return "Muggy. It will feel heavier than the thermometer shows."
        }
        if current.humidity <= 30 {
            return "Dry air. Skin and sinuses may feel it."
        }
        if current.apparentTemperature <= current.temperature - 4 {
            return "Wind is cutting the temperature. Dress warmer than \(Formatters.temperature(current.temperature))."
        }
        return "Comfortable humidity for most people."
    }

    var outdoorAdvice: String {
        if activeStorm { return "Stay indoors until the storm cell moves off." }
        if let uv = today?.uvIndexMax, uv >= 8, current.isDay { return "Great for a walk, but cover up — UV is intense." }
        if WeatherCode.isRain(current.weatherCode) { return "Jacket weather. Pavement will be slick." }
        if WeatherCode.isSnow(current.weatherCode) { return "Bundle up. Watch for packed snow and ice." }
        if current.isDay { return "Solid conditions to get outside." }
        return "Calm evening. A light layer is probably enough."
    }

    var drivingAdvice: String {
        if current.visibility < 1600 { return "Poor visibility. Headlights and extra following distance." }
        if WeatherCode.isSnow(current.weatherCode) || WeatherCode.isRain(current.weatherCode) {
            return "Wet or snowy roads. Leave earlier than usual."
        }
        if current.windGusts >= (units == .metric ? 55 : 35) {
            return "Crosswinds on open roads and bridges."
        }
        return "Roads look straightforward right now."
    }

    func hours(on day: DailyForecast) -> [HourlyForecast] {
        hourly.filter { calendar.isDate($0.date, inSameDayAs: day.date) }
    }

    private static let hourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter
    }()
}

enum Formatters {
    static func temperature(_ value: Double) -> String {
        guard value.isFinite else { return "—" }
        return "\(Int(value.rounded()))°"
    }

    static func compact(_ value: Double, digits: Int = 1) -> String {
        guard value.isFinite else { return "—" }
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = digits
        formatter.minimumFractionDigits = value.rounded() == value ? 0 : min(1, digits)
        return formatter.string(from: NSNumber(value: value)) ?? "—"
    }

    static func compass(_ degrees: Double) -> String {
        guard degrees.isFinite else { return "—" }
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((degrees / 22.5).rounded()) % 16
        return directions[(index + 16) % 16]
    }

    static func visibility(_ meters: Double, units: UnitSystem) -> String {
        guard meters.isFinite else { return "—" }
        if units == .metric {
            let km = meters / 1000
            return km >= 10 ? "\(Int(km.rounded())) km" : "\(compact(km)) km"
        }
        let miles = meters / 1609.34
        return miles >= 10 ? "\(Int(miles.rounded())) mi" : "\(compact(miles)) mi"
    }

    static func pressure(_ hPa: Double, units: UnitSystem) -> String {
        guard hPa.isFinite else { return "—" }
        if units == .metric {
            return "\(Int(hPa.rounded())) hPa"
        }
        return "\(compact(hPa * 0.02953, digits: 2)) inHg"
    }

    static func uv(_ value: Double) -> String {
        guard value.isFinite else { return "—" }
        switch value {
        case ..<3: return "Low"
        case ..<6: return "Moderate"
        case ..<8: return "High"
        case ..<11: return "Very High"
        default: return "Extreme"
        }
    }

    static func duration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    static func snowDepth(_ meters: Double, units: UnitSystem) -> String {
        guard meters.isFinite, meters > 0 else { return "None" }
        if units == .metric {
            let cm = meters * 100
            return cm >= 10 ? "\(Int(cm.rounded())) cm" : "\(compact(cm)) cm"
        }
        let inches = meters * 39.3701
        return "\(compact(inches)) in"
    }

    static func altitude(_ meters: Double, units: UnitSystem) -> String {
        guard meters.isFinite else { return "—" }
        if units == .metric {
            return "\(Int(meters.rounded())) m"
        }
        return "\(Int((meters * 3.28084).rounded())) ft"
    }
}

struct WeatherAlert: Identifiable {
    var id: String
    var title: String
    var detail: String
    var severity: Severity

    enum Severity {
        case warning, watch, advisory

        var label: String {
            switch self {
            case .warning: "WARNING"
            case .watch: "WATCH"
            case .advisory: "ADVISORY"
            }
        }
    }
}

struct MoonPhase {
    var name: String
    var symbol: String
    var illumination: Int

    static func at(_ date: Date) -> MoonPhase {
        let synodic = 29.53058867
        let knownNew = Date(timeIntervalSince1970: 947_182_440)
        let days = date.timeIntervalSince(knownNew) / 86_400
        let cycle = days.truncatingRemainder(dividingBy: synodic)
        let t = (cycle < 0 ? cycle + synodic : cycle) / synodic
        let illumination = Int((1 - cos(2 * .pi * t)) / 2 * 100)
        switch t {
        case 0..<0.04, 0.96...1: return MoonPhase(name: "New moon", symbol: "moon", illumination: illumination)
        case 0.04..<0.21: return MoonPhase(name: "Waxing crescent", symbol: "moon.fill", illumination: illumination)
        case 0.21..<0.29: return MoonPhase(name: "First quarter", symbol: "circle.lefthalf.filled", illumination: illumination)
        case 0.29..<0.46: return MoonPhase(name: "Waxing gibbous", symbol: "moon.fill", illumination: illumination)
        case 0.46..<0.54: return MoonPhase(name: "Full moon", symbol: "moon.stars.fill", illumination: illumination)
        case 0.54..<0.71: return MoonPhase(name: "Waning gibbous", symbol: "moon.fill", illumination: illumination)
        case 0.71..<0.79: return MoonPhase(name: "Last quarter", symbol: "circle.lefthalf.filled", illumination: illumination)
        default: return MoonPhase(name: "Waning crescent", symbol: "moon.fill", illumination: illumination)
        }
    }
}

extension WeatherSnapshot {
    static func map(
        response: ForecastResponse,
        place: Place,
        airQuality: AirQuality?,
        units: UnitSystem
    ) -> WeatherSnapshot {
        let timezone = TimeZone(identifier: response.timezone) ?? .current
        let hourly = response.hourly
        let daily = response.daily
        let current = response.current

        let hourlyItems: [HourlyForecast] = hourly.time.enumerated().compactMap { index, stamp in
            guard hourly.temperature2m.indices.contains(index) else { return nil }
            return HourlyForecast(
                date: Date(timeIntervalSince1970: TimeInterval(stamp)),
                temperature: hourly.temperature2m[safe: index] ?? .nan,
                apparentTemperature: hourly.apparentTemperature[safe: index] ?? .nan,
                humidity: hourly.relativeHumidity2m[safe: index] ?? .nan,
                dewPoint: hourly.dewPoint2m[safe: index] ?? .nan,
                precipProbability: hourly.precipitationProbability[safe: index] ?? 0,
                precipitation: hourly.precipitation[safe: index] ?? 0,
                rain: hourly.rain[safe: index] ?? 0,
                snowfall: hourly.snowfall[safe: index] ?? 0,
                weatherCode: hourly.weatherCode[safe: index] ?? 0,
                pressure: hourly.pressureMsl[safe: index] ?? .nan,
                cloudCover: hourly.cloudCover[safe: index] ?? 0,
                visibility: hourly.visibility[safe: index] ?? .nan,
                windSpeed: hourly.windSpeed10m[safe: index] ?? 0,
                windDirection: hourly.windDirection10m[safe: index] ?? 0,
                windGusts: hourly.windGusts10m[safe: index] ?? 0,
                uvIndex: hourly.uvIndex[safe: index] ?? 0,
                cape: hourly.cape[safe: index] ?? 0,
                isDay: (hourly.isDay[safe: index] ?? 1) == 1
            )
        }

        let dailyItems: [DailyForecast] = daily.time.enumerated().compactMap { index, stamp in
            guard daily.temperature2mMax.indices.contains(index) else { return nil }
            return DailyForecast(
                date: localCalendarDate(unix: stamp, timezone: timezone),
                weatherCode: daily.weatherCode[safe: index] ?? 0,
                high: daily.temperature2mMax[safe: index] ?? .nan,
                low: daily.temperature2mMin[safe: index] ?? .nan,
                apparentHigh: daily.apparentTemperatureMax[safe: index] ?? .nan,
                apparentLow: daily.apparentTemperatureMin[safe: index] ?? .nan,
                sunrise: Date(timeIntervalSince1970: TimeInterval(daily.sunrise[safe: index] ?? stamp)),
                sunset: Date(timeIntervalSince1970: TimeInterval(daily.sunset[safe: index] ?? stamp)),
                daylight: daily.daylightDuration[safe: index] ?? 0,
                sunshine: daily.sunshineDuration[safe: index] ?? 0,
                uvIndexMax: daily.uvIndexMax[safe: index] ?? 0,
                precipitation: daily.precipitationSum[safe: index] ?? 0,
                rain: daily.rainSum[safe: index] ?? 0,
                snowfall: daily.snowfallSum[safe: index] ?? 0,
                precipHours: daily.precipitationHours[safe: index] ?? 0,
                precipProbability: daily.precipitationProbabilityMax[safe: index] ?? 0,
                windMax: daily.windSpeed10mMax[safe: index] ?? 0,
                gustMax: daily.windGusts10mMax[safe: index] ?? 0,
                windDirection: daily.windDirection10mDominant[safe: index] ?? 0
            )
        }

        let minutelyItems: [MinutelyPrecip] = (response.minutely15?.time ?? []).enumerated().map { index, stamp in
            let block = response.minutely15
            return MinutelyPrecip(
                date: Date(timeIntervalSince1970: TimeInterval(stamp)),
                precipitation: block?.precipitation[safe: index] ?? 0,
                rain: block?.rain[safe: index] ?? 0,
                snowfall: block?.snowfall[safe: index] ?? 0,
                weatherCode: block?.weatherCode[safe: index] ?? 0,
                cape: block?.cape[safe: index] ?? 0,
                lightningPotential: block?.lightningPotential[safe: index] ?? 0
            )
        }

        let conditions = CurrentConditions(
            date: Date(timeIntervalSince1970: TimeInterval(current.time)),
            temperature: current.temperature2m,
            apparentTemperature: current.apparentTemperature ?? current.temperature2m,
            humidity: current.relativeHumidity2m ?? 0,
            isDay: current.isDay == 1,
            precipitation: current.precipitation ?? 0,
            rain: current.rain ?? 0,
            snowfall: current.snowfall ?? 0,
            weatherCode: current.weatherCode,
            cloudCover: current.cloudCover ?? 0,
            pressure: current.pressureMsl ?? current.surfacePressure ?? 0,
            windSpeed: current.windSpeed10m ?? 0,
            windDirection: current.windDirection10m ?? 0,
            windGusts: current.windGusts10m ?? 0,
            visibility: current.visibility ?? 0,
            dewPoint: current.dewPoint2m ?? 0,
            cape: current.cape ?? 0,
            snowDepth: current.snowDepth,
            freezingLevel: current.freezingLevelHeight
        )

        return WeatherSnapshot(
            place: place,
            timezone: timezone,
            units: units,
            current: conditions,
            hourly: hourlyItems,
            daily: dailyItems,
            minutely: minutelyItems,
            airQuality: airQuality,
            fetchedAt: Date()
        )
    }
}

private func localCalendarDate(unix: Int, timezone: TimeZone) -> Date {
    var utc = Calendar(identifier: .gregorian)
    utc.timeZone = TimeZone(secondsFromGMT: 0) ?? timezone
    let parts = utc.dateComponents([.year, .month, .day], from: Date(timeIntervalSince1970: TimeInterval(unix)))
    var local = Calendar(identifier: .gregorian)
    local.timeZone = timezone
    return local.date(from: DateComponents(year: parts.year, month: parts.month, day: parts.day))
        ?? Date(timeIntervalSince1970: TimeInterval(unix))
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
