//
//  ExchangeRateService.swift
//  KinakoApp
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

import Foundation
import SwiftData

actor ExchangeRateService {
    static let shared = ExchangeRateService()

    private init() {}

    /// Seeds initial exchange rates from rates_seed.json if the database is currently empty
    @discardableResult
    func seedInitialRatesIfNeeded(in context: ModelContext) throws -> Bool {
        let descriptor = FetchDescriptor<CurrencyRateRecord>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return false }

        guard let seedURL = findSeedURL() else {
            return false
        }

        let data = try Data(contentsOf: seedURL)
        let decoder = JSONDecoder()
        let payload = try decoder.decode(SeedPayload.self, from: data)

        let formatter = ISO8601DateFormatter()
        let lastUpdated = formatter.date(from: payload.updated_at) ?? Date.now

        for (target, rateDouble) in payload.rates {
            let record = CurrencyRateRecord(
                baseCurrency: payload.base,
                targetCurrency: target,
                rate: Decimal(rateDouble),
                lastUpdated: lastUpdated
            )
            context.insert(record)
        }

        try context.save()
        return true
    }

    /// Converts an amount from source to target currency using cached/seed rates
    func convert(
        amount: Decimal,
        from source: String,
        to target: String,
        in context: ModelContext
    ) -> (convertedAmount: Decimal, rateUsed: Decimal) {
        let src = source.uppercased()
        let tgt = target.uppercased()

        if src == tgt {
            return (amount, 1)
        }

        // 1. Direct Pair (A -> B)
        let directKey = "\(src)_\(tgt)"
        let directDescriptor = FetchDescriptor<CurrencyRateRecord>(predicate: #Predicate { $0.pairKey == directKey })
        if let direct = try? context.fetch(directDescriptor).first {
            return (amount * direct.rate, direct.rate)
        }

        // 2. Inverted Pair (B -> A)
        let invertedKey = "\(tgt)_\(src)"
        let invertedDescriptor = FetchDescriptor<CurrencyRateRecord>(predicate: #Predicate { $0.pairKey == invertedKey })
        if let inverted = try? context.fetch(invertedDescriptor).first, inverted.rate != 0 {
            let invertedRate = 1 / inverted.rate
            return (amount / inverted.rate, invertedRate)
        }

        // 3. Cross-currency triangle via USD bridge
        if let triangleUSD = triangleConvert(amount: amount, from: src, to: tgt, via: "USD", in: context) {
            return triangleUSD
        }

        // Fallback cross-currency triangle via EUR bridge
        if let triangleEUR = triangleConvert(amount: amount, from: src, to: tgt, via: "EUR", in: context) {
            return triangleEUR
        }

        // Fallback to identity if rate missing offline
        return (amount, 1)
    }

    private func triangleConvert(
        amount: Decimal,
        from source: String,
        to target: String,
        via bridge: String,
        in context: ModelContext
    ) -> (convertedAmount: Decimal, rateUsed: Decimal)? {
        guard let relSource = bridgeRelation(for: source, bridge: bridge, in: context),
              let relTarget = bridgeRelation(for: target, bridge: bridge, in: context) else {
            return nil
        }

        switch (relSource, relTarget) {
        case (.inverted(let rSource), .inverted(let rTarget)):
            // Both quoted as bridge -> currency (e.g. USD -> JPY and USD -> IDR)
            guard rSource != 0 else { return nil }
            let rate = rTarget / rSource
            let converted = (amount * rTarget) / rSource
            return (converted, rate)

        case (.direct(let rSource), .inverted(let rTarget)):
            // Source is source -> bridge, Target is bridge -> target
            let rate = rSource * rTarget
            let converted = amount * rate
            return (converted, rate)

        case (.direct(let rSource), .direct(let rTarget)):
            // Both are currency -> bridge
            guard rTarget != 0 else { return nil }
            let rate = rSource / rTarget
            let converted = (amount * rSource) / rTarget
            return (converted, rate)

        case (.inverted(let rSource), .direct(let rTarget)):
            // Source is bridge -> source, Target is target -> bridge
            let denom = rSource * rTarget
            guard denom != 0 else { return nil }
            let rate = 1 / denom
            let converted = amount / denom
            return (converted, rate)
        }
    }

    private enum BridgeRelation {
        case direct(Decimal)    // currency -> bridge rate
        case inverted(Decimal)  // bridge -> currency rate
    }

    private func bridgeRelation(for currency: String, bridge: String, in context: ModelContext) -> BridgeRelation? {
        let curr = currency.uppercased()
        let brg = bridge.uppercased()

        if curr == brg {
            return .direct(1)
        }

        let directKey = "\(curr)_\(brg)"
        let directDescriptor = FetchDescriptor<CurrencyRateRecord>(predicate: #Predicate { $0.pairKey == directKey })
        if let direct = try? context.fetch(directDescriptor).first {
            return .direct(direct.rate)
        }

        let invertedKey = "\(brg)_\(curr)"
        let invertedDescriptor = FetchDescriptor<CurrencyRateRecord>(predicate: #Predicate { $0.pairKey == invertedKey })
        if let inverted = try? context.fetch(invertedDescriptor).first, inverted.rate != 0 {
            return .inverted(inverted.rate)
        }

        return nil
    }

    private func findSeedURL() -> URL? {
        if let url = Bundle.main.url(forResource: "rates_seed", withExtension: "json") {
            return url
        }
        for bundle in Bundle.allBundles {
            if let url = bundle.url(forResource: "rates_seed", withExtension: "json") {
                return url
            }
        }
        return nil
    }
}

private nonisolated struct SeedPayload: Decodable, Sendable {
    let base: String
    let updated_at: String
    let rates: [String: Double]
}
