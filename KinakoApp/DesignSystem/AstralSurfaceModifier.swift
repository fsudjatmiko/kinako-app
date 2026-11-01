//
//  AstralSurfaceModifier.swift
//  KinakoApp
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

import SwiftUI

public struct AstralSurfaceModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    public var cut: CGFloat
    public var accentColor: Color
    public var showGlow: Bool

    public init(cut: CGFloat = 10, accentColor: Color = KinakoColor.accentPrimary, showGlow: Bool = true) {
        self.cut = cut
        self.accentColor = accentColor
        self.showGlow = showGlow
    }

    private var isDarkMode: Bool {
        colorScheme == .dark
    }

    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    KinakoColor.cardSurface
                    Rectangle().fill(.ultraThinMaterial)
                }
                .clipShape(SandalphonChamfer(cut: cut))
            )
            .overlay(
                // Crisp 0.5pt inner highlight line
                SandalphonChamfer(cut: cut)
                    .stroke(
                        isDarkMode ? Color.white.opacity(0.10) : Color.black.opacity(0.03),
                        lineWidth: 0.5
                    )
                    .padding(0.5)
            )
            .overlay(
                // 1.0pt outer border with light/dark ambient awareness
                SandalphonChamfer(cut: cut)
                    .stroke(
                        isDarkMode
                        ? LinearGradient(
                            stops: [
                                .init(color: accentColor.opacity(0.85), location: 0.0),
                                .init(color: KinakoColor.accentMagenta.opacity(0.35), location: 0.4),
                                .init(color: Color.white.opacity(0.1), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            stops: [
                                .init(color: accentColor.opacity(0.35), location: 0.0),
                                .init(color: Color.black.opacity(0.08), location: 0.6),
                                .init(color: Color.black.opacity(0.04), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
            )
            .shadow(
                color: isDarkMode
                    ? (showGlow ? accentColor.opacity(0.18) : .clear)
                    : Color.black.opacity(0.05),
                radius: 8,
                x: 0,
                y: 3
            )
    }
}

public extension View {
    func astralSurface(cut: CGFloat = 10, accentColor: Color = KinakoColor.accentPrimary, showGlow: Bool = true) -> some View {
        self.modifier(AstralSurfaceModifier(cut: cut, accentColor: accentColor, showGlow: showGlow))
    }
}
