//
//  KinakoTypography.swift
//  KinakoApp
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

import SwiftUI

public extension Font {
    /// Internal Helvetica resolution helper
    static func helvetica(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold, .heavy, .black, .semibold:
            return .custom("Helvetica-Bold", size: size)
        case .light, .ultraLight, .thin:
            return .custom("Helvetica-Light", size: size)
        default:
            return .custom("Helvetica", size: size)
        }
    }

    /// Titles, Hero Banners, and Section Headers
    static func helveticaTitle(size: CGFloat = 24, weight: Font.Weight = .bold) -> Font {
        helvetica(size: size, weight: weight)
    }

    /// Standard Body Copy, Descriptive Text, and Form Labels
    static func helveticaBody(size: CGFloat = 15) -> Font {
        helvetica(size: size, weight: .regular)
    }

    /// Captions, Status Pills, and Secondary Metadata
    static func helveticaCaption(size: CGFloat = 12, weight: Font.Weight = .regular) -> Font {
        helvetica(size: size, weight: weight)
    }

    /// Financial Digits and Prominent Numerical Values
    static func helveticaNumbers(size: CGFloat = 20, weight: Font.Weight = .bold) -> Font {
        helvetica(size: size, weight: weight)
    }

    // MARK: - Semantic Design Tokens (Mapping cleanly to Helvetica)

    /// Hero Currency & Grand Balance Amounts
    static let kinakoHeroBalance = helvetica(size: 38, weight: .bold)

    /// Secondary Transaction Amounts & Safe-to-Spend Totals
    static let kinakoCardAmount = helveticaNumbers(size: 20, weight: .bold)

    /// Telemetry Readouts, Currency Badges, and Exchange Rates (Clean Non-Monospaced Helvetica)
    static let kinakoTelemetry = helveticaCaption(size: 11, weight: .bold)

    /// Standard List Row Titles and HIG Form Labels
    static let kinakoBody = helveticaBody(size: 15)

    /// Section Subheaders with High Tracking
    static let kinakoSectionHeader = helveticaTitle(size: 12, weight: .bold)
}
