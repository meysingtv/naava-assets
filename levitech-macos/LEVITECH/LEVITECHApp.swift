//
//  LEVITECHApp.swift
//  LEVITECH Workspace App — macOS (SwiftUI)
//
//  Native Portierung der LEVITECH IT-Service App im Handy-Format.
//

import SwiftUI

@main
struct LEVITECHApp: App {
    @StateObject private var store = Store()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .frame(minWidth: 440, minHeight: 900)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
}
