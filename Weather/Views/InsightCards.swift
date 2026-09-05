//
//  InsightCards.swift
//  Weather
//

import SwiftUI

struct AlertsCard: View {
    let alerts: [WeatherAlert]
    @Environment(\.palette) private var palette

    var body: some View {
        if !alerts.isEmpty {
            GroveCard(title: "Alerts", systemImage: "exclamationmark.triangle.fill") {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(alerts) { alert in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(alert.severity.label)
                                    .font(.caption2.weight(.heavy))
                                    .tracking(0.8)
                                    .foregroundStyle(alert.severity == .warning ? Color.red : palette.gold)
                                Text(alert.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(palette.text)
                            }
                            Text(alert.detail)
                                .font(.footnote)
                                .foregroundStyle(palette.muted)
                        }
                    }
                }
            }
        }
    }
}

struct ConditionsInsightCard: View {
    let snapshot: WeatherSnapshot
    @Environment(\.palette) private var palette

    var body: some View {
        GroveCard(title: "Going out", systemImage: "figure.walk") {
            VStack(alignment: .leading, spacing: 10) {
                insight("Outside", snapshot.outdoorAdvice)
                insight("Driving", snapshot.drivingAdvice)
                insight("Comfort", snapshot.comfort)
            }
        }
    }

    private func insight(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(palette.accentSoft)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(palette.text)
        }
    }
}

struct MoonPollenRow: View {
    let snapshot: WeatherSnapshot
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            GroveCard(title: "Moon", systemImage: "moon.stars") {
                HStack(spacing: 10) {
                    Image(systemName: snapshot.moon.symbol)
                        .font(.title)
                        .foregroundStyle(palette.accentSoft)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(snapshot.moon.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(palette.text)
                        Text("\(snapshot.moon.illumination)% lit")
                            .font(.caption)
                            .foregroundStyle(palette.muted)
                    }
                }
            }
            GroveCard(title: "Pollen", systemImage: "allergens") {
                if let pollen = snapshot.airQuality?.pollenLevel {
                    Text(snapshot.airQuality?.pollenCategory ?? "—")
                        .font(palette.display(22, weight: .semibold))
                        .foregroundStyle(palette.text)
                    Text("\(pollen.name) \(Int(pollen.value.rounded()))")
                        .font(.caption)
                        .foregroundStyle(palette.muted)
                } else {
                    Text("Quiet")
                        .font(palette.display(22, weight: .semibold))
                        .foregroundStyle(palette.text)
                    Text("No pollen reported here")
                        .font(.caption)
                        .foregroundStyle(palette.muted)
                }
            }
        }
    }
}
