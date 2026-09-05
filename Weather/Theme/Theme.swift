//
//  Theme.swift
//  Weather
//

import SwiftUI

enum Pine {
    static let pine = Color(red: 0.18, green: 0.49, blue: 0.20)
    static let pine400 = Color(red: 0.31, green: 0.67, blue: 0.36)
    static let pine300 = Color(red: 0.48, green: 0.77, blue: 0.52)
    static let pine100 = Color(red: 0.84, green: 0.93, blue: 0.85)
    static let pine50 = Color(red: 0.93, green: 0.97, blue: 0.94)
    static let bark = Color(red: 0.027, green: 0.043, blue: 0.031)
    static let bark900 = Color(red: 0.047, green: 0.071, blue: 0.055)
    static let bark850 = Color(red: 0.071, green: 0.102, blue: 0.078)
    static let ink = Color(red: 0.91, green: 0.94, blue: 0.91)
    static let muted = Color(red: 0.72, green: 0.82, blue: 0.74).opacity(0.72)
    static let gold = Color(red: 0.92, green: 0.70, blue: 0.03)
    static let border = Color(red: 0.18, green: 0.49, blue: 0.20).opacity(0.38)

    static func display(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case dark
    case live
    case classic
    case light

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dark: "Dark"
        case .live: "Live Weather"
        case .classic: "PineDev Classic"
        case .light: "Light"
        }
    }

    var joke: String? {
        self == .light ? "please don't use this" : nil
    }

    var subtitle: String {
        switch self {
        case .dark: "Super sleek and modern. Advanced stats stay front and center."
        case .live: "Backgrounds and weather art match what's happening outside."
        case .classic: "The original Pinecone dark-forest look, if you're feeling nostalgic."
        case .light: "Bright mode. We tried to warn you."
        }
    }

    var icon: String {
        switch self {
        case .dark: "moon.stars.fill"
        case .live: "cloud.sun.fill"
        case .classic: "tree.fill"
        case .light: "sun.max.fill"
        }
    }

    var preferredColorScheme: ColorScheme {
        self == .light ? .light : .dark
    }
}

struct ThemePalette {
    var text: Color
    var muted: Color
    var accent: Color
    var accentSoft: Color
    var gold: Color
    var cardFill: Color
    var cardFillAlt: Color
    var border: Color
    var chipFill: Color
    var barTrack: Color
    var barColors: [Color]
    var chartFill: Color
    var chartLine: Color
    var heroEyebrow: String
    var usesSerif: Bool
    var tabTitle: String

