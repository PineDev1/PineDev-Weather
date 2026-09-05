//
//  ContentView.swift
//  Weather
//
//  Created by Riley Starkey on 2026-09-05.
//

import SwiftUI

struct ContentView: View {
    @Environment(WeatherStore.self) private var store

    var body: some View {
        TabView {
            ForecastScreen()
                .tabItem {
                    Label(store.palette.tabTitle, systemImage: store.theme == .classic ? "tree.fill" : "cloud.sun.fill")
                }
            RadarScreen()
                .tabItem {
                    Label("Radar", systemImage: "cloud.rain.fill")
                }
            AviationScreen()
                .tabItem {
                    Label("Aviation", systemImage: "airplane")
                }
            SettingsScreen()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(store.palette.accent)
        .environment(\.palette, store.palette)
        .preferredColorScheme(store.theme.preferredColorScheme)
    }
}

#Preview {
    ContentView()
        .environment(WeatherStore())
        .environment(AviationStore())
}
