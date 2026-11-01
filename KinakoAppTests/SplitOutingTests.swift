//
//  SplitOutingTests.swift
//  KinakoAppTests
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

import Testing
import Foundation
import SwiftData
@testable import KinakoApp

@Suite("Split Outing Tests")
struct SplitOutingTests {

    @Test("Split expense records full charge but only impacts budget by user share")
    @MainActor
    func testSplitExpenseIntegrity() throws {
        let container = try TestModelContainerFactory.makeContainer()
        let context = container.mainContext

        let splitTx = Transaction(
            title: "Dinner with Team",
            categoryId: "dining",
            originalAmount: 120,
            originalCurrencyCode: "USD",
            baseAmount: 120,
            baseCurrencyCode: "USD",
            exchangeRateUsed: 1,
            isSplitExpense: true,
            myShareAmount: 30,
            pendingReimbursement: 90
        )

        context.insert(splitTx)
        try context.save()

        let fetchDescriptor = FetchDescriptor<Transaction>()
        let records = try context.fetch(fetchDescriptor)

        try #require(records.count == 1)
        let saved = records[0]
        #expect(saved.originalAmount == 120)
        #expect(saved.myShareAmount == 30)
        #expect(saved.pendingReimbursement == 90)
        #expect(saved.isReimbursed == false)

        // Verify GhostSplitManager logic
        let personalCost = GhostSplitManager.personalCost(for: saved)
        #expect(personalCost == 30)

        // Settle reimbursement
        GhostSplitManager.settleReimbursement(for: saved)
        #expect(saved.isReimbursed == true)
    }

    @Test("GhostSplitManager calculation produces correct pending reimbursement")
    func testGhostSplitCalculation() {
        let (pending, isValid) = GhostSplitManager.calculateSplit(totalAmount: 150, myShare: 50)
        #expect(pending == 100)
        #expect(isValid == true)

        let (invalidPending, isInvalid) = GhostSplitManager.calculateSplit(totalAmount: 50, myShare: 80)
        #expect(isInvalid == false)
        #expect(invalidPending == 0)
    }

    @Test("Non-split transaction personalCost returns baseAmount")
    func testNonSplitPersonalCost() {
        let regularTx = Transaction(
            title: "Groceries",
            originalAmount: 75,
            originalCurrencyCode: "USD",
            baseAmount: 75,
            baseCurrencyCode: "USD",
            exchangeRateUsed: 1,
            isSplitExpense: false
        )
        let cost = GhostSplitManager.personalCost(for: regularTx)
        #expect(cost == 75)
    }
}

