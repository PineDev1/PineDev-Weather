//
//  AviationModels.swift
//  Weather
//

import Foundation

enum FlightCategory: String {
    case vfr = "VFR"
    case mvfr = "MVFR"
    case ifr = "IFR"
    case lifr = "LIFR"
    case unknown = "UNK"

    var title: String {
        switch self {
        case .vfr: "Visual Flight Rules"
        case .mvfr: "Marginal Visual Flight Rules"
        case .ifr: "Instrument Flight Rules"
        case .lifr: "Low Instrument Flight Rules"
        case .unknown: "Not reported"
        }
    }

    var shortLabel: String { rawValue }
}

struct MetarCloud: Decodable, Hashable {
    var cover: String?
    var base: Int?
    var type: String?

    var summary: String {
        let name: String
        switch cover?.uppercased() {
        case "FEW": name = "Few"
        case "SCT": name = "Scattered"
        case "BKN": name = "Broken"
        case "OVC": name = "Overcast"
        case "VV": name = "Vertical vis"
        case "CLR", "SKC", "CAVOK": name = "Clear"
        default: name = cover ?? "Clouds"
        }
        if let base {
            return "\(name) \(base.formatted()) ft"
        }
        return name
    }
}

struct MetarJSON: Decodable {
    var icaoId: String?
    var name: String?
    var rawOb: String?
    var fltCat: String?
    var temp: Double?
    var dewp: Double?
    var wdir: JSONScalar?
    var wspd: Double?
    var wgst: Double?
    var visib: JSONScalar?
    var altim: Double?
    var wxString: String?
    var cover: String?
    var clouds: [MetarCloud]?
    var lat: Double?
    var lon: Double?
    var obsTime: Double?
    var elev: Double?
}

struct TafPeriodJSON: Decodable, Identifiable {
    var timeFrom: Double?
    var timeTo: Double?
    var fcstChange: String?
    var probability: Double?
    var wdir: JSONScalar?
    var wspd: Double?
    var wgst: Double?
    var visib: JSONScalar?
    var wxString: String?
    var clouds: [MetarCloud]?

    var id: Double { (timeFrom ?? 0) + (timeTo ?? 0) * 0.001 }

    var changeLabel: String {
        if let probability, probability > 0 {
            return "PROB \(Int(probability))"
        }
        switch fcstChange?.uppercased() {
        case "FM": return "FROM"
        case "BECMG": return "BECOMING"
        case "TEMPO": return "TEMPO"
        default: return "BASE"
        }
    }
}

struct TafJSON: Decodable {
    var icaoId: String?
    var name: String?
    var rawTAF: String?
    var issueTime: String?
    var validTimeFrom: Double?
    var validTimeTo: Double?
    var fcsts: [TafPeriodJSON]?
}

enum JSONScalar: Decodable, Hashable {
    case int(Int)
    case double(Double)
    case string(String)
    case none

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .none
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else {
            self = .none
        }
    }

    var text: String {
        switch self {
        case .int(let value): String(value)
        case .double(let value): value.rounded() == value ? String(Int(value)) : String(value)
        case .string(let value): value
        case .none: "—"
        }
    }

    var double: Double? {
        switch self {
        case .int(let value): Double(value)
        case .double(let value): value
        case .string(let value): Double(value.replacingOccurrences(of: "+", with: ""))
        case .none: nil
        }
    }
}

struct AviationBriefing {
    var icao: String
    var name: String
    var latitude: Double?
    var longitude: Double?
    var observedAt: Date?
    var flightCategory: FlightCategory
    var temperatureC: Double?
    var dewpointC: Double?
    var wind: String
    var visibility: String
    var altimeter: String
    var weather: String
    var clouds: [String]
    var rawMetar: String
    var rawTaf: String?
    var tafPeriods: [TafPeriodJSON]
    var validFrom: Date?
    var validTo: Date?
}
