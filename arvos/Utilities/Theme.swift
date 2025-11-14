//
//  Theme.swift
//  arvos
//
//  App-wide theme - clean Apple design
//

import SwiftUI

struct Theme {
    // MARK: - Corner Radius

    static let cornerRadius: CGFloat = 10
    static let largeCornerRadius: CGFloat = 12
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    var isDestructive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(isDestructive ? Color.red : Color.primary)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
