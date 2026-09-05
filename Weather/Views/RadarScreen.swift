//
//  RadarScreen.swift
//  Weather
//

import Combine
import CoreLocation
import MapKit
import SwiftUI
import UIKit

struct RadarScreen: View {
    @Environment(WeatherStore.self) private var store
    @Environment(\.palette) private var palette
    @State private var timeline: RadarClient.Timeline?
    @State private var frameIndex = 0
    @State private var isPlaying = true
    @State private var loadError: String?
    @State private var lightningOn = true
    @State private var lightning: LightningClient.Overlay?

    private let timer = Timer.publish(every: 2.5, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .bottom) {
            RadarMapView(
                coordinate: coordinate,
                placeName: store.snapshot?.place.name ?? "Location",
                template: currentTemplate,
                lightningEnabled: lightningOn,
                lightningTemplates: lightning?.templates ?? [],
                onUserNavigated: { isPlaying = false }
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
    /// RainViewer and RealEarth only publish tiles through zoom 7. MapKit still
    /// asks for higher zooms so we upscale the parent tile instead of going blank.
    let nativeMaxZ = 7

    private let templateLock = NSLock()
    private var currentTemplate: String

    init(urlTemplate: String, kind: Kind) {
        self.kind = kind
        self.currentTemplate = urlTemplate
        super.init(urlTemplate: urlTemplate)
        canReplaceMapContent = false
        minimumZ = 1
        maximumZ = 12
        switch kind {
        case .radar:
            tileSize = CGSize(width: 512, height: 512)
        case .lightning:
            tileSize = CGSize(width: 256, height: 256)
        }
    }

    func updateTemplate(_ template: String) {
        templateLock.lock()
        currentTemplate = template
        templateLock.unlock()
    }

    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        let shift = max(0, path.z - nativeMaxZ)
        let nativeZ = path.z - shift
        let parentX = path.x >> shift
        let parentY = path.y >> shift

        templateLock.lock()
        let template = currentTemplate
        templateLock.unlock()

        guard let url = Self.url(template: template, z: nativeZ, x: parentX, y: parentY) else {
            result(nil, nil)
            return
        }

        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 20)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                result(nil, error)
                return
            }
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                result(nil, nil)
                return
            }
            guard let data else {
                result(nil, nil)
                return
            }
            if shift == 0 {
                result(data, nil)
                return
            }
            result(Self.overzoomedTile(from: data, path: path, shift: shift, outputSize: self.tileSize), nil)
        }.resume()
    }

    private static func url(template: String, z: Int, x: Int, y: Int) -> URL? {
        let filled = template
            .replacingOccurrences(of: "{z}", with: String(z))
            .replacingOccurrences(of: "{x}", with: String(x))
            .replacingOccurrences(of: "{y}", with: String(y))
        return URL(string: filled)
    }

    private static func overzoomedTile(
        from data: Data,
        path: MKTileOverlayPath,
        shift: Int,
        outputSize: CGSize
    ) -> Data? {
        guard let image = UIImage(data: data)?.cgImage else { return data }
        let scale = 1 << shift
        let cropW = image.width / scale
        let cropH = image.height / scale
        guard cropW > 0, cropH > 0 else { return data }

        let subX = path.x % scale
        let subY = path.y % scale
        let cropRect = CGRect(x: subX * cropW, y: subY * cropH, width: cropW, height: cropH)
        guard let cropped = image.cropping(to: cropRect) else { return data }

        let width = Int(outputSize.width)
        let height = Int(outputSize.height)
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return data }

        context.interpolationQuality = .none
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        context.draw(cropped, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let scaled = context.makeImage() else { return data }
        return UIImage(cgImage: scaled).pngData()
    }
}

struct RadarMapView: UIViewRepresentable {
    var coordinate: CLLocationCoordinate2D
    var placeName: String
    var template: String?
    var lightningEnabled: Bool
    var lightningTemplates: [String]
    var onUserNavigated: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onUserNavigated: onUserNavigated)
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
        context.coordinator.centeredCoordinate = coordinate
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        context.coordinator.onUserNavigated = onUserNavigated

        if context.coordinator.annotatedName != placeName {
            map.removeAnnotations(map.annotations.filter { $0 !== map.userLocation })
            let pin = MKPointAnnotation()
            pin.coordinate = coordinate
            pin.title = placeName
            map.addAnnotation(pin)
            context.coordinator.annotatedName = placeName
        }

        let placeMoved =
            abs(context.coordinator.centeredCoordinate.latitude - coordinate.latitude) > 0.2
            || abs(context.coordinator.centeredCoordinate.longitude - coordinate.longitude) > 0.2
        if placeMoved && !context.coordinator.userHasMovedMap {
            map.setRegion(
                MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 2.8, longitudeDelta: 2.8)),
                animated: true
            )
            context.coordinator.centeredCoordinate = coordinate
        }

        if context.coordinator.template != template {
            context.coordinator.template = template
            if let overlay = context.coordinator.radarOverlay, let template {
                overlay.updateTemplate(template)
                context.coordinator.radarRenderer?.reloadData()
            } else {
                map.removeOverlays(context.coordinator.overlays(on: map, kind: .radar))
                context.coordinator.radarOverlay = nil
                context.coordinator.radarRenderer = nil
                if let template {
                    let radar = WeatherTileOverlay(urlTemplate: template, kind: .radar)
                    context.coordinator.radarOverlay = radar
                    if let lightningOverlay = context.coordinator.overlays(on: map, kind: .lightning).first {
                        map.insertOverlay(radar, below: lightningOverlay)
                    } else {
                        map.addOverlay(radar, level: .aboveLabels)
                    }
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
        var centeredCoordinate = CLLocationCoordinate2D()
        var userHasMovedMap = false
        var radarOverlay: WeatherTileOverlay?
        weak var radarRenderer: MKTileOverlayRenderer?
        var onUserNavigated: () -> Void

        init(onUserNavigated: @escaping () -> Void) {
            self.onUserNavigated = onUserNavigated
        }

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
                renderer.alpha = 0.85
                radarRenderer = renderer
            }
            return renderer
        }

        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            guard isUserDriven(mapView) else { return }
            userHasMovedMap = true
            onUserNavigated()
        }

        private func isUserDriven(_ mapView: MKMapView) -> Bool {
            let recognizers = (mapView.gestureRecognizers ?? [])
                + mapView.subviews.flatMap { $0.gestureRecognizers ?? [] }
            return recognizers.contains { recognizer in
                (recognizer is UIPanGestureRecognizer || recognizer is UIPinchGestureRecognizer)
                    && (recognizer.state == .began || recognizer.state == .changed)
            }
        }
    }
}