    func display(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: usesSerif ? .serif : .default)
    }

    func captionFont() -> Font {
        .system(size: 11, weight: .semibold, design: usesSerif ? .serif : .rounded)
    }

    static func make(theme: AppTheme, code: Int, isDay: Bool) -> ThemePalette {
        switch theme {
        case .classic: classic
        case .dark: dark
        case .light: light
        case .live: live(code: code, isDay: isDay)
        }
    }

    static let classic = ThemePalette(
        text: Pine.pine50,
        muted: Pine.muted,
        accent: Pine.pine400,
        accentSoft: Pine.pine300,
        gold: Pine.gold,
        cardFill: Color.black.opacity(0.48),
        cardFillAlt: Pine.bark850.opacity(0.55),
        border: Pine.border,
        chipFill: Pine.bark.opacity(0.55),
        barTrack: Pine.bark850,
        barColors: [Pine.pine, Pine.pine400, Pine.gold],
        chartFill: Pine.pine400.opacity(0.35),
        chartLine: Pine.pine300,
        heroEyebrow: "THE GROVE",
        usesSerif: true,
        tabTitle: "Grove"
    )

    static let dark = ThemePalette(
        text: Color(red: 0.96, green: 0.97, blue: 0.98),
        muted: Color.white.opacity(0.55),
        accent: Color(red: 0.45, green: 0.78, blue: 0.98),
        accentSoft: Color(red: 0.62, green: 0.84, blue: 0.98),
        gold: Color(red: 1.0, green: 0.78, blue: 0.28),
        cardFill: Color.white.opacity(0.06),
        cardFillAlt: Color(red: 0.10, green: 0.11, blue: 0.13).opacity(0.92),
        border: Color.white.opacity(0.10),
        chipFill: Color.white.opacity(0.05),
        barTrack: Color.white.opacity(0.08),
        barColors: [Color(red: 0.35, green: 0.72, blue: 0.98), Color(red: 0.72, green: 0.85, blue: 1.0), Color(red: 1.0, green: 0.82, blue: 0.40)],
        chartFill: Color(red: 0.45, green: 0.78, blue: 0.98).opacity(0.28),
        chartLine: Color(red: 0.62, green: 0.86, blue: 1.0),
        heroEyebrow: "CURRENT",
        usesSerif: false,
        tabTitle: "Weather"
    )

    static let light = ThemePalette(
        text: Color(red: 0.12, green: 0.13, blue: 0.15),
        muted: Color.black.opacity(0.48),
        accent: Color(red: 0.12, green: 0.42, blue: 0.78),
        accentSoft: Color(red: 0.20, green: 0.50, blue: 0.82),
        gold: Color(red: 0.78, green: 0.52, blue: 0.05),
        cardFill: Color.white.opacity(0.78),
        cardFillAlt: Color(red: 0.97, green: 0.96, blue: 0.93),
        border: Color.black.opacity(0.08),
        chipFill: Color.white.opacity(0.9),
        barTrack: Color.black.opacity(0.08),
        barColors: [Color(red: 0.20, green: 0.52, blue: 0.86), Color(red: 0.98, green: 0.72, blue: 0.22)],
        chartFill: Color(red: 0.20, green: 0.50, blue: 0.86).opacity(0.22),
        chartLine: Color(red: 0.12, green: 0.42, blue: 0.78),
        heroEyebrow: "CURRENT",
        usesSerif: false,
        tabTitle: "Weather"
    )

    static func live(code: Int, isDay: Bool) -> ThemePalette {
        var palette = dark
        palette.heroEyebrow = "LIVE SKY"
        palette.tabTitle = "Weather"
        palette.usesSerif = false
        if WeatherCode.isThunderstorm(code) {
            palette.accent = Color(red: 0.78, green: 0.72, blue: 1.0)
            palette.accentSoft = Color(red: 0.88, green: 0.82, blue: 1.0)
        } else if WeatherCode.isSnow(code) {
            palette.accent = Color(red: 0.78, green: 0.90, blue: 1.0)
        } else if WeatherCode.isRain(code) {
            palette.accent = Color(red: 0.55, green: 0.82, blue: 0.95)
        } else if isDay {
            palette.accent = Color(red: 1.0, green: 0.86, blue: 0.42)
            palette.accentSoft = Color(red: 1.0, green: 0.93, blue: 0.65)
        } else {
            palette.accent = Color(red: 0.70, green: 0.78, blue: 1.0)
        }
        palette.cardFill = Color.black.opacity(0.28)
        palette.cardFillAlt = Color.black.opacity(0.22)
        palette.border = Color.white.opacity(0.16)
        return palette
    }
}

private struct PaletteKey: EnvironmentKey {
    static let defaultValue = ThemePalette.dark
}

extension EnvironmentValues {
    var palette: ThemePalette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}

