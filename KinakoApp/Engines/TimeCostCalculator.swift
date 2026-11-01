//
//  TimeCostCalculator.swift
//  KinakoApp
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

import Foundation

public struct TimeCostCalculator {
    /// Formats an expense amount into working-time equivalency based on net hourly wage
    public static func formatEquivalentTime(amount: Decimal, hourlyWage: Decimal?) -> String? {
        guard let wage = hourlyWage, wage > 0, amount > 0 else { return nil }

        let totalHours = (amount as NSDecimalNumber).doubleValue / (wage as NSDecimalNumber).doubleValue

        if totalHours < 1.0 {
            let minutes = Int(round(totalHours * 60))
            return "≈ \(minutes)m of work"
        } else if totalHours < 8.0 {
            let hours = Int(totalHours)
            let minutes = Int(round((totalHours - Double(hours)) * 60))
            return minutes > 0 ? "≈ \(hours)h \(minutes)m of work" : "≈ \(hours)h of work"
        } else {
            let days = totalHours / 8.0
            return String(format: "≈ %.1f work days", days)
        }
    }
}

