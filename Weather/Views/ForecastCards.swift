//
//  ForecastCards.swift
//  Weather
//

import Charts
import SwiftUI

struct HourlyForecastCard: View {
    let hours: [HourlyForecast]
    let timezone: TimeZone
    @Environment(\.palette) private var palette

    var body: some View {
        GlassCard(title: "Next hours", systemImage: "clock") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(hours.prefix(18).enumerated()), id: \.element.id) { index, hour in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(index == 0 ? "Now" : Self.timeString(hour.date, timezone: timezone))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(palette.accentSoft)
                            Image(systemName: hour.symbolName)
                                .font(.title3)
                                .foregroundStyle(palette.text)
                            Text(Formatters.temperature(hour.temperature))
                                .font(palette.display(22, weight: .semibold))
                                .foregroundStyle(palette.text)
                            Text("\(Int(hour.precipProbability.rounded()))% rain")
                                .font(.caption2)
                                .foregroundStyle(hour.precipProbability >= 30 ? palette.accent : palette.muted)
                        }
                        .padding(12)
                        .frame(width: 88, alignment: .leading)
                        .background(palette.chipFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(palette.border, lineWidth: 1)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private static func timeString(_ date: Date, timezone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timezone
        formatter.dateFormat = "ha"
        return formatter.string(from: date).lowercased()
    }
}

struct TenDayCard: View {
    let days: [DailyForecast]
    let timezone: TimeZone
    var onSelect: (DailyForecast) -> Void
    @Environment(\.palette) private var palette

