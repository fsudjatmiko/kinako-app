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
                        // Title & Amount Card
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("TRANSACTION DETAILS")
                                    .font(.kinakoSectionHeader)
                                    .foregroundStyle(KinakoColor.accentLavender)

                                TextField("Title (e.g. Lunch with team)", text: $title)
                                    .font(.kinakoBody)
                                    .foregroundStyle(KinakoColor.textPrimary)
                                    .padding(12)
                                    .background(KinakoColor.canvasMidnight.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
                            }

                            // Amount & Currency Row
                            VStack(alignment: .leading, spacing: 6) {
                                Text("AMOUNT & CURRENCY")
                                    .font(.kinakoSectionHeader)
                                    .foregroundStyle(KinakoColor.accentLavender)

                                HStack(spacing: 12) {
                                    TextField("0.00", text: $amountString)
                                        .keyboardType(.decimalPad)
                                        .font(.kinakoCardAmount)
                                        .foregroundStyle(KinakoColor.textPrimary)
                                        .padding(12)
                                        .background(KinakoColor.canvasMidnight.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
                                        .onChange(of: amountString) { _, _ in
                                            updateLiveConversion()
                                        }

                                    Menu {
                                        ForEach(availableCurrencies, id: \.self) { code in
                                            Button(code) {
                                                selectedCurrency = code
                                                KinakoHaptic.keyPress()
                                                updateLiveConversion()
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(selectedCurrency)
                                                .font(.kinakoTelemetry)
                                                .foregroundStyle(KinakoColor.textPrimary)
                                            Image(systemName: "chevron.up.chevron.down")
                                                .font(.caption2)
                                                .foregroundStyle(KinakoColor.accentLavender)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 14)
                                        .background(KinakoColor.canvasMidnight.opacity(0.8), in: SandalphonChamfer(cut: 8))
                                        .overlay(SandalphonChamfer(cut: 8).stroke(KinakoColor.accentLavender.opacity(0.5), lineWidth: 1))
                                    }
                                }

                                // Live inline conversion subline
                                if selectedCurrency != homeCurrency && amountDecimal > 0 {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.triangle.swap")
                                            .font(.caption2)
                                            .foregroundStyle(KinakoColor.accentMagenta)

                                        Text("≈ \(convertedBaseAmount.formatted(.currency(code: homeCurrency))) (\(homeCurrency))")
                                            .font(.kinakoTelemetry)
                                            .foregroundStyle(KinakoColor.textSecondary)
                                    }
                                    .padding(.top, 4)
                                }

                                // Time cost equivalency subline
                                if let timeCost = timeCostString {
                                    HStack(spacing: 6) {
                                        Image(systemName: "hourglass")
                                            .font(.caption2)
                                            .foregroundStyle(KinakoColor.statusWarning)

                                        Text(timeCost)
                                            .font(.kinakoTelemetry)
                                            .foregroundStyle(KinakoColor.textSecondary)
                                    }
                                    .padding(.top, 2)
                                }
                            }
                        }
                        .padding(16)
                        .astralSurface(cut: 12)

                        // Category Selection Card
                        VStack(alignment: .leading, spacing: 10) {
                            Text("CATEGORY")
                                .font(.kinakoSectionHeader)
                                .foregroundStyle(KinakoColor.accentLavender)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 95))], spacing: 8) {
                                ForEach(categories, id: \.self) { cat in
                                    Button {
                                        selectedCategory = cat
                                        KinakoHaptic.keyPress()
                                    } label: {
                                        Text(cat)
                                            .font(.kinakoTelemetry)
                                            .foregroundStyle(selectedCategory == cat ? Color.white : KinakoColor.textSecondary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                selectedCategory == cat ? KinakoColor.regalPurple : KinakoColor.canvasMidnight.opacity(0.5),
                                                in: RoundedRectangle(cornerRadius: 6)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(selectedCategory == cat ? KinakoColor.accentLavender : Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .astralSurface(cut: 12)

                        // Split Outing Card
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
                                    // Default personal share to half of total
                                    myShareString = (amountDecimal / 2).formatted()
                                }
                            }

                            if isSplitExpense {
                                Divider().background(Color.white.opacity(0.1))

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("MY PERSONAL SHARE")
                                        .font(.kinakoSectionHeader)
                                        .foregroundStyle(KinakoColor.accentLavender)

                                    TextField("0.00", text: $myShareString)
                                        .keyboardType(.decimalPad)
                                        .font(.kinakoCardAmount)
                                        .foregroundStyle(KinakoColor.textPrimary)
                                        .padding(12)
                                        .background(KinakoColor.canvasMidnight.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))

                                    HStack {
                                        Text("Pending from others:")
                                            .font(.kinakoTelemetry)
                                            .foregroundStyle(KinakoColor.textSecondary)
                                        Spacer()
                                        Text("\(pendingReimbursement.formatted(.currency(code: selectedCurrency)))")
                                            .font(.kinakoTelemetry)
                                            .foregroundStyle(KinakoColor.accentMagenta)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }
                        .padding(16)
                        .astralSurface(cut: 12)

                        // Notes Card
                        VStack(alignment: .leading, spacing: 6) {
                            Text("NOTES (OPTIONAL)")
                                .font(.kinakoSectionHeader)
                                .foregroundStyle(KinakoColor.accentLavender)

                            TextField("Add optional note...", text: $note)
                                .font(.kinakoBody)
                                .foregroundStyle(KinakoColor.textPrimary)
                                .padding(12)
                                .background(KinakoColor.canvasMidnight.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
                        }
                        .padding(16)
                        .astralSurface(cut: 12)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
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
                    .font(.kinakoBody)
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

    private func updateLiveConversion() {
        Task { @MainActor in
            let amount = amountDecimal
            guard amount > 0 else {
                convertedBaseAmount = 0
                timeCostString = nil
                return
            }

            let service = ExchangeRateService.shared
            let result = await service.convert(amount: amount, from: selectedCurrency, to: homeCurrency, in: modelContext)
            convertedBaseAmount = result.convertedAmount
            rateUsed = result.rateUsed

            // Calculate equivalent time
            let wage = activeSettings?.effectiveHourlyWage
            timeCostString = TimeCostCalculator.formatEquivalentTime(amount: result.convertedAmount, hourlyWage: wage)
        }
    }

    private func saveExpense() {
        KinakoHaptic.commit()

        let originalAmt = amountDecimal
        let baseAmt = selectedCurrency == homeCurrency ? originalAmt : convertedBaseAmount
        let finalRate = selectedCurrency == homeCurrency ? 1 : rateUsed

        let myShare = isSplitExpense ? myShareDecimal : nil
        let pending = isSplitExpense ? pendingReimbursement : nil

        let transaction = Transaction(
            title: title.trimmingCharacters(in: .whitespaces),
            note: note.trimmingCharacters(in: .whitespaces).isEmpty ? nil : note,
            timestamp: Date.now,
            categoryId: selectedCategory.lowercased(),
            originalAmount: originalAmt,
            originalCurrencyCode: selectedCurrency,
            baseAmount: baseAmt,
            baseCurrencyCode: homeCurrency,
            exchangeRateUsed: finalRate,
            isSplitExpense: isSplitExpense,
            myShareAmount: myShare,
            pendingReimbursement: pending,
            auditPromptDate: Date.now.addingTimeInterval(14 * 86400) // Default 14-day regret audit prompt
        )

        modelContext.insert(transaction)
        try? modelContext.save()
        dismiss()
    }
}

