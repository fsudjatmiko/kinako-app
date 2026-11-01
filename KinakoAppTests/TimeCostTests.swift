//
//  TimeCostTests.swift
//  KinakoAppTests
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

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
        #expect(TimeCostCalculator.formatEquivalentTime(amount: 0, hourlyWage: 25) == nil)
    }
}

