//
//  PacingEngine.swift
//  KinakoApp
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

import SwiftUI
import Foundation

public nonisolated enum BudgetState: Equatable, Sendable {
    case stable
    case highTension
    case inversionDeficit

    public var statusCopy: String {
        switch self {
        case .stable:
            return "STABLE"
        case .highTension:
            return "PRESSURE RISING"
        case .inversionDeficit:
            return "INVERSION // DEFICIT"
        }
    }

    @MainActor
    public var accentColor: Color {
        switch self {
        case .stable:
            return KinakoColor.accentLavender
        case .highTension:
            return KinakoColor.statusWarning
        case .inversionDeficit:
            return KinakoColor.statusInverse
        }
    }
}

public nonisolated struct PacingEngine {
    /// Calculates safe daily allowance and remaining budget for the current cycle
    public static func calculateSafeDaily(
        monthlyCap: Decimal,
        totalSpentThisMonth: Decimal,
        daysRemainingInMonth: Int
    ) -> (safeDaily: Decimal, remainingBudget: Decimal) {
        let remaining = monthlyCap - totalSpentThisMonth
        let days = max(1, Decimal(daysRemainingInMonth))
        let safeDaily = max(0, remaining / days)
        return (safeDaily, remaining)
    }

    /// Classifies current budget tension into Stable, High Tension, or Inversion Deficit
    public static func classifyBudgetState(
        monthlyCap: Decimal,
        remainingBudget: Decimal,
        safeDaily: Decimal,
        todaySpend: Decimal
    ) -> BudgetState {
        if remainingBudget < 0 {
            return .inversionDeficit
        }
        if todaySpend > safeDaily || (monthlyCap > 0 && remainingBudget <= (monthlyCap * Decimal(0.20))) {
            return .highTension
        }
        return .stable
    }
}

