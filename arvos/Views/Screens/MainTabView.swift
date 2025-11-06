//
//  MainTabView.swift
//  arvos
//
//  Main tab navigation
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var viewModel = StreamingViewModel()

    var body: some View {
        TabView {
            // Stream Tab
            StreamView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Stream", systemImage: "video.circle.fill")
                }

            // Settings Tab
            SettingsView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }

            // Files Tab
            FilesView()
                .tabItem {
                    Label("Files", systemImage: "folder.fill")
                }

            // Debug Tab
            DebugView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Debug", systemImage: "ant.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
}
