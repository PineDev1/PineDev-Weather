//
//  WeatherStore.swift
//  Weather
//

import CoreLocation
import Foundation

@Observable
final class WeatherStore {
    var snapshot: WeatherSnapshot?
    var savedPlaces: [Place] = []
    var selectedPlaceID: String = Place.currentID
    var units: UnitSystem
    var theme: AppTheme
    var isLoading = false
    var errorMessage: String?
    var searchQuery = ""
    var searchResults: [GeocodingResult] = []
    var isSearching = false

    let location = LocationProvider()

    private var searchTask: Task<Void, Never>?
    private let defaults = UserDefaults.standard

    init() {
        if let raw = defaults.string(forKey: Keys.units), let parsed = UnitSystem(rawValue: raw) {
            units = parsed
        } else {
            units = .fromLocale
        }
        if let rawTheme = defaults.string(forKey: Keys.theme), let parsed = AppTheme(rawValue: rawTheme) {
            theme = parsed
        } else {
            theme = .dark
        }
        selectedPlaceID = defaults.string(forKey: Keys.selected) ?? Place.currentID
        savedPlaces = Self.loadPlaces()
        location.onUpdate = { [weak self] in
            Task { await self?.handleLocationUpdate() }
        }
    }

    var selectedPlace: Place? {
        if selectedPlaceID == Place.currentID {
            return savedPlaces.first(where: { $0.isCurrentLocation }) ?? snapshot?.place
        }
        return savedPlaces.first(where: { $0.id == selectedPlaceID }) ?? snapshot?.place
    }

    func bootstrap() async {
        location.request()
        if let existing = selectedPlace, !existing.isCurrentLocation {
            await refresh(for: existing)
        } else if let coordinate = location.coordinate {
            await useCurrentLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        } else if let last = savedPlaces.first(where: { !$0.isCurrentLocation }) {
            selectedPlaceID = last.id
            await refresh(for: last)
        }
    }

    func handleLocationUpdate() async {
        guard selectedPlaceID == Place.currentID, let coordinate = location.coordinate else { return }
        await useCurrentLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    func select(_ place: Place) async {
        selectedPlaceID = place.id
        persist()
        await refresh(for: place)
    }

    func selectCurrentLocation() async {
        selectedPlaceID = Place.currentID
        persist()
        location.request()
        if let coordinate = location.coordinate {
            await useCurrentLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }
    }

    func save(_ place: Place) {
        guard !place.isCurrentLocation else { return }
        if !savedPlaces.contains(where: { $0.id == place.id }) {
            savedPlaces.append(place)
            persist()
        }
    }

    func remove(_ place: Place) {
        savedPlaces.removeAll { $0.id == place.id }
        if selectedPlaceID == place.id {
            selectedPlaceID = Place.currentID
        }
        persist()
    }

    var palette: ThemePalette {
        ThemePalette.make(
            theme: theme,
            code: snapshot?.current.weatherCode ?? 0,
            isDay: snapshot?.current.isDay ?? true
        )
    }

    func setTheme(_ theme: AppTheme) {
        self.theme = theme
        persist()
    }

    func toggleUnits() async {
        await setUnits(units == .imperial ? .metric : .imperial)
    }

    func setUnits(_ units: UnitSystem) async {
        self.units = units
        persist()
        if let place = selectedPlace {
            await refresh(for: place)
        }
    }

    func refreshSelected() async {
        if selectedPlaceID == Place.currentID {
            location.refresh()
            if let coordinate = location.coordinate {
                await useCurrentLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                return
            }
        }
        if let place = selectedPlace {
            await refresh(for: place)
        }
    }

    func updateSearch(_ query: String) {
        searchQuery = query
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            searchResults = []
            isSearching = false
            return
        }
        isSearching = true
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(280))
            guard !Task.isCancelled else { return }
            do {
                let results = try await OpenMeteoClient.searchPlaces(trimmed)
                searchResults = results
            } catch {
                searchResults = []
            }
            isSearching = false
        }
    }

    private func useCurrentLocation(latitude: Double, longitude: Double) async {
        let resolved = await location.reverseName(
            for: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        )
        let place = Place.current(
            name: resolved.name,
            detail: resolved.detail,
            latitude: latitude,
            longitude: longitude
        )
        savedPlaces.removeAll { $0.isCurrentLocation }
        savedPlaces.insert(place, at: 0)
        persist()
        await refresh(for: place)
    }

    private func refresh(for place: Place) async {
        isLoading = snapshot == nil
        errorMessage = nil
        do {
            async let forecastTask = OpenMeteoClient.forecast(
                latitude: place.latitude,
                longitude: place.longitude,
                units: units
            )
            async let airTask = OpenMeteoClient.airQuality(latitude: place.latitude, longitude: place.longitude)
            let forecast = try await forecastTask
            let air = try? await airTask
            snapshot = WeatherSnapshot.map(response: forecast, place: place, airQuality: air, units: units)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func persist() {
        defaults.set(units.rawValue, forKey: Keys.units)
        defaults.set(theme.rawValue, forKey: Keys.theme)
        defaults.set(selectedPlaceID, forKey: Keys.selected)
        if let data = try? JSONEncoder().encode(savedPlaces.filter { !$0.isCurrentLocation }) {
            defaults.set(data, forKey: Keys.places)
        }
    }

    private static func loadPlaces() -> [Place] {
        guard let data = UserDefaults.standard.data(forKey: Keys.places) else { return [] }
        return (try? JSONDecoder().decode([Place].self, from: data)) ?? []
    }

    private enum Keys {
        static let units = "pinedev.weather.units"
        static let theme = "pinedev.weather.theme"
        static let selected = "pinedev.weather.selected"
        static let places = "pinedev.weather.places"
    }
}