    var body: some View {
        GlassCard(title: "Ten-day almanac", systemImage: "calendar") {
            let range = temperatureRange
            VStack(spacing: 0) {
                ForEach(Array(days.prefix(10).enumerated()), id: \.element.id) { index, day in
                    Button {
                        onSelect(day)
                    } label: {
                        HStack(spacing: 12) {
                            Text(dayLabel(day, index: index))
                                .font(.system(.body, design: palette.usesSerif ? .serif : .default).weight(.semibold))
                                .foregroundStyle(palette.text)
                                .frame(width: 92, alignment: .leading)
                            Image(systemName: day.symbolName)
                                .foregroundStyle(palette.accentSoft)
                                .frame(width: 28)
                            if day.precipProbability >= 20 {
                                Text("\(Int(day.precipProbability.rounded()))%")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(palette.accent)
                                    .frame(width: 36, alignment: .leading)
                            } else {
                                Color.clear.frame(width: 36)
                            }
                            Text(Formatters.temperature(day.low))
                                .font(.callout.weight(.medium))
                                .foregroundStyle(palette.muted)
                                .frame(width: 36, alignment: .trailing)
                            TemperatureBar(low: day.low, high: day.high, range: range)
                            Text(Formatters.temperature(day.high))
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(palette.text)
                                .frame(width: 36, alignment: .trailing)
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    if index < min(days.count, 10) - 1 {
                        Divider().overlay(palette.border)
                    }
                }
            }
        }
    }

    private var temperatureRange: ClosedRange<Double> {
        let lows = days.prefix(10).map(\.low)
        let highs = days.prefix(10).map(\.high)
        let minValue = (lows.min() ?? 0) - 1
        let maxValue = (highs.max() ?? 1) + 1
        return minValue...max(maxValue, minValue + 1)
    }

    private func dayLabel(_ day: DailyForecast, index: Int) -> String {
        if index == 0 { return "Today" }
        let formatter = DateFormatter()
        formatter.timeZone = timezone
        formatter.dateFormat = "EEEE"
        return formatter.string(from: day.date)
    }
}

struct TemperatureBar: View {
    let low: Double
    let high: Double
    let range: ClosedRange<Double>
    @Environment(\.palette) private var palette

    var body: some View {
        GeometryReader { geo in
            let span = range.upperBound - range.lowerBound
            let start = CGFloat((low - range.lowerBound) / span) * geo.size.width
            let end = CGFloat((high - range.lowerBound) / span) * geo.size.width
            Capsule()
                .fill(palette.barTrack)
            Capsule()
                .fill(
                    LinearGradient(
                        colors: palette.barColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: max(8, end - start))
                .offset(x: start)
        }
        .frame(height: 6)
    }
}

struct PrecipitationCard: View {
    let snapshot: WeatherSnapshot
    @Environment(\.palette) private var palette

    var body: some View {
        GlassCard(title: "Precipitation", systemImage: "drop.fill") {
            Text(snapshot.rainStory)
                .font(palette.display(22, weight: .semibold))
                .foregroundStyle(palette.text)
                .fixedSize(horizontal: false, vertical: true)

            if !snapshot.minutely.isEmpty {
                Chart(snapshot.minutely.filter { $0.precipitation.isFinite }) { item in
                    AreaMark(
                        x: .value("Time", item.date),
                        y: .value("Precip", max(item.precipitation, 0))
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [palette.chartFill, palette.accent.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    LineMark(
                        x: .value("Time", item.date),
                        y: .value("Precip", max(item.precipitation, 0))
                    )
                    .foregroundStyle(palette.accent)
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 84)
            }

            HStack {
                precipStat(title: "Today rain", value: rainToday)
                Spacer()
                precipStat(title: "Snow", value: snowToday)
                Spacer()
                precipStat(title: "Next hour", value: nextHour)
            }
        }
    }

    private var rainToday: String {
        guard let today = snapshot.today else { return "—" }
        return "\(Formatters.compact(today.rain)) \(snapshot.units.precipSymbol)"
    }

    private var snowToday: String {
        guard let today = snapshot.today else { return "—" }
        return "\(Formatters.compact(today.snowfall)) \(snapshot.units.precipSymbol)"
    }

    private var nextHour: String {
        let total = snapshot.minutely.prefix(4).reduce(0) { $0 + $1.precipitation }
        return "\(Formatters.compact(total)) \(snapshot.units.precipSymbol)"
    }

    private func precipStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(palette.muted)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.text)
        }
    }
}

struct StormCard: View {
    let snapshot: WeatherSnapshot
    @Environment(\.palette) private var palette

    var body: some View {
        let risk = snapshot.stormRisk
        let maxCape = snapshot.upcomingHourly.prefix(12).map(\.cape).max() ?? snapshot.current.cape
        let lightning = snapshot.minutely.map(\.lightningPotential).max() ?? 0

        GlassCard(title: "Thunderstorms", systemImage: "cloud.bolt.fill") {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: snapshot.activeStorm ? "cloud.bolt.rain.fill" : "bolt.fill")
                    .font(.system(size: 34))
                    .symbolRenderingMode(.multicolor)
                VStack(alignment: .leading, spacing: 6) {
                    Text(risk ?? "No thunderstorms expected")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(palette.text)
                    Text(snapshot.activeStorm
                         ? "Stay indoors and avoid open areas until the storm passes."
                         : "CAPE and lightning potential are used to flag storm risk.")
                        .font(.footnote)
                        .foregroundStyle(palette.muted)
                }
            }

            HStack(spacing: 12) {
                stormMetric("CAPE", Formatters.compact(maxCape, digits: 0), "J/kg")
                stormMetric("Lightning", Formatters.compact(lightning, digits: 0), "LPI")
                stormMetric("Gusts", Formatters.compact(snapshot.current.windGusts, digits: 0), snapshot.units.speedSymbol)
            }
        }
        .overlay(alignment: .topTrailing) {
            if snapshot.activeStorm || snapshot.upcomingStorm != nil {
                Text(snapshot.activeStorm ? "LIVE" : "WATCH")
                    .font(.caption2.weight(.heavy))
                    .tracking(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(snapshot.activeStorm ? Color.red.opacity(0.85) : palette.gold.opacity(0.85), in: Capsule())
                    .foregroundStyle(.white)
                    .padding(16)
            }
        }
    }

    private func stormMetric(_ title: String, _ value: String, _ unit: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(palette.muted)
            Text("\(value) \(unit)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(palette.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TemperatureChartCard: View {
    let hours: [HourlyForecast]
    @Environment(\.palette) private var palette

    var body: some View {
        GlassCard(title: "Next 24 hours", systemImage: "chart.xyaxis.line") {
            Chart(hours.filter { $0.temperature.isFinite }) { hour in
                AreaMark(
                    x: .value("Time", hour.date),
                    y: .value("Temp", hour.temperature)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [palette.chartFill, Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                LineMark(
                    x: .value("Time", hour.date),
                    y: .value("Temp", hour.temperature)
                )
                .foregroundStyle(palette.accentSoft)
                .interpolationMethod(.catmullRom)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(palette.border)
                    AxisValueLabel().foregroundStyle(palette.muted)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisValueLabel().foregroundStyle(palette.muted)
                }
            }
            .frame(height: 160)
        }
    }
}

struct ConditionGrid: View {
    let snapshot: WeatherSnapshot
    @Environment(\.palette) private var palette

    var body: some View {
        let current = snapshot.current
        let today = snapshot.today
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            MetricTile(
                title: "Feels like",
                systemImage: "thermometer.medium",
                value: Formatters.temperature(current.apparentTemperature),
                detail: feelsLikeDetail
            )
            MetricTile(
                title: "Wind",
                systemImage: "wind",
                value: "\(Int(current.windSpeed.rounded()))",
                detail: "\(Formatters.compass(current.windDirection)) · Gusts \(Int(current.windGusts.rounded())) \(snapshot.units.speedSymbol)"
            )
            MetricTile(
                title: "Humidity",
                systemImage: "humidity.fill",
                value: "\(Int(current.humidity.rounded()))%",
                detail: "Dew point \(Formatters.temperature(current.dewPoint))"
            )
            MetricTile(
                title: "UV index",
                systemImage: "sun.max.fill",
                value: today.map { "\(Int($0.uvIndexMax.rounded()))" } ?? "—",
                detail: today.map { Formatters.uv($0.uvIndexMax) } ?? "—"
            )
            MetricTile(
                title: "Visibility",
                systemImage: "eye.fill",
                value: Formatters.visibility(current.visibility, units: snapshot.units),
                detail: current.cloudCover.isFinite ? "Clouds \(Int(current.cloudCover.rounded()))%" : "—"
            )
            MetricTile(
                title: "Pressure",
                systemImage: "gauge.with.dots.needle.33percent",
                value: Formatters.pressure(current.pressure, units: snapshot.units),
                detail: "Sea level"
            )
            MetricTile(
                title: "Sunrise",
                systemImage: "sunrise.fill",
                value: today.map { time($0.sunrise) } ?? "—",
                detail: today.map { "Sunset \(time($0.sunset))" } ?? "—"
            )
            MetricTile(
                title: "Air quality",
                systemImage: "aqi.medium",
                value: snapshot.airQuality?.displayIndex.map { "\(Int($0.rounded()))" } ?? "—",
                detail: snapshot.airQuality?.category ?? "Unavailable"
            )
            MetricTile(
                title: "Snow depth",
                systemImage: "snowflake",
                value: Formatters.snowDepth(current.snowDepth ?? 0, units: snapshot.units),
                detail: "On the ground"
            )
            MetricTile(
                title: "Freezing level",
                systemImage: "thermometer",
                value: current.freezingLevel.map { Formatters.altitude($0, units: snapshot.units) } ?? "—",
                detail: "Height of the 0°C layer"
            )
        }
    }

    private var feelsLikeDetail: String {
        let delta = snapshot.current.apparentTemperature - snapshot.current.temperature
        if delta >= 2 { return "Warmer than the actual temperature" }
        if delta <= -2 { return "Cooler than the actual temperature" }
        return "Similar to the actual temperature"
    }

    private func time(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = snapshot.timezone
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
