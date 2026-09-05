//
//  WeatherCode.swift
//  Weather
//

import SwiftUI

enum WeatherCode {
    static func isThunderstorm(_ code: Int) -> Bool {
        code == 95 || code == 96 || code == 99
    }

    static func isPrecipitation(_ code: Int) -> Bool {
        (51...67).contains(code) || (71...86).contains(code) || isThunderstorm(code)
    }

    static func isSnow(_ code: Int) -> Bool {
        (71...77).contains(code) || (85...86).contains(code)
    }

    static func isRain(_ code: Int) -> Bool {
        (51...67).contains(code) || (80...82).contains(code) || isThunderstorm(code)
    }

    static func summary(_ code: Int) -> String {
        switch code {
        case 0: "Clear sky"
        case 1: "Mainly clear"
        case 2: "Partly cloudy"
        case 3: "Overcast"
        case 45: "Fog"
        case 48: "Icy fog"
        case 51: "Light drizzle"
        case 53: "Drizzle"
        case 55: "Heavy drizzle"
        case 56: "Light freezing drizzle"
        case 57: "Freezing drizzle"
        case 61: "Light rain"
        case 63: "Rain"
        case 65: "Heavy rain"
        case 66: "Light freezing rain"
        case 67: "Freezing rain"
        case 71: "Light snow"
        case 73: "Snow"
        case 75: "Heavy snow"
        case 77: "Snow grains"
        case 80: "Light showers"
        case 81: "Showers"
        case 82: "Heavy showers"
        case 85: "Light snow showers"
        case 86: "Snow showers"
        case 95: "Thunderstorm"
        case 96: "Thunderstorm with hail"
        case 99: "Severe thunderstorm"
        default: "Weather"
        }
    }

    static func symbol(_ code: Int, isDay: Bool) -> String {
        switch code {
        case 0: isDay ? "sun.max.fill" : "moon.stars.fill"
        case 1: isDay ? "sun.min.fill" : "moon.fill"
        case 2: isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        case 3: "cloud.fill"
        case 45, 48: "cloud.fog.fill"
        case 51, 53, 55, 56, 57: "cloud.drizzle.fill"
        case 61, 63, 66, 67: "cloud.rain.fill"
        case 65: "cloud.heavyrain.fill"
        case 71, 73, 75, 77, 85, 86: "cloud.snow.fill"
        case 80, 81: isDay ? "cloud.sun.rain.fill" : "cloud.moon.rain.fill"
        case 82: "cloud.heavyrain.fill"
        case 95: "cloud.bolt.rain.fill"
        case 96, 99: "cloud.bolt.fill"
        default: isDay ? "sun.max.fill" : "moon.fill"
        }
    }
}
