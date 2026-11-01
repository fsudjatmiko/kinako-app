//
//  GhostSplitView.swift
//  KinakoApp
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

import SwiftUI
import SwiftData

struct GhostSplitView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Transaction> { $0.isSplitExpense == true },
        sort: \Transaction.timestamp,
        order: .reverse
    ) private var splitTransactions: [Transaction]

    @Query private var userSettingsList: [UserSettings]
    private var baseCurrency: String {
        userSettingsList.first?.homeCurrencyCode ?? "USD"
    }

    private var pendingTransactions: [Transaction] {
        splitTransactions.filter { !$0.isReimbursed && ($0.pendingReimbursement ?? 0) > 0 }
    }

    private var settledTransactions: [Transaction] {
        splitTransactions.filter { $0.isReimbursed }
    }

    private var totalPendingReceivable: Decimal {
        pendingTransactions.reduce(Decimal.zero) { $0 + ($1.pendingReimbursement ?? 0) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                KinakoColor.canvasMidnight
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Outstanding Receivables Hero Card
                        receivablesHeroCard

                        // Pending Receivables Section
                        if !pendingTransactions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("OUTSTANDING CLAIMS")
                                    .font(.kinakoSectionHeader)
                                    .tracking(1.5)
                                    .foregroundStyle(KinakoColor.accentLavender)

                                ForEach(pendingTransactions) { tx in
                                    ghostSplitRow(tx: tx, isPending: true)
                                }
                            }
                        }

                        // Settled History Section
                        if !settledTransactions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("SETTLED REIMBURSEMENTS")
                                    .font(.kinakoSectionHeader)
                                    .tracking(1.5)
                                    .foregroundStyle(KinakoColor.textMuted)

                                ForEach(settledTransactions) { tx in
                                    ghostSplitRow(tx: tx, isPending: false)
                                }
                            }
                        }

                        if splitTransactions.isEmpty {
                            emptyStateView
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Splits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
    }

    // MARK: - Subviews

    private var receivablesHeroCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("RECEIVABLES TRAY")
                    .font(.kinakoTelemetry)
                    .tracking(1.2)
                    .foregroundStyle(KinakoColor.textSecondary)

                Spacer()

                Text("\(pendingTransactions.count) PENDING")
                    .font(.kinakoTelemetry)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(KinakoColor.accentLavender.opacity(0.15))
                    .clipShape(Capsule())
                    .foregroundStyle(KinakoColor.accentLavender)
            }

            Text(formatCurrency(amount: totalPendingReceivable, currency: baseCurrency))
                .font(.kinakoHeroBalance)
                .foregroundStyle(KinakoColor.textPrimary)

            Text("Reimbursements owed to you that are isolated from your personal budget burn.")
                .font(.kinakoTelemetry)
                .foregroundStyle(KinakoColor.textMuted)
        }
        .padding(20)
        .astralSurface(cut: 10, accentColor: KinakoColor.accentLavender)
    }

    private func ghostSplitRow(tx: Transaction, isPending: Bool) -> some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(tx.title.isEmpty ? tx.categoryId.capitalized : tx.title)
                    .font(.kinakoBody)
                    .foregroundStyle(KinakoColor.textPrimary)

                HStack(spacing: 8) {
                    Text("Total: \(formatCurrency(amount: tx.originalAmount, currency: tx.originalCurrencyCode))")
                    Text("•")
                    Text("My Share: \(formatCurrency(amount: tx.myShareAmount ?? tx.originalAmount, currency: tx.originalCurrencyCode))")
                }
                .font(.kinakoTelemetry)
                .foregroundStyle(KinakoColor.textMuted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(formatCurrency(amount: tx.pendingReimbursement ?? 0, currency: tx.originalCurrencyCode))
                    .font(.kinakoCardAmount)
                    .foregroundStyle(isPending ? KinakoColor.accentLavender : KinakoColor.textMuted)

                if isPending {
                    Button {
                        KinakoHaptic.commit()
                        withAnimation(.kinakoSnap) {
                            tx.isReimbursed = true
                            try? modelContext.save()
                        }
                    } label: {
                        Text("Settle")
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(KinakoColor.accentMagenta.opacity(0.2))
                            .overlay(
                                Capsule()
                                    .stroke(KinakoColor.accentMagenta.opacity(0.6), lineWidth: 0.8)
                            )
                            .clipShape(Capsule())
                            .foregroundStyle(KinakoColor.textPrimary)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("Settled")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(KinakoColor.statusNormal)
                }
            }
        }
        .padding(16)
        .astralSurface(cut: 8, accentColor: isPending ? KinakoColor.accentLavender : KinakoColor.canvasCard, showGlow: false)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 40))
                .foregroundStyle(KinakoColor.textMuted.opacity(0.5))

            Text("No Split Expenses")
                .font(.kinakoBody)
                .foregroundStyle(KinakoColor.textSecondary)

            Text("When logging a group dinner or bill, toggle 'Split Outing' in the Add Expense sheet to track friend reimbursements here without skewing your personal budget.")
                .font(.kinakoTelemetry)
                .foregroundStyle(KinakoColor.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(.vertical, 40)
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
    GhostSplitView()
        .modelContainer(for: [Transaction.self, UserSettings.self], inMemory: true)
}
