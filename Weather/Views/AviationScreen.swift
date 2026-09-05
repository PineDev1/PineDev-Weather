//
//  AviationScreen.swift
//  Weather
//

import CoreLocation
import SwiftUI

struct AviationScreen: View {
    @Environment(WeatherStore.self) private var weather
    @Environment(AviationStore.self) private var aviation
    @Environment(\.palette) private var palette
    @FocusState private var fieldFocused: Bool

    var body: some View {
        @Bindable var aviation = aviation
        NavigationStack {
            ZStack {
                AppBackdrop(
                    theme: weather.theme,
                    weatherCode: weather.snapshot?.current.weatherCode ?? 0,
                    isDay: weather.snapshot?.current.isDay ?? true
                )
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        header
                        search
                        recents
                        if let message = aviation.errorMessage {
                            Text(message)
                                .font(.footnote)
                                .foregroundStyle(palette.gold)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        if aviation.isLoading {
                            ProgressView()
                                .tint(palette.accentSoft)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 24)
                        } else if let briefing = aviation.briefing {
                            briefingViews(briefing)
                        }
                        Text("METARs and TAFs from NOAA Aviation Weather Center")
                            .font(.caption)
                            .foregroundStyle(palette.muted)
                            .padding(.bottom, 28)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Aviation")
                        .font(palette.display(17, weight: .semibold))
                        .foregroundStyle(palette.text)
                }
            }
            .task {
                if aviation.briefing == nil {
                    if let place = weather.snapshot?.place {
                        await aviation.lookupNearest(latitude: place.latitude, longitude: place.longitude)
                    } else {
                        await aviation.lookup(aviation.query)
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("STATION BRIEFING")
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .tracking(2.4)
                .foregroundStyle(palette.accentSoft)
            Text("METARs & TAFs")
                .font(palette.display(32, weight: .regular))
                .foregroundStyle(palette.text)
            Text("Look up any ICAO station for live observations and terminal forecasts.")
                .font(.subheadline)
                .foregroundStyle(palette.muted)
        }
    }

    private var search: some View {
        @Bindable var aviation = aviation
        return GroveCard(title: "Airport station", systemImage: "airplane") {
            HStack(spacing: 10) {
                TextField("KJFK, EGLL, YXE", text: $aviation.query)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(palette.text)
                    .focused($fieldFocused)
                    .onSubmit {
                        Task { await aviation.lookup(aviation.query) }
                    }
                Button {
                    Task { await aviation.lookup(aviation.query) }
                } label: {
                    Text("Go")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(palette.accent, in: Capsule())
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            if weather.snapshot?.place != nil || weather.location.coordinate != nil {
                Button {
                    Task {
                        if let place = weather.snapshot?.place {
                            await aviation.lookupNearest(latitude: place.latitude, longitude: place.longitude)
                        } else if let coordinate = weather.location.coordinate {
                            await aviation.lookupNearest(latitude: coordinate.latitude, longitude: coordinate.longitude)
                        }
                    }
                } label: {
                    Label("Nearest station to current place", systemImage: "location.viewfinder")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(palette.accentSoft)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
    }

    private var recents: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(aviation.recents, id: \.self) { code in
                    Button {
                        aviation.query = code
                        Task { await aviation.lookup(code) }
                    } label: {
                        Text(code)
                            .font(.system(.caption, design: .monospaced).weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().strokeBorder(
                                    aviation.briefing?.icao == code ? palette.accent : palette.border,
                                    lineWidth: 1
                                )
                            )
                            .foregroundStyle(palette.text)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func briefingViews(_ briefing: AviationBriefing) -> some View {
        categoryCard(briefing)
        decodedGrid(briefing)
        GroveCard(title: "Raw METAR", systemImage: "text.alignleft") {
            Text(briefing.rawMetar)
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(palette.text)
                .textSelection(.enabled)
        }
        if !briefing.tafPeriods.isEmpty || briefing.rawTaf != nil {
            tafCard(briefing)
        }
    }

    private func categoryCard(_ briefing: AviationBriefing) -> some View {
        GroveCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(briefing.icao)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(palette.text)
                    Text(briefing.name)
                        .font(.subheadline)
                        .foregroundStyle(palette.muted)
                    if let observed = briefing.observedAt {
                        Text("Observed \(observed.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(palette.muted)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(briefing.flightCategory.shortLabel)
                        .font(.system(size: 22, weight: .heavy, design: .serif))
                    Text(briefing.flightCategory.title)
                        .font(.caption2)
                        .multilineTextAlignment(.trailing)
                }
                .foregroundStyle(categoryColor(briefing.flightCategory))
                .padding(12)
                .background(categoryColor(briefing.flightCategory).opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private func decodedGrid(_ briefing: AviationBriefing) -> some View {
        let temp = briefing.temperatureC.map { celsius in
            weather.units == .metric
                ? "\(Int(celsius.rounded()))°C"
                : "\(Int((celsius * 9 / 5 + 32).rounded()))°F"
        } ?? "—"
        let dew = briefing.dewpointC.map { celsius in
            weather.units == .metric
                ? "\(Int(celsius.rounded()))°C"
                : "\(Int((celsius * 9 / 5 + 32).rounded()))°F"
        } ?? "—"

        return VStack(spacing: 12) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricTile(title: "Wind", systemImage: "wind", value: briefing.wind, detail: "Surface winds")
                MetricTile(title: "Visibility", systemImage: "eye", value: briefing.visibility, detail: "Statute miles")
                MetricTile(title: "Temperature", systemImage: "thermometer.medium", value: temp, detail: "Dew point \(dew)")
                MetricTile(title: "Altimeter", systemImage: "gauge.with.dots.needle.33percent", value: briefing.altimeter, detail: "Sea level pressure")
            }
            GroveCard(title: "Sky & weather", systemImage: "cloud") {
                Text(briefing.weather)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(palette.text)
                ForEach(briefing.clouds, id: \.self) { cloud in
                    Text(cloud)
                        .font(.footnote)
                        .foregroundStyle(palette.muted)
                }
            }
        }
    }

    private func tafCard(_ briefing: AviationBriefing) -> some View {
        GroveCard(title: "TAF forecast", systemImage: "clock.arrow.2.circlepath") {
            if let from = briefing.validFrom, let to = briefing.validTo {
                Text("Valid \(from.formatted(date: .abbreviated, time: .shortened)) – \(to.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(palette.muted)
            }
            ForEach(briefing.tafPeriods) { period in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(period.changeLabel)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(palette.accentSoft)
                        Spacer()
                        Text(periodWindow(period))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(palette.muted)
                    }
                    Text(periodSummary(period))
                        .font(.footnote)
                        .foregroundStyle(palette.text)
                }
                .padding(.vertical, 6)
                Divider().overlay(palette.border)
            }
            if let raw = briefing.rawTaf {
                Text(raw)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(palette.muted)
                    .textSelection(.enabled)
                    .padding(.top, 6)
            }
        }
    }

    private func periodWindow(_ period: TafPeriodJSON) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = .gmt
        let start = period.timeFrom.map { formatter.string(from: Date(timeIntervalSince1970: $0)) } ?? "—"
        let end = period.timeTo.map { formatter.string(from: Date(timeIntervalSince1970: $0)) } ?? "—"
        return "\(start)–\(end)Z"
    }

    private func periodSummary(_ period: TafPeriodJSON) -> String {
        var parts: [String] = []
        if let dir = period.wdir {
            let speed = period.wspd.map { "\(Int($0.rounded())) kt" } ?? ""
            let gust = period.wgst.map { "G\(Int($0.rounded()))" } ?? ""
            parts.append("Wind \(dir.text)° \(speed)\(gust)")
        }
        if let vis = period.visib { parts.append("Vis \(vis.text) SM") }
        if let wx = period.wxString, !wx.isEmpty { parts.append(wx) }
        let clouds = (period.clouds ?? []).map(\.summary).joined(separator: ", ")
        if !clouds.isEmpty { parts.append(clouds) }
        return parts.isEmpty ? "No detailed change" : parts.joined(separator: " · ")
    }

    private func categoryColor(_ category: FlightCategory) -> Color {
        switch category {
        case .vfr: palette.accent
        case .mvfr: Color(red: 0.35, green: 0.62, blue: 0.92)
        case .ifr: Color.red
        case .lifr: Color.purple
        case .unknown: palette.muted
        }
    }
}
