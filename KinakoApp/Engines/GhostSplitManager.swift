//
//  GhostSplitManager.swift
//  KinakoApp
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

import Foundation
import SwiftData

struct GhostSplitManager {
    /// Computes pending reimbursement given total amount and user's share
    static func calculateSplit(
        totalAmount: Decimal,
        myShare: Decimal
    ) -> (pendingReimbursement: Decimal, isValid: Bool) {
        let pending = totalAmount - myShare
        let isValid = totalAmount > 0 && myShare >= 0 && pending >= 0
        return (max(0, pending), isValid)
    }

    /// Determines the personal cost impact of a transaction for personal budget calculations.
    /// If isSplitExpense is true and myShareAmount is provided, returns myShareAmount; otherwise returns baseAmount.
    static func personalCost(for transaction: Transaction) -> Decimal {
        if transaction.isSplitExpense, let share = transaction.myShareAmount {
            return share
        }
        return transaction.baseAmount
    }

    /// Marks a split transaction as fully reimbursed / settled
    static func settleReimbursement(for transaction: Transaction) {
        transaction.isReimbursed = true
    }
}
