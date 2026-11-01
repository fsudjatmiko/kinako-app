//
//  KinakoColor.swift
//  KinakoApp
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

import SwiftUI

public enum KinakoColor {
    // Canvas & Structural Backgrounds
    public static let canvasMidnight      = Color(hex: "#0F071D") // Deep Astral Void
    public static let canvasCard          = Color(hex: "#180D2E") // Armored Slate Base
    public static let surfaceFrosted      = Color.white.opacity(0.04)

    // Astral Tohka Energy Trims
    public static let accentLavender      = Color(hex: "#B784F8") // Primary Aura / Reiryoku
    public static let accentMagenta       = Color(hex: "#E03BE5") // High-Tension Energy
    public static let regalPurple         = Color(hex: "#6C2EB9") // Deep Armor Joint Trims
    public static let bladeSilver         = Color(hex: "#E2E8F0") // Sandalphon Edge

    // Status & Feedback States
    public static let statusNormal        = Color(hex: "#B784F8") // Stable Safe-to-Spend
    public static let statusWarning       = Color(hex: "#F59E0B") // Budget Pressure Alert
    public static let statusInverse       = Color(hex: "#E11D48") // Tenka Dark Deficit

    // Text Hierarchy
    public static let textPrimary         = Color.white
    public static let textSecondary       = Color(hex: "#94A3B8")
    public static let textMuted           = Color(hex: "#64748B")
}

// Hex Color Initializer Extension
public extension Color {
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