struct ForestBackdrop: View {
    var weatherCode: Int = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.09, green: 0.19, blue: 0.11),
                    Pine.bark900,
                    Pine.bark
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [Color(red: 0.71, green: 0.82, blue: 0.63).opacity(0.16), .clear],
                center: UnitPoint(x: 0.78, y: 0.12),
                startRadius: 8,
                endRadius: 160
            )
            TimelineView(.animation(minimumInterval: 1 / 20, paused: false)) { timeline in
                Canvas { context, size in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    drawMoon(context: context, size: size)
                    drawStars(context: context, size: size, time: time)
                    drawTrees(context: context, size: size, time: time)
                    drawFog(context: context, size: size, time: time)
                    drawFireflies(context: context, size: size, time: time)
                }
            }
            LinearGradient(
                colors: [Color.black.opacity(0.18), .clear, Color.black.opacity(0.45)],
                startPoint: .top,
                endPoint: .bottom
            )
            WeatherParticles(code: weatherCode)
        }
        .ignoresSafeArea()
    }

    private func drawMoon(context: GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width * 0.78, y: size.height * 0.11)
        let glow = Path(ellipseIn: CGRect(x: center.x - 46, y: center.y - 46, width: 92, height: 92))
        context.fill(glow, with: .radialGradient(
            Gradient(colors: [Color(red: 0.82, green: 0.90, blue: 0.75).opacity(0.28), .clear]),
            center: center,
            startRadius: 4,
            endRadius: 46
        ))
        let moon = Path(ellipseIn: CGRect(x: center.x - 16, y: center.y - 16, width: 32, height: 32))
        context.fill(moon, with: .color(Color(red: 0.86, green: 0.92, blue: 0.78).opacity(0.55)))
    }

    private func drawStars(context: GraphicsContext, size: CGSize, time: TimeInterval) {
        let stars: [(CGFloat, CGFloat, CGFloat, Double)] = [
            (0.12, 0.08, 2.0, 0), (0.22, 0.14, 1.2, 1.2), (0.38, 0.06, 2.0, 0.4),
            (0.48, 0.18, 1.0, 2.0), (0.61, 0.10, 2.0, 0.8), (0.74, 0.05, 1.0, 1.6),
            (0.82, 0.16, 2.0, 0.2), (0.91, 0.09, 1.0, 2.4), (0.08, 0.22, 1.2, 1.1),
            (0.33, 0.12, 1.0, 1.8), (0.55, 0.20, 1.2, 0.6), (0.68, 0.07, 2.0, 2.1)
        ]
        for star in stars {
            let pulse = 0.35 + 0.65 * (0.5 + 0.5 * sin(time * 1.6 + star.3))
            let rect = CGRect(
                x: star.0 * size.width,
                y: star.1 * size.height,
                width: star.2,
                height: star.2
            )
            context.fill(Path(ellipseIn: rect), with: .color(Pine.pine100.opacity(pulse)))
        }
    }

    private func drawTrees(context: GraphicsContext, size: CGSize, time: TimeInterval) {
        let trees: [(CGFloat, CGFloat, CGFloat, Double, Double)] = [
            (0.02, 0.42, 0.78, 0.45, 0),
            (0.14, 0.50, 0.72, 0.55, 1.4),
            (0.28, 0.36, 0.82, 0.48, 2.2),
            (0.46, 0.54, 0.70, 0.42, 0.7),
            (0.62, 0.40, 0.86, 0.52, 1.8),
            (0.78, 0.48, 0.74, 0.58, 0.3),
            (0.92, 0.38, 0.90, 0.50, 2.6),
            (-0.06, 0.58, 0.95, 0.92, 0.2),
            (0.18, 0.62, 1.05, 0.96, 1.1),
            (0.72, 0.60, 1.12, 0.94, 1.9),
            (0.88, 0.66, 1.18, 1.0, 0.6)
        ]
        for tree in trees {
            let sway = sin(time / 3.4 + tree.4) * 0.035
            var context = context
            let base = CGPoint(x: tree.0 * size.width, y: size.height)
            context.translateBy(x: base.x, y: base.y)
            context.rotate(by: .radians(sway))
            drawPine(context: &context, height: size.height * tree.1, width: size.width * 0.28, opacity: tree.3)
        }
    }

    private func drawPine(context: inout GraphicsContext, height: CGFloat, width: CGFloat, opacity: Double) {
        let fill = Color(red: 0.04, green: 0.10, blue: 0.06).opacity(opacity)
        let stroke = Color(red: 0.14, green: 0.36, blue: 0.20).opacity(opacity * 0.7)
        let layers = [
            (peak: height * 0.08, bottom: height * 0.42, spread: 0.38),
            (peak: height * 0.22, bottom: height * 0.64, spread: 0.48),
            (peak: height * 0.40, bottom: height * 0.92, spread: 0.56)
        ]
        for layer in layers {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: -layer.peak))
            path.addLine(to: CGPoint(x: width * layer.spread, y: -layer.bottom))
            path.addLine(to: CGPoint(x: -width * layer.spread, y: -layer.bottom))
            path.closeSubpath()
            context.fill(path, with: .color(fill))
            context.stroke(path, with: .color(stroke), lineWidth: 1)
        }
        let trunk = Path(roundedRect: CGRect(x: -width * 0.04, y: -height * 0.08, width: width * 0.08, height: height * 0.10), cornerRadius: 2)
        context.fill(trunk, with: .color(Color.black.opacity(opacity)))
    }

    private func drawFog(context: GraphicsContext, size: CGSize, time: TimeInterval) {
        let shift = sin(time / 9) * size.width * 0.06
        let rect = CGRect(x: -size.width * 0.1 + shift, y: size.height * 0.62, width: size.width * 1.2, height: 90)
        context.fill(
            Path(ellipseIn: rect),
            with: .linearGradient(
                Gradient(colors: [.clear, Color(red: 0.47, green: 0.63, blue: 0.47).opacity(0.10), .clear]),
                startPoint: CGPoint(x: rect.minX, y: rect.midY),
                endPoint: CGPoint(x: rect.maxX, y: rect.midY)
            )
        )
    }

    private func drawFireflies(context: GraphicsContext, size: CGSize, time: TimeInterval) {
        let flies: [(CGFloat, CGFloat, Double, Double)] = [
            (0.18, 0.72, 0, 9), (0.32, 0.64, 2, 11), (0.47, 0.76, 5, 8),
            (0.63, 0.60, 1, 12), (0.78, 0.70, 4, 10), (0.25, 0.52, 7, 13)
        ]
        for fly in flies {
            let phase = (time + fly.2) / fly.3
            let x = fly.0 * size.width + sin(phase * .pi * 2) * 18
            let y = fly.1 * size.height + cos(phase * .pi * 2) * 14
            let glow = 0.25 + 0.75 * (0.5 + 0.5 * sin(phase * .pi * 2))
            let rect = CGRect(x: x, y: y, width: 3, height: 3)
            context.fill(Path(ellipseIn: rect.insetBy(dx: -4, dy: -4)), with: .color(Pine.pine300.opacity(0.18 * glow)))
            context.fill(Path(ellipseIn: rect), with: .color(Pine.pine300.opacity(glow)))
        }
    }
}

