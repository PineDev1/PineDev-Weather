//
//  LightningClient.swift
//  Weather
//

import Foundation

enum LightningClient {
    struct Overlay {
        var templates: [String]
        var updated: Date?
    }

    /// GOES-East GLM full-disk group density draws strike-like pixels across the
    /// Americas. GOES-West flash-extent density fills in the Pacific CONUS.
    /// West is listed first so the yellow strike layer paints on top.
    private static let products = ["GOESWestGLMFEDRadC", "glmgroupdensity"]

    static func load() async -> Overlay {
        let loaded = await withTaskGroup(of: (String, String?).self) { group in
            for product in products {
                group.addTask {
                    (product, await latestTime(for: product))
                }
            }
            var times: [String: String?] = [:]
            for await (product, time) in group {
                times[product] = time
            }
            return times
        }

        let templates = products.map { product in
            tileTemplate(product: product, time: loaded[product] ?? nil)
        }

        let parsedDates = products.compactMap { product -> Date? in
            guard let time = loaded[product] ?? nil else { return nil }
            return parseProductTime(time)
        }

        return Overlay(templates: templates, updated: parsedDates.max())
    }

    static func tileTemplate(product: String, time: String?) -> String {
        let base = "https://realearth.ssec.wisc.edu/tiles/\(product)/{z}/{x}/{y}.png"
        guard let time else { return base }
        return "\(base)?time=\(time)"
    }

    private static func latestTime(for product: String) async -> String? {
        guard var components = URLComponents(string: "https://realearth.ssec.wisc.edu/api/products") else {
            return nil
        }
        components.queryItems = [URLQueryItem(name: "products", value: product)]
        guard let url = components.url else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode([RealEarthProduct].self, from: data)
            return decoded.first(where: { $0.id == product })?.times?.last
        } catch {
            return nil
        }
    }

    private static func parseProductTime(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd.HHmmss"
        return formatter.date(from: value)
    }
}

private struct RealEarthProduct: Decodable {
    let id: String
    let times: [String]?
}
