//
//  AddExpenseSheet.swift
//  KinakoApp
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

import SwiftUI
import SwiftData

struct AddExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var userSettingsList: [UserSettings]

    // Form inputs
    @State private var title: String = ""
    @State private var note: String = ""
    @State private var amountString: String = ""
    @State private var selectedCurrency: String = "IDR"
    @State private var selectedCategory: String = "Dining"
    @State private var isSplitExpense: Bool = false
    @State private var myShareString: String = ""

    // Live conversion states
    @State private var convertedBaseAmount: Decimal = 0
    @State private var rateUsed: Decimal = 1
    @State private var timeCostString: String? = nil

    private let availableCurrencies = [
        "IDR", "USD", "JPY", "SGD", "MYR", "THB",
        "KRW", "CNY", "TWD", "HKD", "VND", "PHP",
        "EUR", "GBP", "AUD"
    ]

    private let categories = [
        "Dining", "Groceries", "Transit", "Shopping", "Entertainment", "General"
    ]

    private var activeSettings: UserSettings? {
        userSettingsList.first
    }

    private var homeCurrency: String {
        activeSettings?.homeCurrencyCode ?? "IDR"
    }

    private var amountDecimal: Decimal {
        Decimal(string: amountString) ?? 0
    }

    private var myShareDecimal: Decimal {
        Decimal(string: myShareString) ?? 0
    }

    private var pendingReimbursement: Decimal {
        if isSplitExpense {
            let (pending, _) = GhostSplitManager.calculateSplit(totalAmount: amountDecimal, myShare: myShareDecimal)
            return pending
        }
        return 0
    }

    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && amountDecimal > 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                KinakoColor.canvasMidnight
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Large Amount Entry Card
                        amountHeroCard

                        // 2. Transaction Details Card
                        detailsCard

                        // 3. Category Selection Card
                        categoryCard

                        // 4. Split Outing Card
                        splitOutingCard
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(KinakoColor.textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveExpense()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isFormValid ? KinakoColor.accentLavender : KinakoColor.textMuted)
                    .disabled(!isFormValid)
                }
            }
            .onAppear {
                if let settings = activeSettings {
                    selectedCurrency = settings.activeDisplayCurrencyCode
                }
                updateLiveConversion()
            }
        }
    }

    // MARK: - Subviews

    private var amountHeroCard: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Menu {
                    ForEach(availableCurrencies, id: \.self) { code in
                        Button(code) {
                            selectedCurrency = code
                            KinakoHaptic.keyPress()
                            updateLiveConversion()
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedCurrency)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(KinakoColor.accentLavender)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(KinakoColor.accentLavender)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(KinakoColor.canvasMidnight.opacity(0.8), in: Capsule())
                    .overlay(Capsule().stroke(KinakoColor.accentLavender.opacity(0.4), lineWidth: 0.8))
                }

                TextField("0", text: $amountString)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(KinakoColor.textPrimary)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.5)
                    .onChange(of: amountString) { _, _ in
                        updateLiveConversion()
                    }
            }

            // Live inline conversion subline (e.g. ≈ Rp 150.000 (IDR))
            if selectedCurrency != homeCurrency && amountDecimal > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.swap")
                        .font(.caption2)
                        .foregroundStyle(KinakoColor.accentMagenta)

                    Text("≈ \(formatCurrency(amount: convertedBaseAmount, currency: homeCurrency)) (\(homeCurrency))")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(KinakoColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Time cost equivalency subline
            if let timeCost = timeCostString {
                HStack(spacing: 6) {
                    Image(systemName: "hourglass")
                        .font(.caption2)
                        .foregroundStyle(KinakoColor.statusWarning)

                    Text(timeCost)
                        .font(.kinakoTelemetry)
                        .foregroundStyle(KinakoColor.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .astralSurface(cut: 10, accentColor: KinakoColor.accentLavender)
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TRANSACTION DETAILS")
                .font(.kinakoSectionHeader)
                .tracking(1.5)
                .foregroundStyle(KinakoColor.accentLavender)

            TextField("Title (e.g. Lunch with team)", text: $title)
                .font(.kinakoBody)
                .foregroundStyle(KinakoColor.textPrimary)
                .padding(12)
                .background(KinakoColor.canvasMidnight.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )

            TextField("Notes (optional)", text: $note)
                .font(.kinakoBody)
                .foregroundStyle(KinakoColor.textPrimary)
                .padding(12)
                .background(KinakoColor.canvasMidnight.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        }
        .padding(18)
        .astralSurface(cut: 10, accentColor: KinakoColor.canvasCard, showGlow: false)
    }

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CATEGORY")
                .font(.kinakoSectionHeader)
                .tracking(1.5)
                .foregroundStyle(KinakoColor.accentLavender)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { cat in
                        Button {
                            selectedCategory = cat
                            KinakoHaptic.keyPress()
                        } label: {
                            Text(cat)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(selectedCategory == cat ? Color.white : KinakoColor.textSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    selectedCategory == cat ? KinakoColor.regalPurple : KinakoColor.canvasMidnight.opacity(0.6),
                                    in: Capsule()
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(selectedCategory == cat ? KinakoColor.accentLavender : Color.white.opacity(0.12), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(18)
        .astralSurface(cut: 10, accentColor: KinakoColor.canvasCard, showGlow: false)
    }

    private var splitOutingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $isSplitExpense) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Split Outing")
                        .font(.kinakoBody)
                        .foregroundStyle(KinakoColor.textPrimary)
                    Text("Asymmetric group reimbursement ledger")
                        .font(.kinakoTelemetry)
                        .foregroundStyle(KinakoColor.textMuted)
                }
            }
            .tint(KinakoColor.accentLavender)
            .onChange(of: isSplitExpense) { _, newValue in
                KinakoHaptic.keyPress()
                if newValue && myShareString.isEmpty {
                    myShareString = (amountDecimal / 2).formatted()
                }
            }

            if isSplitExpense {
                Divider().background(Color.white.opacity(0.1))

                VStack(alignment: .leading, spacing: 8) {
                    Text("MY PERSONAL SHARE")
                        .font(.kinakoSectionHeader)
                        .foregroundStyle(KinakoColor.accentLavender)

                    HStack {
                        Text(selectedCurrency)
                            .font(.kinakoTelemetry)
                            .foregroundStyle(KinakoColor.textSecondary)

                        TextField("0.00", text: $myShareString)
                            .keyboardType(.decimalPad)
                            .font(.kinakoCardAmount)
                            .foregroundStyle(KinakoColor.textPrimary)
                    }
                    .padding(12)
                    .background(KinakoColor.canvasMidnight.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))

                    HStack {
                        Text("Pending from others:")
                            .font(.kinakoTelemetry)
                            .foregroundStyle(KinakoColor.textSecondary)
                        Spacer()
                        Text(formatCurrency(amount: pendingReimbursement, currency: selectedCurrency))
                            .font(.kinakoTelemetry)
                            .foregroundStyle(KinakoColor.accentMagenta)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(18)
        .astralSurface(cut: 10, accentColor: isSplitExpense ? KinakoColor.accentMagenta : KinakoColor.canvasCard, showGlow: isSplitExpense)
    }

    // MARK: - Actions

    private func updateLiveConversion() {
        Task { @MainActor in
            let amount = amountDecimal
            guard amount > 0 else {
                convertedBaseAmount = 0
                timeCostString = nil
                return
            }

            let service = ExchangeRateService.shared
            let conversion = await service.convert(
                amount: amount,
                from: selectedCurrency,
                to: homeCurrency,
                in: modelContext
            )

            self.convertedBaseAmount = conversion.convertedAmount
            self.rateUsed = conversion.rateUsed

            // Calculate time-cost equivalency against user's hourly wage
            if let wage = activeSettings?.effectiveHourlyWage {
                self.timeCostString = TimeCostCalculator.formatEquivalentTime(
                    amount: conversion.convertedAmount,
                    hourlyWage: wage
                )
            } else {
                self.timeCostString = nil
            }
        }
    }

    private func saveExpense() {
        guard isFormValid else { return }
        KinakoHaptic.commit()

        let amount = amountDecimal
        let baseAmt = selectedCurrency == homeCurrency ? amount : convertedBaseAmount

        let (pending, _) = GhostSplitManager.calculateSplit(
            totalAmount: amount,
            myShare: isSplitExpense ? myShareDecimal : amount
        )
        let actualMyShare = isSplitExpense ? myShareDecimal : amount

        let transaction = Transaction(
            title: title.trimmingCharacters(in: .whitespaces),
            note: note.isEmpty ? nil : note,
            timestamp: Date.now,
            categoryId: selectedCategory.lowercased(),
            originalAmount: amount,
            originalCurrencyCode: selectedCurrency,
            baseAmount: baseAmt,
            baseCurrencyCode: homeCurrency,
            exchangeRateUsed: rateUsed,
            isSplitExpense: isSplitExpense,
            myShareAmount: isSplitExpense ? actualMyShare : nil,
            pendingReimbursement: isSplitExpense ? pending : nil,
            auditPromptDate: Calendar.current.date(byAdding: .day, value: 14, to: Date.now)
        )

        modelContext.insert(transaction)
        try? modelContext.save()
        dismiss()
    }

    private func formatCurrency(amount: Decimal, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        if currency == "IDR" || currency == "JPY" || currency == "KRW" {
            formatter.maximumFractionDigits = 0
        } else {
            formatter.maximumFractionDigits = 2
        }
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currency) \(amount)"
    }
}

#Preview {
    AddExpenseSheet()
        .modelContainer(for: [Transaction.self, UserSettings.self], inMemory: true)
}
