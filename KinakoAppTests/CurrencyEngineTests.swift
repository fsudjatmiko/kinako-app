//
//  CurrencyEngineTests.swift
//  KinakoAppTests
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

import Testing
import Foundation
import SwiftData
@testable import KinakoApp

@Suite("Currency Engine Tests")
struct CurrencyEngineTests {

    @Test("Offline rate conversion calculation")
    @MainActor
    func testDirectConversion() async throws {
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

    @Test("Inverted conversion calculation")
    @MainActor
    func testInvertedConversion() async throws {
        let container = try TestModelContainerFactory.makeContainer()
        let context = container.mainContext

        // 1 USD = 16,000 IDR
        let rateRecord = CurrencyRateRecord(baseCurrency: "USD", targetCurrency: "IDR", rate: 16000)
        context.insert(rateRecord)
        try context.save()

        let service = ExchangeRateService.shared
        // 160,000 IDR should be 10 USD
        let result = await service.convert(amount: 160000, from: "IDR", to: "USD", in: context)

        #expect(result.convertedAmount == 10)
        #expect(result.rateUsed == Decimal(1) / Decimal(16000))
    }

    @Test("Cross-currency triangle conversion via USD bridge")
    @MainActor
    func testTriangleConversion() async throws {
        let container = try TestModelContainerFactory.makeContainer()
        let context = container.mainContext

        // 1 USD = 150 JPY
        let jpyRate = CurrencyRateRecord(baseCurrency: "USD", targetCurrency: "JPY", rate: 150)
        // 1 USD = 15,000 IDR
        let idrRate = CurrencyRateRecord(baseCurrency: "USD", targetCurrency: "IDR", rate: 15000)
        context.insert(jpyRate)
        context.insert(idrRate)
        try context.save()

        let service = ExchangeRateService.shared
        // 1500 JPY to IDR: 1500 * (1/150) * 15000 = 10 * 15000 = 150,000 IDR
        let result = await service.convert(amount: 1500, from: "JPY", to: "IDR", in: context)

        #expect(result.convertedAmount == 150000)
        #expect(result.rateUsed == 100)
    }

    @Test("Seed file ingestion loads initial rates without duplicates")
    @MainActor
    func testSeedFileIngestion() async throws {
        let container = try TestModelContainerFactory.makeContainer()
        let context = container.mainContext

        let service = ExchangeRateService.shared
        let didSeed = try await service.seedInitialRatesIfNeeded(in: context)
        #expect(didSeed == true)

        let descriptor = FetchDescriptor<CurrencyRateRecord>()
        let count = try context.fetchCount(descriptor)
        #expect(count == 15)

        // Verify conversion using seeded rate (e.g., 1 USD to JPY = 153.2)
        let usdToJpy = await service.convert(amount: 10, from: "USD", to: "JPY", in: context)
        #expect(usdToJpy.convertedAmount == 1532)

        // Second call should skip seeding
        let didSeedAgain = try await service.seedInitialRatesIfNeeded(in: context)
        #expect(didSeedAgain == false)
        let countAfter = try context.fetchCount(descriptor)
        #expect(countAfter == 15)
    }

    @Test("Missing rate falls back to identity conversion")
    @MainActor
    func testMissingRateFallback() async throws {
        let container = try TestModelContainerFactory.makeContainer()
        let service = ExchangeRateService.shared

        let result = await service.convert(amount: 42, from: "ABC", to: "XYZ", in: container.mainContext)
        #expect(result.convertedAmount == 42)
        #expect(result.rateUsed == 1)
    }
}

