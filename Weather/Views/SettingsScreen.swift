//
//  SettingsScreen.swift
//  Weather
//

import SwiftUI

struct SettingsScreen: View {
    @Environment(WeatherStore.self) private var store
    @Environment(\.palette) private var palette

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackdrop(
                    theme: store.theme,
                    weatherCode: store.snapshot?.current.weatherCode ?? 0,
                    isDay: store.snapshot?.current.isDay ?? true
                )
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How PineDev looks and measures the sky.")
                            .font(.subheadline)
                            .foregroundStyle(palette.muted)

                        GroveCard(title: "Theme", systemImage: "paintpalette") {
                            VStack(spacing: 10) {
                                ForEach(AppTheme.allCases) { theme in
                                    themeRow(theme)
                                }
                            }
                        }

                        GroveCard(title: "Units", systemImage: "ruler") {
                            Picker("Units", selection: Binding(
                                get: { store.units },
                                set: { newValue in
                                    Task { await store.setUnits(newValue) }
                                }
                            )) {
                                Text("Fahrenheit · mph").tag(UnitSystem.imperial)
                                Text("Celsius · km/h").tag(UnitSystem.metric)
                            }
                            .pickerStyle(.segmented)
                        }

                        GroveCard(title: "Location", systemImage: "location") {
                            Button {
                                store.location.request()
                            } label: {
                                Label(
                                    store.location.isAuthorized ? "Location is on" : "Enable location",
                                    systemImage: store.location.isAuthorized ? "checkmark.circle.fill" : "location.slash"
                                )
                                .foregroundStyle(palette.text)
                            }
                            .buttonStyle(.plain)
                            Text("Used for forecasts, radar, and the nearest METAR station.")
                                .font(.footnote)
                                .foregroundStyle(palette.muted)
                        }

                        GroveCard(title: "About", systemImage: "info.circle") {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("PineDev Weather")
                                    .font(palette.display(22, weight: .semibold))
                                    .foregroundStyle(palette.text)
                                Text("Forecasts by Open-Meteo. Radar tiles by RainViewer. Lightning from NOAA GOES GLM via SSEC RealEarth. Aviation METARs and TAFs from the NOAA Aviation Weather Center.")
                                    .font(.footnote)
                                    .foregroundStyle(palette.muted)
                            }
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(store.theme == .light ? .light : .dark, for: .navigationBar)
        }
    }

    private func themeRow(_ theme: AppTheme) -> some View {
        Button {
            store.setTheme(theme)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: theme.icon)
                    .font(.title3)
                    .foregroundStyle(palette.accent)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(theme.title)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(palette.text)
                        if let joke = theme.joke {
                            Text(joke)
                                .font(.caption.italic())
                                .foregroundStyle(palette.gold)
                        }
                    }
                    Text(theme.subtitle)
                        .font(.caption)
                        .foregroundStyle(palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                if store.theme == theme {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(palette.accent)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(store.theme == theme ? palette.accent.opacity(0.12) : .clear)
            )
        }
        .buttonStyle(.plain)
    }
}
