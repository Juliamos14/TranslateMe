//
//  TranslateMeApp.swift
//  TranslateMe
//

import SwiftUI

@main
struct TranslateMeApp: App {

    init() {
        // Connects to Firebase using GoogleService-Info.plist (if it's been added).
        FirebaseSetup.configureIfPossible()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
