//
//  RadarClient.swift
//  Weather
//

import Foundation

enum RadarClient {
    struct Timeline {
        var host: String
        var frames: [RadarFrame]
    }

    static func loadTimeline() async throws -> Timeline {
        guard let url = URL(string: "https://api.rainviewer.com/public/weather-maps.json") else {
            throw OpenMeteoClient.ClientError.badURL
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(RadarMapsResponse.self, from: data)
        let frames = decoded.radar.past + (decoded.radar.nowcast ?? [])
        return Timeline(host: decoded.host, frames: frames)
    }

    static func tileTemplate(host: String, path: String) -> String {
        "\(host)\(path)/512/{z}/{x}/{y}/2/1_1.png"
    }
}