struct WeatherParticles: View {
    let code: Int

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: false)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                if WeatherCode.isSnow(code) {
                    drawSnow(context: context, size: size, time: time)
                } else if WeatherCode.isRain(code) || WeatherCode.isThunderstorm(code) {
                    drawRain(context: context, size: size, time: time, storm: WeatherCode.isThunderstorm(code))
                }
            }
        }
        .allowsHitTesting(false)
        .opacity(0.4)
    }

    private func drawRain(context: GraphicsContext, size: CGSize, time: TimeInterval, storm: Bool) {
        let count = storm ? 80 : 48
        for index in 0..<count {
            var rng = SeededRandom(seed: UInt64(index + 17))
            let x = rng.next() * size.width
            let speed = storm ? 420.0 : 280.0
            let y = (rng.next() * size.height + CGFloat(time) * speed).truncatingRemainder(dividingBy: size.height + 40) - 20
            var path = Path()
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x + 2, y: y + (storm ? 16 : 11)))
            context.stroke(path, with: .color(Pine.pine100.opacity(storm ? 0.45 : 0.28)), lineWidth: 1)
        }
    }

    private func drawSnow(context: GraphicsContext, size: CGSize, time: TimeInterval) {
        for index in 0..<40 {
            var rng = SeededRandom(seed: UInt64(index + 91))
            let drift = sin(time * 0.6 + Double(index)) * 18
            let x = rng.next() * size.width + drift
            let speed = 40.0 + rng.next() * 50
            let y = (rng.next() * size.height + CGFloat(time) * speed).truncatingRemainder(dividingBy: size.height + 20) - 10
            let radius = 1.4 + rng.next() * 2.2
            context.fill(
                Path(ellipseIn: CGRect(x: x, y: y, width: radius, height: radius)),
                with: .color(Pine.pine100.opacity(0.7))
            )
        }
    }
}

private struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed &* 6364136223846793005 &+ 1
    }

    mutating func next() -> CGFloat {
        state = state &* 6364136223846793005 &+ 1
        return CGFloat(Double(state % 10_000) / 10_000)
    }
}

struct GroveCard<Content: View>: View {
    var title: String = ""
    var systemImage: String = ""
    @Environment(\.palette) private var palette
    @ViewBuilder var content: () -> Content

    init(title: String = "", systemImage: String = "", @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !title.isEmpty {
                Label(title, systemImage: systemImage)
                    .font(palette.captionFont())
                    .foregroundStyle(palette.accentSoft.opacity(0.95))
                    .textCase(.uppercase)
                    .tracking(1.6)
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(palette.cardFill)
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(palette.cardFillAlt)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(palette.border, lineWidth: 1)
        }
    }
}

struct GlassCard<Content: View>: View {
    var title: String
    var systemImage: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        GroveCard(title: title, systemImage: systemImage, content: content)
    }
}

struct MetricTile: View {
    var title: String
    var systemImage: String
    var value: String
    var detail: String
    @Environment(\.palette) private var palette

    var body: some View {
        GroveCard(title: title, systemImage: systemImage) {
            Text(value)
                .font(palette.display(28, weight: .semibold))
                .foregroundStyle(palette.text)
            Text(detail)
                .font(.footnote)
                .foregroundStyle(palette.muted)
        }
    }
}

