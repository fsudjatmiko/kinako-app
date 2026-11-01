//
//  PacingEngineTests.swift
//  KinakoAppTests
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

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

    @Test("Budget state classification transitions")
    func testBudgetStateClassification() {
        // Stable: Remaining > 20% cap ($200 > $100), Today ($20) <= safeDaily ($50)
        let stable = PacingEngine.classifyBudgetState(
            monthlyCap: 500,
            remainingBudget: 200,
            safeDaily: 50,
            todaySpend: 20
        )
        #expect(stable == .stable)
        #expect(stable.statusCopy == "STABLE")

        // High Tension: Today spend exceeds safeDaily ($60 > $50)
        let overSpendToday = PacingEngine.classifyBudgetState(
            monthlyCap: 500,
            remainingBudget: 200,
            safeDaily: 50,
            todaySpend: 60
        )
        #expect(overSpendToday == .highTension)
        #expect(overSpendToday.statusCopy == "PRESSURE RISING")

        // High Tension: Remaining budget <= 20% cap ($90 <= $100)
        let lowRemaining = PacingEngine.classifyBudgetState(
            monthlyCap: 500,
            remainingBudget: 90,
            safeDaily: 50,
            todaySpend: 20
        )
        #expect(lowRemaining == .highTension)

        // Inversion Deficit: Remaining budget < 0
        let deficit = PacingEngine.classifyBudgetState(
            monthlyCap: 500,
            remainingBudget: -50,
            safeDaily: 0,
            todaySpend: 10
        )
        #expect(deficit == .inversionDeficit)
        #expect(deficit.statusCopy == "INVERSION // DEFICIT")
    }
}

