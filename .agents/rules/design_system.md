# Design System & UI Tokens (Sandalphon Theme)

## 1. Aesthetic Philosophy
The visual core of Kinako unifies **Apple Human Interface Guidelines (HIG)** with **Anime GFX UI** elements derived from Yatogami Tohka (*Date A Live*):
- **Structure:** Clean, standard iOS navigation hierarchies, sheets, toolbars, and dynamic type support.
- **Atmosphere:** Deep astral violet canvases, frosted glass armor plating, dual-tone energetic neon strokes, and chamfered blade silhouettes.
- **Copy:** Professional, native terminology on functional controls (`Save`, `Cancel`, `Add Expense`, `Done`). Stylized anime accents are reserved strictly for ambient visual textures, metadata badges, and energy states.

---

## 2. Color Palette Tokens

```swift
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
extension Color {
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


3. Geometry: SandalphonChamfer

Replaces generic squircies on interactive cards, action sheets, and modal frames with 45-degree corner blade chamfers.

import SwiftUI

public struct SandalphonChamfer: Shape {
    public var cut: CGFloat

    public init(cut: CGFloat = 12) {
        self.cut = cut
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let c = min(cut, min(rect.width, rect.height) / 2)

        path.move(to: CGPoint(x: c, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX - c, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: c))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - c))
        path.addLine(to: CGPoint(x: rect.maxX - c, y: rect.maxY))
        path.addLine(to: CGPoint(x: c, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: rect.maxY - c))
        path.addLine(to: CGPoint(x: 0, y: c))
        path.closeSubpath()
        return path
    }
}


4. Astral Surface View Modifier

Applies the signature Tohka frosted armor surface, gradient edge stroke, and subtle ambient bloom.

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


5. Typography Hierarchy & Dynamic Type

All typography must preserve accessibility and Dynamic Type scaling via system font mappings:

import SwiftUI

public extension Font {
    /// Hero Currency & Grand Balance Amounts
    static let kinakoHeroBalance = Font.system(size: 38, weight: .heavy, design: .rounded)

    /// Secondary Transaction Amounts & Safe-to-Spend Totals
    static let kinakoCardAmount = Font.system(size: 20, weight: .bold, design: .rounded)

    /// Telemetry Readouts, Currency Badges, and Exchange Rates
    static let kinakoTelemetry = Font.system(.caption2, design: .monospaced, weight: .bold)

    /// Standard List Row Titles and HIG Form Labels
    static let kinakoBody = Font.system(.body, design: .default, weight: .semibold)

    /// Section Subheaders with High Tracking
    static let kinakoSectionHeader = Font.system(size: 11, weight: .black, design: .default)
}


6. Motion & Tactical Haptics

import SwiftUI

public extension Animation {
    /// Crisp, high-tension spring for sheets, cards, and numeric counter hops
    static let kinakoSnap = Animation.spring(response: 0.28, dampingFraction: 0.68, blendDuration: 0)

    /// Slash effect spring when completing a transaction or checking off an audit
    static let kinakoSlash = Animation.interpolatingSpring(mass: 0.4, stiffness: 220, damping: 14)
}

public enum KinakoHaptic {
    /// Standard keypress on numeric entry pad
    public static func keyPress() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.7)
    }

    /// Slash commit when logging a transaction
    public static func commit() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 1.0)
    }

    /// Deficit warning or budget breach
    public static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
