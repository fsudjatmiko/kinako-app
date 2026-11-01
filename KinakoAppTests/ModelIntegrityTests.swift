//
//  ModelIntegrityTests.swift
//  KinakoAppTests
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

import Testing
import Foundation
import SwiftData
@testable import KinakoApp

@Suite("SwiftData Model Integrity Tests")
struct ModelIntegrityTests {

    // MARK: - Transaction Tests

    @Test("Transaction instantiation with default values")
    @MainActor
    func testTransactionDefaultValues() {
        let beforeInit = Date.now.addingTimeInterval(-1)
        let tx = Transaction()
        let afterInit = Date.now.addingTimeInterval(1)

        #expect(tx.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
        #expect(tx.title == "")
        #expect(tx.note == nil)
        #expect(tx.timestamp >= beforeInit && tx.timestamp <= afterInit)
        #expect(tx.categoryId == "general")
        #expect(tx.originalAmount == 0)
        #expect(tx.originalCurrencyCode == "IDR")
        #expect(tx.baseAmount == 0)
        #expect(tx.baseCurrencyCode == "IDR")
        #expect(tx.exchangeRateUsed == 1)
        #expect(tx.isSplitExpense == false)
        #expect(tx.myShareAmount == nil)
        #expect(tx.pendingReimbursement == nil)
        #expect(tx.isReimbursed == false)
        #expect(tx.satisfactionRating == nil)
        #expect(tx.auditedAt == nil)
        #expect(tx.auditPromptDate == nil)
    }

    @Test("Transaction custom values uppercase currency codes")
    @MainActor
    func testTransactionCustomValuesAndCasing() {
        let fixedDate = Date(timeIntervalSince1970: 1700000000)
        let auditDate = Date(timeIntervalSince1970: 1702592000)

        let tx = Transaction(
            title: "Tokyo Ramen",
            note: "Shinjuku branch",
            timestamp: fixedDate,
            categoryId: "dining",
            originalAmount: 1200,
            originalCurrencyCode: "jpy",
            baseAmount: 125000,
            baseCurrencyCode: "idr",
            exchangeRateUsed: 104.16,
            isSplitExpense: true,
            myShareAmount: 600,
            pendingReimbursement: 600,
            auditPromptDate: auditDate,
            isReimbursed: false,
            satisfactionRating: 5,
            auditedAt: nil
        )

        #expect(tx.title == "Tokyo Ramen")
        #expect(tx.note == "Shinjuku branch")
        #expect(tx.timestamp == fixedDate)
        #expect(tx.categoryId == "dining")
        #expect(tx.originalAmount == 1200)
        #expect(tx.originalCurrencyCode == "JPY")
        #expect(tx.baseAmount == 125000)
        #expect(tx.baseCurrencyCode == "IDR")
        #expect(tx.exchangeRateUsed == 104.16)
        #expect(tx.isSplitExpense == true)
        #expect(tx.myShareAmount == 600)
        #expect(tx.pendingReimbursement == 600)
        #expect(tx.auditPromptDate == auditDate)
        #expect(tx.isReimbursed == false)
        #expect(tx.satisfactionRating == 5)
        #expect(tx.auditedAt == nil)
    }

