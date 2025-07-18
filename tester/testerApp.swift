//
//  testerApp.swift
//  tester
//
//  Created by Israel Kamuanga  on 7/4/25.
//

import SwiftUI

@main
struct testerApp: App {
    init() {
        UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 1920, height: 1080)
    }
}