struct AppBackdrop: View {
    var theme: AppTheme
    var weatherCode: Int = 0
    var isDay: Bool = true

    var body: some View {
        switch theme {
        case .classic:
            ForestBackdrop(weatherCode: weatherCode)
        case .dark:
            DarkBackdrop()
        case .light:
            LightBackdrop()
        case .live:
            LiveWeatherBackdrop(code: weatherCode, isDay: isDay)
        }
    }
}

struct DarkBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.08, blue: 0.10),
                    Color(red: 0.04, green: 0.045, blue: 0.055),
                    Color(red: 0.02, green: 0.02, blue: 0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [Color(red: 0.28, green: 0.40, blue: 0.55).opacity(0.18), .clear],
                center: UnitPoint(x: 0.85, y: 0.0),
                startRadius: 10,
                endRadius: 380
            )
            LinearGradient(
                colors: [Color.white.opacity(0.04), .clear],
                startPoint: .top,
                endPoint: .center
            )
        }
        .ignoresSafeArea()
    }
}

struct LightBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.95, blue: 0.92),
                    Color(red: 0.93, green: 0.94, blue: 0.96),
                    Color(red: 0.89, green: 0.91, blue: 0.94)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [Color(red: 1.0, green: 0.92, blue: 0.72).opacity(0.35), .clear],
                center: UnitPoint(x: 0.85, y: 0.08),
                startRadius: 4,
                endRadius: 260
            )
        }
        .ignoresSafeArea()
    }
}

struct LiveWeatherBackdrop: View {
    var code: Int
    var isDay: Bool

    var body: some View {
        ZStack {
            LinearGradient(colors: skyColors, startPoint: .top, endPoint: .bottom)
            RadialGradient(
                colors: [glowColor, .clear],
                center: UnitPoint(x: 0.78, y: 0.12),
                startRadius: 6,
                endRadius: 280
            )
            weatherArt
                .foregroundStyle(.white.opacity(isDay && !WeatherCode.isThunderstorm(code) ? 0.28 : 0.18))
                .offset(x: 70, y: -40)
                .allowsHitTesting(false)
            WeatherParticles(code: code)
            LinearGradient(
                colors: [Color.black.opacity(0.12), .clear, Color.black.opacity(0.38)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.6), value: code)
    }

    private var weatherArt: some View {
        Image(systemName: WeatherCode.symbol(code, isDay: isDay))
            .font(.system(size: 220, weight: .ultraLight))
            .symbolRenderingMode(.hierarchical)
    }

    private var glowColor: Color {
        if WeatherCode.isThunderstorm(code) { return Color.purple.opacity(0.35) }
        if WeatherCode.isSnow(code) { return Color.white.opacity(0.22) }
        if WeatherCode.isRain(code) { return Color.cyan.opacity(0.18) }
        return isDay ? Color.yellow.opacity(0.28) : Color.blue.opacity(0.22)
    }

    private var skyColors: [Color] {
        if WeatherCode.isThunderstorm(code) {
            return [Color(red: 0.10, green: 0.08, blue: 0.22), Color(red: 0.05, green: 0.05, blue: 0.10)]
        }
        if WeatherCode.isSnow(code) {
            return [Color(red: 0.42, green: 0.50, blue: 0.58), Color(red: 0.18, green: 0.22, blue: 0.28)]
        }
        if WeatherCode.isRain(code) {
            return [Color(red: 0.16, green: 0.24, blue: 0.34), Color(red: 0.06, green: 0.10, blue: 0.16)]
        }
        switch code {
        case 45, 48:
            return [Color(red: 0.45, green: 0.47, blue: 0.48), Color(red: 0.22, green: 0.23, blue: 0.24)]
        case 2, 3:
            return isDay
                ? [Color(red: 0.38, green: 0.52, blue: 0.66), Color(red: 0.16, green: 0.24, blue: 0.34)]
                : [Color(red: 0.12, green: 0.16, blue: 0.28), Color(red: 0.04, green: 0.05, blue: 0.10)]
        default:
            return isDay
                ? [Color(red: 0.28, green: 0.58, blue: 0.86), Color(red: 0.12, green: 0.32, blue: 0.58)]
                : [Color(red: 0.06, green: 0.08, blue: 0.22), Color(red: 0.02, green: 0.03, blue: 0.08)]
        }
    }
}
