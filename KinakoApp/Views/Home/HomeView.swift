//
//  HomeView.swift
//  KinakoApp
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Transaction.timestamp, order: .reverse)
    private var transactions: [Transaction]

    @Query private var userSettingsList: [UserSettings]

    @State private var showAddExpense: Bool = false
    @State private var activeDisplayCurrency: String = "IDR"
    @State private var convertedDailyBudget: Decimal = 0

    private let availableCurrencies = [
        "IDR", "USD", "JPY", "SGD", "MYR", "THB",
        "KRW", "CNY", "TWD", "HKD", "VND", "PHP",
        "EUR", "GBP", "AUD"
    ]

    private var activeSettings: UserSettings {
        if let first = userSettingsList.first {
            return first
        }
        let defaultSettings = UserSettings(
            homeCurrencyCode: "IDR",
            activeDisplayCurrencyCode: "IDR",
            monthlyBudgetCap: 5000000,
            effectiveHourlyWage: 50000
        )
        return defaultSettings
    }

    private var homeCurrency: String {
        activeSettings.homeCurrencyCode
    }

    // Current month pacing calculation
    private var monthlyCap: Decimal {
        activeSettings.monthlyBudgetCap > 0 ? activeSettings.monthlyBudgetCap : 5000000
    }

    private var currentMonthTransactions: [Transaction] {
        let calendar = Calendar.current
        let now = Date.now
        return transactions.filter {
            calendar.isDate($0.timestamp, equalTo: now, toGranularity: .month) &&
            calendar.isDate($0.timestamp, equalTo: now, toGranularity: .year)
        }
    }

    private var totalSpentThisMonth: Decimal {
        currentMonthTransactions.reduce(into: Decimal(0)) { total, tx in
            total += GhostSplitManager.personalCost(for: tx)
        }
    }

    private var todaySpend: Decimal {
        let calendar = Calendar.current
        let now = Date.now
        return transactions.filter { calendar.isDate($0.timestamp, inSameDayAs: now) }
            .reduce(into: Decimal(0)) { total, tx in
                total += GhostSplitManager.personalCost(for: tx)
            }
    }

    private var daysRemainingInMonth: Int {
        let calendar = Calendar.current
        let now = Date.now
        guard let range = calendar.range(of: .day, in: .month, for: now) else { return 30 }
        let currentDay = calendar.component(.day, from: now)
        return max(1, range.count - currentDay + 1)
    }

    private var pacingData: (safeDaily: Decimal, remainingBudget: Decimal) {
        PacingEngine.calculateSafeDaily(
            monthlyCap: monthlyCap,
            totalSpentThisMonth: totalSpentThisMonth,
            daysRemainingInMonth: daysRemainingInMonth
        )
    }

    private var budgetState: BudgetState {
        PacingEngine.classifyBudgetState(
            monthlyCap: monthlyCap,
            remainingBudget: pacingData.remainingBudget,
            safeDaily: pacingData.safeDaily,
            todaySpend: todaySpend
        )
    }

    private var pendingReimbursements: [Transaction] {
        transactions.filter { $0.isSplitExpense && !$0.isReimbursed && ($0.pendingReimbursement ?? 0) > 0 }
    }

    private var totalPendingReimbursement: Decimal {
        pendingReimbursements.reduce(into: Decimal(0)) { total, tx in
            total += (tx.pendingReimbursement ?? 0)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                KinakoColor.canvasMidnight
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Hero Safe-to-Spend Dial Card
                        heroSafeToSpendCard

                        // Ghost Split Receivables Banner (if any pending)
                        if !pendingReimbursements.isEmpty {
                            receivablesBanner
                        }

                        // Recent Transactions Section
                        transactionsSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Kinako")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        ForEach(availableCurrencies, id: \.self) { curr in
                            Button {
                                activeDisplayCurrency = curr
                                KinakoHaptic.keyPress()
                                updateConvertedHeroBudget()
                            } label: {
                                if curr == activeDisplayCurrency {
                                    Label(curr, systemImage: "checkmark")
                                } else {
                                    Text(curr)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(activeDisplayCurrency)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(KinakoColor.textPrimary)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(KinakoColor.accentLavender)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(KinakoColor.canvasCard, in: Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        KinakoHaptic.keyPress()
                        showAddExpense = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(KinakoColor.accentLavender)
                            .frame(width: 32, height: 32)
                            .background(KinakoColor.canvasCard)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(KinakoColor.accentLavender.opacity(0.4), lineWidth: 1))
                    }
                    .accessibilityLabel("Add Expense")
                }
            }
            .sheet(isPresented: $showAddExpense) {
                AddExpenseSheet()
            }
            .onAppear {
                seedInitialStateIfNeeded()
            }
        }
    }

    // MARK: - Subviews

    private var heroSafeToSpendCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("SAFE-TO-SPEND")
                    .font(.kinakoSectionHeader)
                    .tracking(2)
                    .foregroundStyle(KinakoColor.textSecondary)

                Spacer()

                // State Pill
                Text(budgetState.statusCopy)
                    .font(.kinakoTelemetry)
                    .foregroundStyle(budgetState.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(budgetState.accentColor.opacity(0.12), in: Capsule())
                    .overlay(Capsule().stroke(budgetState.accentColor.opacity(0.6), lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(convertedDailyBudget.formatted(.currency(code: activeDisplayCurrency)))
                    .font(.kinakoHeroBalance)
                    .foregroundStyle(KinakoColor.textPrimary)

                Text("DAILY BURN ALLOWANCE • \(daysRemainingInMonth) DAYS REMAINING")
                    .font(.kinakoTelemetry)
                    .foregroundStyle(KinakoColor.textMuted)
            }

            Divider().background(Color.white.opacity(0.1))

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("REMAINING BUDGET")
                        .font(.kinakoTelemetry)
                        .foregroundStyle(KinakoColor.textMuted)
                    Text(pacingData.remainingBudget.formatted(.currency(code: homeCurrency)))
                        .font(.kinakoCardAmount)
                        .foregroundStyle(KinakoColor.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("MONTHLY CAP")
                        .font(.kinakoTelemetry)
                        .foregroundStyle(KinakoColor.textMuted)
                    Text(monthlyCap.formatted(.currency(code: homeCurrency)))
                        .font(.kinakoCardAmount)
                        .foregroundStyle(KinakoColor.textSecondary)
                }
            }
        }
        .padding(20)
        .astralSurface(cut: 16, accentColor: budgetState.accentColor)
    }

    private var receivablesBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(KinakoColor.accentMagenta)
                Text("GHOST SPLIT RECEIVABLES")
                    .font(.kinakoSectionHeader)
                    .foregroundStyle(KinakoColor.accentMagenta)
                Spacer()
                Text("\(pendingReimbursements.count) PENDING")
                    .font(.kinakoTelemetry)
                    .foregroundStyle(KinakoColor.textSecondary)
            }

            ForEach(pendingReimbursements.prefix(3)) { tx in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tx.title)
                            .font(.kinakoBody)
                            .foregroundStyle(KinakoColor.textPrimary)
                        Text("Owed: \((tx.pendingReimbursement ?? 0).formatted(.currency(code: tx.originalCurrencyCode)))")
                            .font(.kinakoTelemetry)
                            .foregroundStyle(KinakoColor.textSecondary)
                    }
                    Spacer()
                    Button("Settled") {
                        KinakoHaptic.keyPress()
                        withAnimation(.kinakoSnap) {
                            GhostSplitManager.settleReimbursement(for: tx)
                            try? modelContext.save()
                        }
                    }
                    .font(.kinakoTelemetry)
                    .foregroundStyle(KinakoColor.accentLavender)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(KinakoColor.canvasMidnight, in: RoundedRectangle(cornerRadius: 6))
                }
                .padding(8)
                .background(KinakoColor.canvasMidnight.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .astralSurface(cut: 12, accentColor: KinakoColor.accentMagenta, showGlow: false)
    }

    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("RECENT ACTIVITY")
                    .font(.kinakoSectionHeader)
                    .tracking(2)
                    .foregroundStyle(KinakoColor.accentLavender)
                Spacer()
                Text("\(transactions.count) LOGGED")
                    .font(.kinakoTelemetry)
                    .foregroundStyle(KinakoColor.textMuted)
            }

            if transactions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 32))
                        .foregroundStyle(KinakoColor.textMuted)
                    Text("No transactions logged yet.")
                        .font(.kinakoBody)
                        .foregroundStyle(KinakoColor.textSecondary)
                    Text("Tap 'Add Expense' to record your first purchase.")
                        .font(.kinakoTelemetry)
                        .foregroundStyle(KinakoColor.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .astralSurface(cut: 12, accentColor: KinakoColor.accentLavender, showGlow: false)
            } else {
                ForEach(transactions) { tx in
                    transactionRow(tx)
                }
            }
        }
    }

    private func transactionRow(_ tx: Transaction) -> some View {
        HStack(alignment: .center, spacing: 14) {
            // Category Icon Badge
            ZStack {
                Circle()
                    .fill(KinakoColor.regalPurple.opacity(0.4))
                    .frame(width: 40, height: 40)
                Image(systemName: iconForCategory(tx.categoryId))
                    .foregroundStyle(KinakoColor.accentLavender)
            }

            // Title & Metadata
            VStack(alignment: .leading, spacing: 3) {
                Text(tx.title)
                    .font(.kinakoBody)
                    .foregroundStyle(KinakoColor.textPrimary)

                HStack(spacing: 6) {
                    Text(tx.categoryId.capitalized)
                        .font(.kinakoTelemetry)
                        .foregroundStyle(KinakoColor.textSecondary)

                    if tx.isSplitExpense {
                        Text("•")
                            .font(.kinakoTelemetry)
                            .foregroundStyle(KinakoColor.textMuted)
                        Text(tx.isReimbursed ? "Reimbursed" : "Split Outing")
                            .font(.kinakoTelemetry)
                            .foregroundStyle(tx.isReimbursed ? KinakoColor.accentLavender : KinakoColor.accentMagenta)
                    }
                }
            }

            Spacer()

            // Amount Display
            VStack(alignment: .trailing, spacing: 2) {
                Text(tx.originalAmount.formatted(.currency(code: tx.originalCurrencyCode)))
                    .font(.kinakoCardAmount)
                    .foregroundStyle(KinakoColor.textPrimary)

                if tx.originalCurrencyCode != homeCurrency {
                    Text("≈ \(tx.baseAmount.formatted(.currency(code: homeCurrency)))")
                        .font(.kinakoTelemetry)
                        .foregroundStyle(KinakoColor.textMuted)
                }
            }
        }
        .padding(14)
        .astralSurface(cut: 10, accentColor: KinakoColor.accentLavender, showGlow: false)
        .contextMenu {
            Button(role: .destructive) {
                withAnimation(.kinakoSnap) {
                    modelContext.delete(tx)
                    try? modelContext.save()
                    updateConvertedHeroBudget()
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func iconForCategory(_ categoryId: String) -> String {
        switch categoryId.lowercased() {
        case "dining": return "fork.knife"
        case "groceries": return "cart.fill"
        case "transit": return "tram.fill"
        case "shopping": return "bag.fill"
        case "entertainment": return "tv.fill"
        default: return "creditcard.fill"
        }
    }

    private func seedInitialStateIfNeeded() {
        Task { @MainActor in
            let service = ExchangeRateService.shared
            _ = try? await service.seedInitialRatesIfNeeded(in: modelContext)

            if userSettingsList.isEmpty {
                let initialSettings = UserSettings(
                    homeCurrencyCode: "IDR",
                    activeDisplayCurrencyCode: "IDR",
                    monthlyBudgetCap: 5000000,
                    effectiveHourlyWage: 50000
                )
                modelContext.insert(initialSettings)
                try? modelContext.save()
            }

            if let currentSettings = userSettingsList.first {
                activeDisplayCurrency = currentSettings.activeDisplayCurrencyCode
            }

            updateConvertedHeroBudget()
        }
    }

    private func updateConvertedHeroBudget() {
        Task { @MainActor in
            let safeDailyInHome = pacingData.safeDaily
            if activeDisplayCurrency == homeCurrency {
                convertedDailyBudget = safeDailyInHome
            } else {
                let service = ExchangeRateService.shared
                let result = await service.convert(
                    amount: safeDailyInHome,
                    from: homeCurrency,
                    to: activeDisplayCurrency,
                    in: modelContext
                )
                convertedDailyBudget = result.convertedAmount
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Transaction.self, CurrencyRateRecord.self, UserSettings.self], inMemory: true)
}

