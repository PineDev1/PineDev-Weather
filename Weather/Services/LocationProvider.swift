//
//  LocationProvider.swift
//  Weather
//

import CoreLocation
import Foundation
import MapKit

@Observable
final class LocationProvider: NSObject, CLLocationManagerDelegate {
    var authorization: CLAuthorizationStatus
    var coordinate: CLLocationCoordinate2D?
    var locationError: String?
    var onUpdate: (() -> Void)?

    private let manager = CLLocationManager()

    override init() {
        authorization = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var isAuthorized: Bool {
        authorization == .authorizedWhenInUse || authorization == .authorizedAlways
    }

    var needsRequest: Bool {
        authorization == .notDetermined
    }

    func request() {
        locationError = nil
        manager.requestWhenInUseAuthorization()
        if isAuthorized {
            manager.requestLocation()
        }
    }

    func refresh() {
        guard isAuthorized else { return }
        manager.requestLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorization = manager.authorizationStatus
        if isAuthorized {
            manager.requestLocation()
        }
    }

    func reverseName(for coordinate: CLLocationCoordinate2D) async -> (name: String, detail: String) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let request = MKReverseGeocodingRequest(location: location) else {
            return ("Current Location", "My location")
        }
        do {
            let item = try await request.mapItems.first
            let representations = item?.addressRepresentations
            let name = representations?.cityName ?? item?.name ?? "Current Location"
            let detail = representations?.regionName ?? item?.address?.shortAddress ?? "My location"
            return (name, detail)
        } catch {
            return ("Current Location", "My location")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        coordinate = locations.last?.coordinate
        locationError = nil
        onUpdate?()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error.localizedDescription
    }
}
