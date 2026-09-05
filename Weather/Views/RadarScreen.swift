//
//  RadarScreen.swift
//  Weather
//

import Combine
import CoreLocation
import MapKit
import SwiftUI

struct RadarScreen: View {
    @Environment(WeatherStore.self) private var store
    @Environment(\.palette) private var palette
    @State private var timeline: RadarClient.Timeline?
    @State private var frameIndex = 0
    @State private var isPlaying = true
    @State private var loadError: String?
    @State private var lightningOn = true
    @State private var lightning: LightningClient.Overlay?

    private let timer = Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .bottom) {
            RadarMapView(
                coordinate: coordinate,
                placeName: store.snapshot?.place.name ?? "Location",
                template: currentTemplate,
                lightningEnabled: lightningOn,
                lightningTemplates: lightning?.templates ?? []
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                if let loadError {
                    Text(loadError)
                        .font(.footnote)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                controls
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(Color.black)
        .task {
            await load()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(90))
                guard !Task.isCancelled else { return }
                await loadLightning()
            }
        }
        .onReceive(timer) { _ in
            guard isPlaying, let frames = timeline?.frames, frames.count > 1 else { return }
            frameIndex = (frameIndex + 1) % frames.count
        }
    }

    private var coordinate: CLLocationCoordinate2D {
        if let place = store.snapshot?.place {
            return CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
        }
        if let coordinate = store.location.coordinate {
            return coordinate
        }
        return CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    }

    private var currentTemplate: String? {
        guard let timeline, timeline.frames.indices.contains(frameIndex) else { return nil }
        return RadarClient.tileTemplate(host: timeline.host, path: timeline.frames[frameIndex].path)
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Radar")
                    .font(palette.display(20, weight: .semibold))
                Spacer()
                Text(frameLabel)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.8))
            }
            .foregroundStyle(.white)

            if lightningOn {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(palette.gold)
                    Text(lightningStatus)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .font(.caption.weight(.semibold))
            }

            if let frames = timeline?.frames, frames.count > 1 {
                Slider(
                    value: Binding(
                        get: { Double(frameIndex) },
                        set: { frameIndex = Int($0.rounded()); isPlaying = false }
                    ),
                    in: 0...Double(frames.count - 1),
                    step: 1
                )
                .tint(palette.accent)
            }

            HStack {
                Button {
                    isPlaying.toggle()
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)

                legend
                Spacer()
                Button {
                    lightningOn.toggle()
                } label: {
                    Image(systemName: lightningOn ? "bolt.fill" : "bolt.slash")
                        .foregroundStyle(lightningOn ? palette.gold : .white)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(lightningOn ? "Hide lightning strikes" : "Show lightning strikes")

                Button {
                    Task { await load() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(.white)

            Text("Radar © RainViewer  ·  Lightning © NOAA GOES GLM")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.55))
        }
        .padding(16)
            .background(Color.black.opacity(0.48), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(palette.border, lineWidth: 1)
        }
    }

    private var frameLabel: String {
        guard let timeline, timeline.frames.indices.contains(frameIndex) else { return "Loading" }
        return Self.timeString(timeline.frames[frameIndex].date, timezone: store.snapshot?.timezone)
    }

    private var lightningStatus: String {
        guard let updated = lightning?.updated else { return "Live satellite strikes" }
        return "Live satellite strikes · \(Self.timeString(updated, timezone: store.snapshot?.timezone))"
    }

    private static func timeString(_ date: Date, timezone: TimeZone?) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timezone ?? .current
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private var legend: some View {
        HStack(spacing: 0) {
            ForEach(0..<6, id: \.self) { index in
                Rectangle().fill(legendColor(index))
            }
        }
        .frame(width: 120, height: 8)
        .clipShape(Capsule())
        .overlay(alignment: .leading) {
            Text("Light")
                .font(.system(size: 8).weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))
                .offset(y: 12)
        }
        .overlay(alignment: .trailing) {
            Text("Heavy")
                .font(.system(size: 8).weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))
                .offset(y: 12)
        }
        .padding(.bottom, 8)
    }

    private func legendColor(_ index: Int) -> Color {
        switch index {
        case 0: Color(red: 0.45, green: 0.95, blue: 0.55)
        case 1: Color(red: 0.15, green: 0.75, blue: 0.35)
        case 2: Color.yellow
        case 3: Color.orange
        case 4: Color.red
        default: Color.purple
        }
    }

    private func load() async {
        async let radar = RadarClient.loadTimeline()
        async let lightningOverlay = LightningClient.load()
        do {
            let loaded = try await radar
            timeline = loaded
            frameIndex = max(0, loaded.frames.count - 1)
            isPlaying = true
            loadError = nil
        } catch {
            loadError = "Radar is unavailable right now."
        }
        lightning = await lightningOverlay
    }

    private func loadLightning() async {
        lightning = await LightningClient.load()
    }
}

