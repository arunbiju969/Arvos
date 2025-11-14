//
//  Theme.swift
//  arvos
//
//  App-wide theme with purple accent and glassy effects
//

import SwiftUI

struct Theme {
    // MARK: - Colors

    /// Primary purple accent color
    static let accent = Color(red: 0.58, green: 0.4, blue: 0.85) // #9466D9

    /// Lighter purple for backgrounds
    static var accentLight: Color {
        Color(red: 0.58, green: 0.4, blue: 0.85).opacity(0.2)
    }

    /// Darker purple for pressed states
    static let accentDark = Color(red: 0.48, green: 0.3, blue: 0.75)

    /// Gradient purple
    static var purpleGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.58, green: 0.4, blue: 0.85),
                Color(red: 0.68, green: 0.5, blue: 0.95)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Glass Materials

    /// Glass card background
    static var glassBackground: some View {
        ZStack {
            Color.white.opacity(0.1)
            Color.white.opacity(0.05)
                .blur(radius: 10)
        }
    }

    /// Glass card with blur
    static func glassCard(cornerRadius: CGFloat = 16) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }

    /// Thick glass effect
    static func thickGlass(cornerRadius: CGFloat = 16) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.thickMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
            )
    }

    /// Glass button style
    static func glassButton(cornerRadius: CGFloat = 12, isPressed: Bool = false) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(isPressed ? .thinMaterial : .ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    // MARK: - Shadows

    static var softShadow: Color {
        Color.black.opacity(0.1)
    }

    static var mediumShadow: Color {
        Color.black.opacity(0.15)
    }

    // MARK: - Corner Radius

    static let smallCornerRadius: CGFloat = 12
    static let mediumCornerRadius: CGFloat = 16
    static let largeCornerRadius: CGFloat = 24
}

// MARK: - Custom Button Styles

struct GlassButtonStyle: ButtonStyle {
    var color: Color = Theme.accent
    var cornerRadius: CGFloat = 12

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                ZStack {
                    if configuration.isPressed {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.thinMaterial)
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                    }

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct PurpleGlassButtonStyle: ButtonStyle {
    var isDestructive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                ZStack {
                    if isDestructive {
                        LinearGradient(
                            colors: [Color.red.opacity(0.8), Color.red.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        // Black button for START STREAMING
                        Color.black.opacity(configuration.isPressed ? 0.9 : 1.0)
                    }

                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                }
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .shadow(
                color: (isDestructive ? Color.red : Color.black).opacity(0.3),
                radius: configuration.isPressed ? 5 : 10,
                x: 0,
                y: configuration.isPressed ? 2 : 5
            )
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Glass Card Modifier

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 16
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Theme.softShadow, radius: 10, x: 0, y: 5)
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 16, padding: CGFloat = 16) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius, padding: padding))
    }
}
