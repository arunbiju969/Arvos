//
//  arvosApp.swift
//  arvos
//
//  Created by JASKIRAT SINGH on 2025-11-06.
//

import SwiftUI

@main
struct arvosApp: App {
    @State private var showSplash = true
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()

                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                }

                if showOnboarding && !showSplash {
                    OnboardingView(isPresented: $showOnboarding)
                        .transition(.opacity)
                        .zIndex(2)
                }
            }
            .onAppear {
                // 8 seconds for iPhone video, 2 seconds for iPad
                let duration: Double = UIDevice.current.userInterfaceIdiom == .pad ? 2.0 : 8.0
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}
