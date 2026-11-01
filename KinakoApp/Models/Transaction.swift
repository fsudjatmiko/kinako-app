//
//  Transaction.swift
//  KinakoApp
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID = UUID()
    var title: String = ""
    var note: String? = nil
    var timestamp: Date = Date.now
    var categoryId: String = "general"

    // Original transaction value as entered by the user
    var originalAmount: Decimal = 0
    var originalCurrencyCode: String = "IDR"

    // Converted value based on user's active home currency at entry time
    var baseAmount: Decimal = 0
    var baseCurrencyCode: String = "IDR"
    var exchangeRateUsed: Decimal = 1

    // Split Expense / Group Outing Fields
    var isSplitExpense: Bool = false
    var myShareAmount: Decimal? = nil       // The portion that actually counts against the user's budget
    var pendingReimbursement: Decimal? = nil // Amount owed by others
    var isReimbursed: Bool = false

    // Post-Purchase Regret Audit
    var satisfactionRating: Int? = nil       // 1 (Regret) to 5 (Worth it)
    var auditedAt: Date? = nil
    var auditPromptDate: Date? = nil         // Scheduled prompt date (e.g. timestamp + 14/30 days)

    init(
        title: String = "",
        note: String? = nil,
        timestamp: Date = .now,
        categoryId: String = "general",
        originalAmount: Decimal = 0,
        originalCurrencyCode: String = "IDR",
        baseAmount: Decimal = 0,
        baseCurrencyCode: String = "IDR",
        exchangeRateUsed: Decimal = 1,
        isSplitExpense: Bool = false,
        myShareAmount: Decimal? = nil,
        pendingReimbursement: Decimal? = nil,
        auditPromptDate: Date? = nil,
        isReimbursed: Bool = false,
        satisfactionRating: Int? = nil,
        auditedAt: Date? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.note = note
        self.timestamp = timestamp
        self.categoryId = categoryId
        self.originalAmount = originalAmount
        self.originalCurrencyCode = originalCurrencyCode.uppercased()
        self.baseAmount = baseAmount
        self.baseCurrencyCode = baseCurrencyCode.uppercased()
        self.exchangeRateUsed = exchangeRateUsed
        self.isSplitExpense = isSplitExpense
        self.myShareAmount = myShareAmount
        self.pendingReimbursement = pendingReimbursement
        self.isReimbursed = isReimbursed
        self.satisfactionRating = satisfactionRating
        self.auditedAt = auditedAt
        self.auditPromptDate = auditPromptDate
    }
}

