# Testing & Quality Assurance Architecture

## 1. Testing Framework Standards
- **Primary Harness:** Modern **Swift Testing** (`import Testing`, using `@Suite`, `@Test`, `#expect`, and `#require`).
- **Legacy / Fallback Harness:** **XCTest** (`import XCTest`, `XCTestCase`) for UI Automation and existing legacy test runners.
- **Strict Isolation:** Unit tests must never interact with the production CloudKit database, network endpoints, or disk-persisted stores. All tests run in isolated in-memory SwiftData containers.

---

## 2. In-Memory SwiftData Test Harness

Use this factory to instantiate completely isolated SwiftData contexts for tests:

```swift
import SwiftData
import Foundation
@testable import KinakoApp

@MainActor
public struct TestModelContainerFactory {
    public static func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            Transaction.self,
            CurrencyRateRecord.self,
            UserSettings.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )

        return try ModelContainer(for: schema, configurations: [configuration])
    }
}


3. Unit Test Suites

Suite A: Currency Engine & Offline Conversion

Tests offline lookups, triangle conversions, and rate freezing immutability.

import Testing
import Foundation
import SwiftData
@testable import KinakoApp

@Suite("Currency Engine Tests")
struct CurrencyEngineTests {

    @Test("Offline rate conversion calculation")
    @MainActor
    func testDirectConversion() throws {
        let container = try TestModelContainerFactory.makeContainer()
        let context = container.mainContext

        // Seed test rate: 1 USD = 16,000 IDR
        let rateRecord = CurrencyRateRecord(baseCurrency: "USD", targetCurrency: "IDR", rate: 16000)
        context.insert(rateRecord)
        try context.save()

        let service = ExchangeRateService.shared
        let result = await service.convert(amount: 50, from: "USD", to: "IDR", in: context)

        #expect(result.convertedAmount == 800000)
        #expect(result.rateUsed == 16000)
    }

    @Test("Identity conversion returns same amount")
    @MainActor
    func testIdentityConversion() async throws {
        let container = try TestModelContainerFactory.makeContainer()
        let service = ExchangeRateService.shared

        let result = await service.convert(amount: 100, from: "IDR", to: "IDR", in: container.mainContext)
        #expect(result.convertedAmount == 100)
        #expect(result.rateUsed == 1)
    }
}


Suite B: Buffer Pacing Engine

Validates safe-to-spend adjustments across billing cycles and division safety.

import Testing
import Foundation
@testable import KinakoApp

@Suite("Pacing Engine Tests")
struct PacingEngineTests {

    @Test("Safe daily calculation under normal spending")
    func testSafeDailyNormal() {
        // Cap: $600, Spent: $100, Days remaining: 10
        // Expected remaining: $500, Safe daily: $50
        let result = PacingEngine.calculateSafeDaily(
            monthlyCap: 600,
            totalSpentThisMonth: 100,
            daysRemainingInMonth: 10
        )

        #expect(result.remainingBudget == 500)
        #expect(result.safeDaily == 50)
    }

    @Test("Zero days remaining safety fallback")
    func testZeroDaysFallback() {
        let result = PacingEngine.calculateSafeDaily(
            monthlyCap: 300,
            totalSpentThisMonth: 150,
            daysRemainingInMonth: 0
        )

        #expect(result.remainingBudget == 150)
        #expect(result.safeDaily == 150) // Should default to dividing by at least 1 day
    }

    @Test("Deficit spending produces zero safe daily")
    func testDeficitHandling() {
        let result = PacingEngine.calculateSafeDaily(
            monthlyCap: 300,
            totalSpentThisMonth: 450,
            daysRemainingInMonth: 5
        )

        #expect(result.remainingBudget == -150)
        #expect(result.safeDaily == 0)
    }
}


Suite C: Ghost Split Accounting

Validates that split expenses do not corrupt the personal budget category.

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

        #require(records.count == 1)
        let saved = records[0]
        #expect(saved.originalAmount == 120)
        #expect(saved.myShareAmount == 30)
        #expect(saved.pendingReimbursement == 90)
        #expect(saved.isReimbursed == false)
    }
}


Suite D: Time-Cost Equivalency

Tests hour, minute, and workday formatting strings.

import Testing
import Foundation
@testable import KinakoApp

@Suite("Time-Cost Equivalency Tests")
struct TimeCostTests {

    @Test("Under 1 hour formats as minutes")
    func testMinutesFormatting() {
        // Wage: $30/hr, Amount: $15 -> 0.5 hr = 30m
        let result = TimeCostCalculator.formatEquivalentTime(amount: 15, hourlyWage: 30)
        #expect(result == "≈ 30m of work")
    }

    @Test("Between 1 and 8 hours formats as hours and minutes")
    func testHoursAndMinutesFormatting() {
        // Wage: $20/hr, Amount: $50 -> 2.5 hrs = 2h 30m
        let result = TimeCostCalculator.formatEquivalentTime(amount: 50, hourlyWage: 20)
        #expect(result == "≈ 2h 30m of work")
    }

    @Test("Over 8 hours formats as working days")
    func testWorkDaysFormatting() {
        // Wage: $25/hr, Amount: $400 -> 16 hrs / 8 = 2.0 work days
        let result = TimeCostCalculator.formatEquivalentTime(amount: 400, hourlyWage: 25)
        #expect(result == "≈ 2.0 work days")
    }

    @Test("Nil or zero wage returns nil")
    func testNilWageSafety() {
        #expect(TimeCostCalculator.formatEquivalentTime(amount: 100, hourlyWage: nil) == nil)
        #expect(TimeCostCalculator.formatEquivalentTime(amount: 100, hourlyWage: 0) == nil)
    }
}


4. UI Automation (XCTest) Target Protocols

For KinakoAppUITests:

1. Accessibility Identifiers:
  ⚬ Hero balance display: accessibilityIdentifier = "hero_balance_text"
  ⚬ Expense entry numpad key: accessibilityIdentifier = "numpad_key_\(digit)"
  ⚬ Currency selector button: accessibilityIdentifier = "currency_selector_menu"
  ⚬ Transaction commit button: accessibilityIdentifier = "btn_commit_transaction"
2. Launch Arguments:
   Pass -ui_testing_mode in launch arguments to automatically bypass onboarding and load mocked in-memory SwiftData seed data.
