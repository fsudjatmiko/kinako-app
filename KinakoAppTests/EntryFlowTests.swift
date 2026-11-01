//
//  EntryFlowTests.swift
//  KinakoAppTests
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

import Testing
import Foundation
import SwiftData
@testable import KinakoApp

@Suite("Entry Flow Integration Tests")
struct EntryFlowTests {

    @Test("End-to-end multi-currency expense entry flow")
    @MainActor
    func testMultiCurrencyExpenseEntry() async throws {
        let container = try TestModelContainerFactory.makeContainer()
        let context = container.mainContext

        // 1. Seed initial rates
        let service = ExchangeRateService.shared
        try await service.seedInitialRatesIfNeeded(in: context)

        // 2. Set user settings (Home: IDR, Hourly wage: 50,000 IDR)
        let settings = UserSettings(
            homeCurrencyCode: "IDR",
            activeDisplayCurrencyCode: "IDR",
            monthlyBudgetCap: 5000000,
            effectiveHourlyWage: 50000
        )
        context.insert(settings)
        try context.save()

        // 3. User enters 1,200 JPY dining expense
        let conversion = await service.convert(amount: 1200, from: "JPY", to: "IDR", in: context)
        #expect(conversion.convertedAmount > 0)

        // Time cost equivalency
        let timeCost = TimeCostCalculator.formatEquivalentTime(
            amount: conversion.convertedAmount,
            hourlyWage: settings.effectiveHourlyWage
        )
        #expect(timeCost != nil)

        // 4. Create and persist Transaction
        let tx = Transaction(
            title: "Tokyo Ramen",
            categoryId: "dining",
            originalAmount: 1200,
            originalCurrencyCode: "JPY",
            baseAmount: conversion.convertedAmount,
            baseCurrencyCode: "IDR",
            exchangeRateUsed: conversion.rateUsed,
            isSplitExpense: false
        )
        context.insert(tx)
        try context.save()

        // 5. Query and verify persistence
        let descriptor = FetchDescriptor<Transaction>()
        let records = try context.fetch(descriptor)
        try #require(records.count == 1)

        let saved = records[0]
        #expect(saved.title == "Tokyo Ramen")
        #expect(saved.originalAmount == 1200)
        #expect(saved.originalCurrencyCode == "JPY")
        #expect(saved.baseCurrencyCode == "IDR")
        #expect(abs(saved.baseAmount - conversion.convertedAmount) < 0.01)
    }

    @Test("End-to-end split outing entry and settlement")
    @MainActor
    func testSplitOutingEntryFlow() async throws {
        let container = try TestModelContainerFactory.makeContainer()
        let context = container.mainContext

        // Total bill: $150 USD, Personal share: $50 USD
        let totalAmount: Decimal = 150
        let myShare: Decimal = 50
        let (pending, isValid) = GhostSplitManager.calculateSplit(totalAmount: totalAmount, myShare: myShare)
        #expect(isValid == true)
        #expect(pending == 100)

        let splitTx = Transaction(
            title: "Team Hotpot",
            categoryId: "dining",
            originalAmount: totalAmount,
            originalCurrencyCode: "USD",
            baseAmount: totalAmount * 16150,
            baseCurrencyCode: "IDR",
            exchangeRateUsed: 16150,
            isSplitExpense: true,
            myShareAmount: myShare * 16150,
            pendingReimbursement: pending,
            isReimbursed: false
        )
        context.insert(splitTx)
        try context.save()

        // Verify budget impact is only personal share
        let budgetImpact = GhostSplitManager.personalCost(for: splitTx)
        #expect(budgetImpact == myShare * 16150)

        // Settle the receivable
        GhostSplitManager.settleReimbursement(for: splitTx)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Transaction>())
        try #require(fetched.count == 1)
        #expect(fetched[0].isReimbursed == true)
    }
}

