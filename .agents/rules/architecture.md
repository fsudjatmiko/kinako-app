# Architecture, SwiftData & Currency Engine

## 1. System Overview
- **Deployment Target:** iOS 26.0+
- **Language Mode:** Swift 6 (Strict Concurrency Enabled)
- **Data Layer:** SwiftData paired with CloudKit private database mirroring (`CKContainer(identifier: "iCloud.com.fsudjatmiko.KinakoApp")`).
- **Core Principle:** Offline-first architecture. All core features (logging, rate conversions, analytics) must execute without network connectivity.

---

## 2. CloudKit-Compatible SwiftData Schemas

To maintain sync integrity across devices via CloudKit:
1. Every attribute **must** have a default value or be declared optional (`?`).
2. **Never** use `@Attribute(.unique)`. Identifiers use standard `UUID()`.
3. All relationships must be optional.

### Model 1: `Transaction`
Represents an individual financial record. Original input amounts and converted equivalents are permanently captured upon creation.

```swift
import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID = UUID()
    var title: String = ""
    var note: String? = nil
    var timestamp: Date = Date.now
    var categoryId: String = "general"

    // Original transaction value as entered by the user
    var originalAmount: Decimal = 0
    var originalCurrencyCode: String = "IDR"

    // Converted value based on user's active home currency at entry time
    var baseAmount: Decimal = 0
    var baseCurrencyCode: String = "IDR"
    var exchangeRateUsed: Decimal = 1

    // Split Expense / Group Outing Fields
    var isSplitExpense: Bool = false
    var myShareAmount: Decimal? = nil       // The portion that actually counts against the user's budget
    var pendingReimbursement: Decimal? = nil // Amount owed by others
    var isReimbursed: Bool = false

    // Post-Purchase Regret Audit
    var satisfactionRating: Int? = nil       // 1 (Regret) to 5 (Worth it)
    var auditedAt: Date? = nil
    var auditPromptDate: Date? = nil         // Scheduled prompt date (e.g. timestamp + 14/30 days)

    init(
        title: String,
        note: String? = nil,
        timestamp: Date = .now,
        categoryId: String = "general",
        originalAmount: Decimal,
        originalCurrencyCode: String,
        baseAmount: Decimal,
        baseCurrencyCode: String,
        exchangeRateUsed: Decimal,
        isSplitExpense: Bool = false,
        myShareAmount: Decimal? = nil,
        pendingReimbursement: Decimal? = nil,
        auditPromptDate: Date? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.note = note
        self.timestamp = timestamp
        self.categoryId = categoryId
        self.originalAmount = originalAmount
        self.originalCurrencyCode = originalCurrencyCode.uppercased()
        self.baseAmount = baseAmount
        self.baseCurrencyCode = baseCurrencyCode.uppercased()
        self.exchangeRateUsed = exchangeRateUsed
        self.isSplitExpense = isSplitExpense
        self.myShareAmount = myShareAmount
        self.pendingReimbursement = pendingReimbursement
        self.isReimbursed = false
        self.satisfactionRating = nil
        self.auditedAt = nil
        self.auditPromptDate = auditPromptDate
    }
}


Model 2: CurrencyRateRecord

Locally caches exchange rate pairs.

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

    init(baseCurrency: String, targetCurrency: String, rate: Decimal, lastUpdated: Date = .now) {
        self.id = UUID()
        self.pairKey = "\(baseCurrency.uppercased())_\(targetCurrency.uppercased())"
        self.baseCurrency = baseCurrency.uppercased()
        self.targetCurrency = targetCurrency.uppercased()
        self.rate = rate
        self.lastUpdated = lastUpdated
    }
}


Model 3: UserSettings

Stores user preferences, budget caps, and effective hourly wage for time-cost calculations.

import Foundation
import SwiftData

@Model
final class UserSettings {
    var id: UUID = UUID()
    var homeCurrencyCode: String = "IDR"
    var activeDisplayCurrencyCode: String = "IDR"
    var monthlyBudgetCap: Decimal = 0
    var effectiveHourlyWage: Decimal? = nil  // For Time-Cost calculation
    var enableRegretAuditNotifications: Bool = true

    init(
        homeCurrencyCode: String = "IDR",
        activeDisplayCurrencyCode: String = "IDR",
        monthlyBudgetCap: Decimal = 0,
        effectiveHourlyWage: Decimal? = nil,
        enableRegretAuditNotifications: Bool = true
    ) {
        self.id = UUID()
        self.homeCurrencyCode = homeCurrencyCode.uppercased()
        self.activeDisplayCurrencyCode = activeDisplayCurrencyCode.uppercased()
        self.monthlyBudgetCap = monthlyBudgetCap
        self.effectiveHourlyWage = effectiveHourlyWage
        self.enableRegretAuditNotifications = enableRegretAuditNotifications
    }
}


3. SwiftData Container Setup (CloudKit Ready)

The container initialization handles both local fallback and iCloud mirroring seamlessly:

import SwiftData
import Foundation

@MainActor
final class AppContainer {
    static let shared = AppContainer()
    let container: ModelContainer

    private init() {
        let schema = Schema([
            Transaction.self,
            CurrencyRateRecord.self,
            UserSettings.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.fsudjatmiko.KinakoApp")
        )

        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error.localizedDescription)")
        }
    }
}


4. Offline-First Currency Engine Protocol

Structure & Responsibilities

All rate operations run inside an isolated actor ExchangeRateService.

1. Seed Ingestion: On first launch, the service reads the bundled rates_seed.json and populates CurrencyRateRecord if the local database is empty.
2. Offline Lookup:
  ⚬ Conversion requests query existing cached CurrencyRateRecord objects.
  ⚬ Direct pair (A -> B): uses cached rate directly.
  ⚬ Inverted pair (B -> A): uses 1 / rate.
  ⚬ Cross-currency (A -> C via USD or EUR): computes intermediate triangle rate.
3. Background Network Refresh:
  ⚬ When online, fetches from European Central Bank / Frankfurter API endpoints.
  ⚬ Updates local records without blocking transaction input or rendering.
4. Display Total Currency Switcher:
  ⚬ Summaries and grand totals are calculated by summing baseAmount (normalized to Home Currency) and multiplying by the active live rate between HomeCurrency and activeDisplayCurrency.

actor ExchangeRateService {
    static let shared = ExchangeRateService()

    /// Converts an amount from source to target currency using cached/seed rates
    func convert(amount: Decimal, from source: String, to target: String, in context: ModelContext) -> (convertedAmount: Decimal, rateUsed: Decimal) {
        if source == target {
            return (amount, 1)
        }

        // Fetch matching rate from context or bundled fallback
        let pairKey = "\(source.uppercased())_\(target.uppercased())"
        let descriptor = FetchDescriptor<CurrencyRateRecord>(predicate: #Predicate { $0.pairKey == pairKey })

        if let record = try? context.fetch(descriptor).first {
            return (amount * record.rate, record.rate)
        }

        // Fallback to identity if rate missing offline
        return (amount, 1)
    }
}
