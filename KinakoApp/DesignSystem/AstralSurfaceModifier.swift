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

    public init(cut: CGFloat = 12, accentColor: Color = KinakoColor.accentLavender, showGlow: Bool = true) {
        self.cut = cut
        self.accentColor = accentColor
        self.showGlow = showGlow
    }

    public func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: SandalphonChamfer(cut: cut))
            .background(KinakoColor.canvasCard.opacity(0.85), in: SandalphonChamfer(cut: cut))
            .overlay(
                SandalphonChamfer(cut: cut)
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: accentColor.opacity(0.9), location: 0.0),
                                .init(color: KinakoColor.accentMagenta.opacity(0.4), location: 0.35),
                                .init(color: Color.white.opacity(0.1), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
            .shadow(color: showGlow ? accentColor.opacity(0.2) : .clear, radius: 10, x: 0, y: 4)
    }
}

public extension View {
    func astralSurface(cut: CGFloat = 12, accentColor: Color = KinakoColor.accentLavender, showGlow: Bool = true) -> some View {
        self.modifier(AstralSurfaceModifier(cut: cut, accentColor: accentColor, showGlow: showGlow))
    }
}