final class WeatherTileOverlay: MKTileOverlay {
    enum Kind {
        case radar
        case lightning
    }

    let kind: Kind

    init(urlTemplate: String, kind: Kind) {
        self.kind = kind
        super.init(urlTemplate: urlTemplate)
        canReplaceMapContent = false
        minimumZ = 1
        maximumZ = 7
        switch kind {
        case .radar:
            tileSize = CGSize(width: 512, height: 512)
        case .lightning:
            tileSize = CGSize(width: 256, height: 256)
        }
    }
}

struct RadarMapView: UIViewRepresentable {
    var coordinate: CLLocationCoordinate2D
    var placeName: String
    var template: String?
    var lightningEnabled: Bool
    var lightningTemplates: [String]

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView(frame: .zero)
        map.delegate = context.coordinator
        map.overrideUserInterfaceStyle = .dark
        map.pointOfInterestFilter = .excludingAll
        map.showsCompass = false
        map.showsUserLocation = true
        map.setRegion(
            MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 2.8, longitudeDelta: 2.8)),
            animated: false
        )
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        if abs(map.centerCoordinate.latitude - coordinate.latitude) > 0.35
            || abs(map.centerCoordinate.longitude - coordinate.longitude) > 0.35 {
            map.setCenter(coordinate, animated: true)
        }

        if context.coordinator.annotatedName != placeName {
            map.removeAnnotations(map.annotations.filter { $0 !== map.userLocation })
            let pin = MKPointAnnotation()
            pin.coordinate = coordinate
            pin.title = placeName
            map.addAnnotation(pin)
            context.coordinator.annotatedName = placeName
        }

        if context.coordinator.template != template {
            context.coordinator.template = template
            map.removeOverlays(context.coordinator.overlays(on: map, kind: .radar))
            if let template {
                let radar = WeatherTileOverlay(urlTemplate: template, kind: .radar)
                if let lightningOverlay = context.coordinator.overlays(on: map, kind: .lightning).first {
                    map.insertOverlay(radar, below: lightningOverlay)
                } else {
                    map.addOverlay(radar, level: .aboveLabels)
                }
            }
        }

        let lightningKey = lightningEnabled ? lightningTemplates.joined(separator: "|") : ""
        if context.coordinator.lightningKey != lightningKey {
            context.coordinator.lightningKey = lightningKey
            map.removeOverlays(context.coordinator.overlays(on: map, kind: .lightning))
            if lightningEnabled {
                for lightningTemplate in lightningTemplates {
                    map.addOverlay(
                        WeatherTileOverlay(urlTemplate: lightningTemplate, kind: .lightning),
                        level: .aboveLabels
                    )
                }
            }
        }
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var template: String?
        var lightningKey: String?
        var annotatedName: String?

        func overlays(on map: MKMapView, kind: WeatherTileOverlay.Kind) -> [MKOverlay] {
            map.overlays.filter { ($0 as? WeatherTileOverlay)?.kind == kind }
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let tile = overlay as? MKTileOverlay else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let renderer = MKTileOverlayRenderer(tileOverlay: tile)
            if let weather = tile as? WeatherTileOverlay, weather.kind == .lightning {
                renderer.alpha = 0.95
            } else {
                renderer.alpha = 0.8
            }
            return renderer
        }
    }
}
