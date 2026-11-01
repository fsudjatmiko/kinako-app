//
//  CurrencyRateRecord.swift
//  KinakoApp
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

import Foundation
import SwiftData

@Model
final class CurrencyRateRecord {
    var id: UUID = UUID()
    var pairKey: String = ""            // e.g. "USD_IDR", "JPY_IDR"
    var baseCurrency: String = "USD"
    var targetCurrency: String = "IDR"
    var rate: Decimal = 1
    var lastUpdated: Date = Date.now

    init(
        baseCurrency: String = "USD",
        targetCurrency: String = "IDR",
        rate: Decimal = 1,
        lastUpdated: Date = .now
    ) {
        self.id = UUID()
        self.pairKey = "\(baseCurrency.uppercased())_\(targetCurrency.uppercased())"
        self.baseCurrency = baseCurrency.uppercased()
        self.targetCurrency = targetCurrency.uppercased()
        self.rate = rate
        self.lastUpdated = lastUpdated
    }
}

