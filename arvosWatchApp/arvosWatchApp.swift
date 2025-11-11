//
//  arvosWatchApp.swift
//  arvosWatchApp
//
//  Watch app entry point
//

import SwiftUI

@main
struct arvosWatchApp: App {
    @StateObject private var connectivityService = WatchConnectivityService.shared
    
    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(connectivityService)
        }
    }
}

