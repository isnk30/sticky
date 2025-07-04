//
//  testerApp.swift
//  tester
//
//  Created by Israel Kamuanga  on 7/4/25.
//

import SwiftUI

@main
struct testerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 800, height: 600)
    }
}
