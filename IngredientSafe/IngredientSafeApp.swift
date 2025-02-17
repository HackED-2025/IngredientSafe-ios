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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authVM)
        }
    }
}
