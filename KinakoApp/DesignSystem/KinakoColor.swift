//
//  KinakoColor.swift
//  KinakoApp
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public enum KinakoColor {
    // MARK: - Core Adaptive Semantic Tokens (Full Light & Dark Mode)

    /// Canvas Background: Deep obsidian in Dark Mode, crisp slate white in Light Mode
    public static let backgroundCanvas   = Color.adaptive(darkHex: "#0C0814", lightHex: "#F8FAFC")

    /// Card Surface: Layered slate in Dark Mode, pure elevated white in Light Mode
    public static let cardSurface        = Color.adaptive(darkHex: "#171026", lightHex: "#FFFFFF")

    /// Primary Typography: Pure White in Dark Mode, Deep Slate 900 in Light Mode
    public static let textPrimary        = Color.adaptive(darkHex: "#FFFFFF", lightHex: "#0F172A")

    /// Secondary Typography: Medium Slate in Dark Mode, Slate 600 in Light Mode
    public static let textSecondary      = Color.adaptive(darkHex: "#94A3B8", lightHex: "#64748B")

    /// Primary Brand Accent: High-contrast Electric Violet
    public static let accentPrimary      = Color(hex: "#9055FF")

    /// Subtle Accent / Tint Fill for frosted containers
    public static let accentSubtle       = Color.adaptive(
        dark: Color.white.opacity(0.06),
        light: Color.black.opacity(0.04)
    )

    // MARK: - Backwards-Compatible Tokens & Status Indicators

    public static let canvasMidnight     = backgroundCanvas
    public static let canvasCard         = cardSurface
    public static let surfaceFrosted     = accentSubtle

    public static let accentLavender     = accentPrimary
    public static let accentMagenta      = Color.adaptive(darkHex: "#E03BE5", lightHex: "#C026D3")
    public static let regalPurple        = Color.adaptive(darkHex: "#6C2EB9", lightHex: "#7C3AED")
    public static let bladeSilver        = Color.adaptive(darkHex: "#E2E8F0", lightHex: "#475569")

    public static let statusNormal       = accentPrimary
    public static let statusWarning      = Color(hex: "#F59E0B")
    public static let statusInverse      = Color(hex: "#E11D48")

    public static let textMuted          = textSecondary
}

// MARK: - Adaptive Color Helpers

public extension Color {
    static func adaptive(darkHex: String, lightHex: String) -> Color {
        #if canImport(UIKit)
        return Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(Color(hex: darkHex)) : UIColor(Color(hex: lightHex))
        })
        #else
        return Color(hex: darkHex)
        #endif
    }

    static func adaptive(dark: Color, light: Color) -> Color {
        #if canImport(UIKit)
        return Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #else
        return dark
        #endif
    }

    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var int: UInt64 = 0
        scanner.scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted).count {
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
