//
//  ForecastScreen.swift
//  Weather
//

import SwiftUI

struct ForecastScreen: View {
    @Environment(WeatherStore.self) private var store
    @Environment(\.palette) private var palette
    @State private var selectedDay: DailyForecast?
    @State private var showPlaces = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackdrop(
                    theme: store.theme,
                    weatherCode: store.snapshot?.current.weatherCode ?? 0,
                    isDay: store.snapshot?.current.isDay ?? true
                )
                if let snapshot = store.snapshot {
                    forecastScroll(snapshot)
                } else if store.isLoading {
                    ProgressView()
                        .tint(palette.accent)
                        .scaleEffect(1.2)
                } else {
                    emptyState
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .toolbarColorScheme(store.theme == .light ? .light : .dark, for: .navigationBar)
            .sheet(isPresented: $showPlaces) {
                PlacesSheet()
                    .environment(store)
                    .environment(\.palette, palette)
                    .presentationDetents([.medium, .large])
            }
            .sheet(item: $selectedDay) { day in
                if let snapshot = store.snapshot {
                    DayDetailView(day: day, snapshot: snapshot)
                        .environment(\.palette, palette)
                        .presentationDetents([.medium, .large])
                }
            }
            .task {
                await store.bootstrap()
            }
        }
    }

    private func forecastScroll(_ snapshot: WeatherSnapshot) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                hero(snapshot)
                AlertsCard(alerts: snapshot.alerts)
                if let warning = store.errorMessage {
                    Text(warning)
                        .font(.footnote)
                        .foregroundStyle(palette.gold)
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(palette.cardFillAlt, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                HourlyForecastCard(hours: snapshot.upcomingHourly, timezone: snapshot.timezone)
                TenDayCard(days: snapshot.daily, timezone: snapshot.timezone) { day in
                    selectedDay = day
                }
                PrecipitationCard(snapshot: snapshot)
                StormCard(snapshot: snapshot)
                ConditionsInsightCard(snapshot: snapshot)
                MoonPollenRow(snapshot: snapshot)
                TemperatureChartCard(hours: snapshot.next24Hours)
                ConditionGrid(snapshot: snapshot)
                Text("Updated \(snapshot.fetchedAt.formatted(date: .omitted, time: .shortened)) · Open-Meteo")
                    .font(.caption)
                    .foregroundStyle(palette.muted)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .refreshable {
            await store.refreshSelected()
        }
    }

    private func hero(_ snapshot: WeatherSnapshot) -> some View {
        GroveCard {
            VStack(alignment: .leading, spacing: 14) {
                Text(palette.heroEyebrow)
                    .font(palette.captionFont())
                    .tracking(2.8)
                    .foregroundStyle(palette.accentSoft)
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(snapshot.place.name)
                            .font(palette.display(34, weight: .regular))
                            .foregroundStyle(palette.text)
                            .fixedSize(horizontal: false, vertical: true)
                        if !snapshot.place.detail.isEmpty {
                            Text(snapshot.place.detail)
                                .font(.subheadline)
                                .foregroundStyle(palette.muted)
                        }
                        HStack(spacing: 8) {
                            Image(systemName: snapshot.current.symbolName)
                            Text(snapshot.current.summary)
                        }
                        .font(.callout.weight(.medium))
                        .foregroundStyle(palette.text)
                        .padding(.top, 8)
                    }
                    Spacer(minLength: 12)
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(Formatters.temperature(snapshot.current.temperature))
                            .font(palette.display(56, weight: .light))
                            .foregroundStyle(palette.text)
                        if let today = snapshot.today {
                            Text("High \(Formatters.temperature(today.high))")
                            Text("Low \(Formatters.temperature(today.low))")
                        }
                    }
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(palette.muted)
                }
            }
        }
        .padding(.top, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: store.theme == .classic ? "tree.fill" : "location.viewfinder")
                .font(.system(size: 42))
                .foregroundStyle(palette.accent)
            Text(store.theme == .classic ? "Enter the woods" : "Find your forecast")
                .font(palette.display(28))
            Text("Allow location or search for a city to load PineDev Weather.")
                .multilineTextAlignment(.center)
                .foregroundStyle(palette.muted)
            Button("Choose a place") { showPlaces = true }
                .buttonStyle(.borderedProminent)
                .tint(palette.accent)
            if let message = store.errorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(palette.gold)
            }
        }
        .foregroundStyle(palette.text)
        .padding(28)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                showPlaces = true
            } label: {
                Image(systemName: "list.bullet")
                    .foregroundStyle(palette.text)
            }
        }
        ToolbarItem(placement: .principal) {
            Text("PineDev Weather")
                .font(palette.display(15, weight: .semibold))
                .foregroundStyle(palette.text)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                Task { await store.toggleUnits() }
            } label: {
                Text("°\(store.units.temperatureSymbol)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.text)
            }
        }
    }
}
