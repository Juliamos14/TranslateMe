//
//  FirebaseSetup.swift
//  TranslateMe
//
//  Firebase needs the GoogleService-Info.plist file from your Firebase
//  project. If it hasn't been added yet, the app still translates, and
//  shows a reminder instead of crashing.
//

import Foundation
import FirebaseCore

enum FirebaseSetup {

    private(set) static var isConfigured = false

    static var hasConfigFile: Bool {
        Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
    }

    static func configureIfPossible() {
        guard !isConfigured, hasConfigFile else { return }
        FirebaseApp.configure()
        isConfigured = true
    }
}
