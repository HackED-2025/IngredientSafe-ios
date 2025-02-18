//
//  IngredientSafeApp.swift
//  IngredientSafe
//
//  Created by Jacob Feng on 2025-02-15.
//

import SwiftUI

@main
struct IngredientSafeApp: App {
    @StateObject var authVM = AuthViewModel()
    @StateObject var preferencesModel = PreferencesModel()
    @StateObject var favoritesModel = FavoritesModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authVM)
                .environmentObject(preferencesModel)
                .environmentObject(favoritesModel)
        }
    }
}