    @Test("Transaction persistence and query in SwiftData context")
    @MainActor
    func testTransactionPersistence() throws {
        let container = try TestModelContainerFactory.makeContainer()
        let context = container.mainContext

        let tx = Transaction(
            title: "Flight Ticket",
            note: "One-way",
            originalAmount: 350,
            originalCurrencyCode: "usd",
            baseAmount: 5600000,
            baseCurrencyCode: "idr",
            exchangeRateUsed: 16000,
            isSplitExpense: false
        )

        context.insert(tx)
        try context.save()

        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.title == "Flight Ticket" }
        )
        let fetched = try context.fetch(descriptor)

        try #require(fetched.count == 1)
        let saved = fetched[0]
        #expect(saved.title == "Flight Ticket")
        #expect(saved.note == "One-way")
        #expect(saved.originalAmount == 350)
        #expect(saved.originalCurrencyCode == "USD")
        #expect(saved.baseAmount == 5600000)
        #expect(saved.baseCurrencyCode == "IDR")
        #expect(saved.exchangeRateUsed == 16000)
        #expect(saved.isSplitExpense == false)
        #expect(saved.myShareAmount == nil)
        #expect(saved.pendingReimbursement == nil)
        #expect(saved.isReimbursed == false)
        #expect(saved.satisfactionRating == nil)

        // Test mutating and saving
        saved.satisfactionRating = 4
        saved.auditedAt = Date.now
        saved.isReimbursed = true
        try context.save()

        let refetched = try context.fetch(descriptor)
        try #require(refetched.count == 1)
        #expect(refetched[0].satisfactionRating == 4)
        #expect(refetched[0].auditedAt != nil)
        #expect(refetched[0].isReimbursed == true)

        // Test deletion
        context.delete(refetched[0])
        try context.save()

        let remaining = try context.fetch(descriptor)
        #expect(remaining.isEmpty)
    }

    // MARK: - CurrencyRateRecord Tests

    @Test("CurrencyRateRecord instantiation with default values")
    @MainActor
    func testCurrencyRateRecordDefaultValues() {
        let beforeInit = Date.now.addingTimeInterval(-1)
        let record = CurrencyRateRecord()
        let afterInit = Date.now.addingTimeInterval(1)

        #expect(record.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
        #expect(record.baseCurrency == "USD")
        #expect(record.targetCurrency == "IDR")
        #expect(record.pairKey == "USD_IDR")
        #expect(record.rate == 1)
        #expect(record.lastUpdated >= beforeInit && record.lastUpdated <= afterInit)
    }

    @Test("CurrencyRateRecord custom values format pairKey with uppercase")
    @MainActor
    func testCurrencyRateRecordCustomValues() {
        let record = CurrencyRateRecord(
            baseCurrency: "eur",
            targetCurrency: "jpy",
            rate: 165.25
        )

        #expect(record.baseCurrency == "EUR")
        #expect(record.targetCurrency == "JPY")
        #expect(record.pairKey == "EUR_JPY")
        #expect(record.rate == 165.25)
    }

    @Test("CurrencyRateRecord persistence and query in SwiftData context")
    @MainActor
    func testCurrencyRateRecordPersistence() throws {
        let container = try TestModelContainerFactory.makeContainer()
        let context = container.mainContext

        let record = CurrencyRateRecord(
            baseCurrency: "USD",
            targetCurrency: "JPY",
            rate: 155.50
        )

        context.insert(record)
        try context.save()

        let descriptor = FetchDescriptor<CurrencyRateRecord>(
            predicate: #Predicate { $0.pairKey == "USD_JPY" }
        )
        let fetched = try context.fetch(descriptor)

        try #require(fetched.count == 1)
        let saved = fetched[0]
        #expect(saved.baseCurrency == "USD")
        #expect(saved.targetCurrency == "JPY")
        #expect(saved.rate == 155.50)
        #expect(saved.pairKey == "USD_JPY")

        // Update rate
        saved.rate = 156.00
        saved.lastUpdated = Date.now
        try context.save()

        let updated = try context.fetch(descriptor)
        try #require(updated.count == 1)
        #expect(updated[0].rate == 156.00)
    }

    // MARK: - UserSettings Tests

    @Test("UserSettings instantiation with default values")
    @MainActor
    func testUserSettingsDefaultValues() {
        let settings = UserSettings()

        #expect(settings.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
        #expect(settings.homeCurrencyCode == "IDR")
        #expect(settings.activeDisplayCurrencyCode == "IDR")
        #expect(settings.monthlyBudgetCap == 0)
        #expect(settings.effectiveHourlyWage == nil)
        #expect(settings.enableRegretAuditNotifications == true)
    }

    @Test("UserSettings custom values uppercase currency codes")
    @MainActor
    func testUserSettingsCustomValues() {
        let settings = UserSettings(
            homeCurrencyCode: "usd",
            activeDisplayCurrencyCode: "eur",
            monthlyBudgetCap: 3000,
            effectiveHourlyWage: 25.50,
            enableRegretAuditNotifications: false
        )

        #expect(settings.homeCurrencyCode == "USD")
        #expect(settings.activeDisplayCurrencyCode == "EUR")
        #expect(settings.monthlyBudgetCap == 3000)
        #expect(settings.effectiveHourlyWage == 25.50)
        #expect(settings.enableRegretAuditNotifications == false)
    }

    @Test("UserSettings persistence and update in SwiftData context")
    @MainActor
    func testUserSettingsPersistence() throws {
        let container = try TestModelContainerFactory.makeContainer()
        let context = container.mainContext

        let settings = UserSettings(
            homeCurrencyCode: "USD",
            activeDisplayCurrencyCode: "USD",
            monthlyBudgetCap: 2500,
            effectiveHourlyWage: 20
        )

        context.insert(settings)
        try context.save()

        let descriptor = FetchDescriptor<UserSettings>()
        let fetched = try context.fetch(descriptor)

        try #require(fetched.count == 1)
        let saved = fetched[0]
        #expect(saved.homeCurrencyCode == "USD")
        #expect(saved.monthlyBudgetCap == 2500)
        #expect(saved.effectiveHourlyWage == 20)
        #expect(saved.enableRegretAuditNotifications == true)

        // Mutate and save
        saved.monthlyBudgetCap = 3000
        saved.effectiveHourlyWage = 30
        try context.save()

        let refetched = try context.fetch(descriptor)
        try #require(refetched.count == 1)
        #expect(refetched[0].monthlyBudgetCap == 3000)
        #expect(refetched[0].effectiveHourlyWage == 30)
    }

    // MARK: - CloudKit Compatibility & Multi-Model Integration

    @Test("All models can coexist and persist together without CloudKit violations")
    @MainActor
    func testAllModelsIntegration() throws {
        let container = try TestModelContainerFactory.makeContainer()
        let context = container.mainContext

        let tx = Transaction(
            title: "Coffee",
            originalAmount: 5,
            originalCurrencyCode: "USD",
            baseAmount: 80000,
            baseCurrencyCode: "IDR",
            exchangeRateUsed: 16000
        )
        let rate = CurrencyRateRecord(baseCurrency: "USD", targetCurrency: "IDR", rate: 16000)
        let settings = UserSettings(homeCurrencyCode: "IDR", monthlyBudgetCap: 5000000)

        context.insert(tx)
        context.insert(rate)
        context.insert(settings)
        try context.save()

        let txCount = try context.fetchCount(FetchDescriptor<Transaction>())
        let rateCount = try context.fetchCount(FetchDescriptor<CurrencyRateRecord>())
        let settingsCount = try context.fetchCount(FetchDescriptor<UserSettings>())

        #expect(txCount == 1)
        #expect(rateCount == 1)
        #expect(settingsCount == 1)
    }
}
