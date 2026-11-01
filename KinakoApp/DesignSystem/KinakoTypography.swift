//
//  KinakoTypography.swift
//  KinakoApp
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

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

