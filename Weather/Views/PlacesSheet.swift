//
//  PlacesSheet.swift
//  Weather
//

import SwiftUI

struct PlacesSheet: View {
    @Environment(WeatherStore.self) private var store
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss
    @FocusState private var searchFocused: Bool

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search cities or zip codes", text: $store.searchQuery)
                            .textInputAutocapitalization(.words)
                            .focused($searchFocused)
                            .onChange(of: store.searchQuery) { _, value in
                                store.updateSearch(value)
                            }
                        if store.isSearching {
                            ProgressView()
                        }
                    }
                }

                if store.location.needsRequest || !store.location.isAuthorized {
                    Section("Location") {
                        Button {
                            store.location.request()
                        } label: {
                            Label(
                                store.location.needsRequest ? "Use current location" : "Location access is off",
                                systemImage: "location.fill"
                            )
                        }
                    }
                }

                if !store.searchResults.isEmpty {
                    Section("Results") {
                        ForEach(store.searchResults) { result in
                            Button {
                                Task {
                                    let place = Place.fromGeocoding(result)
                                    store.save(place)
                                    await store.select(place)
                                    dismiss()
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(result.name)
                                        .foregroundStyle(.primary)
                                    if !result.subtitle.isEmpty {
                                        Text(result.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                Section("Saved") {
                    Button {
                        Task {
                            await store.selectCurrentLocation()
                            dismiss()
                        }
                    } label: {
                        Label("Current Location", systemImage: "location.fill")
                    }

                    ForEach(store.savedPlaces.filter { !$0.isCurrentLocation }) { place in
                        Button {
                            Task {
                                await store.select(place)
                                dismiss()
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(place.name)
                                if !place.detail.isEmpty {
                                    Text(place.detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .onDelete { indexSet in
                        let places = store.savedPlaces.filter { !$0.isCurrentLocation }
                        for index in indexSet {
                            store.remove(places[index])
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(store.theme == .light ? Color(red: 0.94, green: 0.94, blue: 0.92) : Color.black)
            .navigationTitle("Locations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
