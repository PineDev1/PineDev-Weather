//
//  WeatherApp.swift
//  Weather
//
//  Created by Riley Starkey on 2026-09-05.
//

import SwiftUI

@main
struct WeatherApp: App {
    @State private var store = WeatherStore()
    @State private var aviation = AviationStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(aviation)
                .environment(\.palette, store.palette)
                .preferredColorScheme(store.theme.preferredColorScheme)
        }
    }
}
