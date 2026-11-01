//
//  UserSettings.swift
//  KinakoApp
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

import Foundation
import SwiftData

@Model
final class UserSettings {
    var id: UUID = UUID()
    var homeCurrencyCode: String = "IDR"
    var activeDisplayCurrencyCode: String = "IDR"
    var monthlyBudgetCap: Decimal = 0
    var effectiveHourlyWage: Decimal? = nil  // For Time-Cost calculation
    var enableRegretAuditNotifications: Bool = true

    init(
        homeCurrencyCode: String = "IDR",
        activeDisplayCurrencyCode: String = "IDR",
        monthlyBudgetCap: Decimal = 0,
        effectiveHourlyWage: Decimal? = nil,
        enableRegretAuditNotifications: Bool = true
    ) {
        self.id = UUID()
        self.homeCurrencyCode = homeCurrencyCode.uppercased()
        self.activeDisplayCurrencyCode = activeDisplayCurrencyCode.uppercased()
        self.monthlyBudgetCap = monthlyBudgetCap
        self.effectiveHourlyWage = effectiveHourlyWage
        self.enableRegretAuditNotifications = enableRegretAuditNotifications
    }
}

