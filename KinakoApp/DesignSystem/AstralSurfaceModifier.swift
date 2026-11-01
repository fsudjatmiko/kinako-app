//
//  AstralSurfaceModifier.swift
//  KinakoApp
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

import SwiftUI

public struct AstralSurfaceModifier: ViewModifier {
    public var cut: CGFloat
    public var accentColor: Color
    public var showGlow: Bool

    public init(cut: CGFloat = 10, accentColor: Color = KinakoColor.accentLavender, showGlow: Bool = true) {
        self.cut = cut
        self.accentColor = accentColor
        self.showGlow = showGlow
    }

    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    KinakoColor.canvasCard
                    Rectangle().fill(.ultraThinMaterial)
                }
                .clipShape(SandalphonChamfer(cut: cut))
            )
            .overlay(
                // Crisp 0.5pt inner border for glassmorphic depth
                SandalphonChamfer(cut: cut)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                    .padding(0.5)
            )
            .overlay(
                // Thin Tohka energy border stroke (1.0pt)
                SandalphonChamfer(cut: cut)
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: accentColor.opacity(0.85), location: 0.0),
                                .init(color: KinakoColor.accentMagenta.opacity(0.35), location: 0.35),
                                .init(color: Color.white.opacity(0.1), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
            )
            .shadow(color: showGlow ? accentColor.opacity(0.18) : .clear, radius: 8, x: 0, y: 3)
    }
}

public extension View {
    func astralSurface(cut: CGFloat = 10, accentColor: Color = KinakoColor.accentLavender, showGlow: Bool = true) -> some View {
        self.modifier(AstralSurfaceModifier(cut: cut, accentColor: accentColor, showGlow: showGlow))
    }
}

