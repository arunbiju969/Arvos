//
//  SplashScreenView.swift
//  arvos
//
//  Splash screen: Video for iPhone, Black for iPad
//

import SwiftUI
import AVKit

struct SplashScreenView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            // iPad: Simple black splash
            iPadSplash
        } else {
            // iPhone: Video splash
            iPhoneSplash
        }
    }

    // MARK: - iPad Splash (Black with Text)

    private var iPadSplash: some View {
        BlackSplashView()
    }

    // MARK: - iPhone Splash (Video)

    private var iPhoneSplash: some View {
        VideoSplashView()
    }
}

// MARK: - Black Splash for iPad

struct BlackSplashView: View {
    @State private var opacity = 0.0
    @State private var scale: CGFloat = 0.8

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            Text("ARVOS")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .opacity(opacity)
                .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                opacity = 1.0
                scale = 1.0
            }
        }
    }
}

// MARK: - Video Splash for iPhone

struct VideoSplashView: View {
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .disabled(true) // Disable controls
            } else {
                // Fallback while video loads
                Text("ARVOS")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            setupVideoPlayer()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    private func setupVideoPlayer() {
        // Look for splash video in bundle
        guard let videoURL = Bundle.main.url(forResource: "splash", withExtension: "mp4") else {
            print("⚠️ Splash video not found - using fallback")
            return
        }

        player = AVPlayer(url: videoURL)
        player?.isMuted = true // Mute the video
        player?.play()

        // Listen for video end to loop or stop
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { _ in
            // Video finished playing - will auto-transition via parent view
        }
    }
}

#Preview {
    SplashScreenView()
}
