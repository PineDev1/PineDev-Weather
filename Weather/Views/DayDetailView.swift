//
//  DayDetailView.swift
//  Weather
//

import SwiftUI

struct DayDetailView: View {
    let day: DailyForecast
    let snapshot: WeatherSnapshot
    @Environment(WeatherStore.self) private var store
    @Environment(\.palette) private var palette

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    HourlyForecastCard(hours: snapshot.hours(on: day), timezone: snapshot.timezone)
                    stats
                }
                .padding(16)
            }
            .background(AppBackdrop(theme: store.theme, weatherCode: day.weatherCode, isDay: true))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var title: String {
        let formatter = DateFormatter()
        formatter.timeZone = snapshot.timezone
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: day.date)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: day.symbolName)
                .font(.system(size: 44))
                .symbolRenderingMode(.multicolor)
            Text(WeatherCode.summary(day.weatherCode))
                .font(palette.display(26))
                .foregroundStyle(palette.text)
            Text("High \(Formatters.temperature(day.high))   Low \(Formatters.temperature(day.low))")
                .foregroundStyle(palette.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var stats: some View {
        let formatter = DateFormatter()
        formatter.timeZone = snapshot.timezone
        formatter.dateFormat = "h:mm a"

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricTile(title: "Rain", systemImage: "cloud.rain.fill", value: "\(Formatters.compact(day.rain)) \(snapshot.units.precipSymbol)", detail: "\(Int(day.precipProbability.rounded()))% chance")
            MetricTile(title: "Snow", systemImage: "snowflake", value: "\(Formatters.compact(day.snowfall)) \(snapshot.units.precipSymbol)", detail: "\(Int(day.precipHours.rounded()))h of precip")
            MetricTile(title: "Wind", systemImage: "wind", value: "\(Int(day.windMax.rounded())) \(snapshot.units.speedSymbol)", detail: "Gusts \(Int(day.gustMax.rounded())) · \(Formatters.compass(day.windDirection))")
            MetricTile(title: "UV", systemImage: "sun.max.fill", value: "\(Int(day.uvIndexMax.rounded()))", detail: Formatters.uv(day.uvIndexMax))
            MetricTile(title: "Sunrise", systemImage: "sunrise.fill", value: formatter.string(from: day.sunrise), detail: "Daylight \(Formatters.duration(day.daylight))")
            MetricTile(title: "Sunset", systemImage: "sunset.fill", value: formatter.string(from: day.sunset), detail: "Sunshine \(Formatters.duration(day.sunshine))")
        }
    }
}
