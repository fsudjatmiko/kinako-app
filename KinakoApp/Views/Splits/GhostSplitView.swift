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
                KinakoColor.backgroundCanvas
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Outstanding Receivables Hero Card
                        receivablesHeroCard

                        // Pending Receivables Section
                        if !pendingTransactions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("OUTSTANDING CLAIMS")
                                    .font(.helveticaTitle(size: 12, weight: .bold))
                                    .tracking(1.5)
                                    .foregroundStyle(KinakoColor.accentPrimary)

                                ForEach(pendingTransactions) { tx in
                                    ghostSplitRow(tx: tx, isPending: true)
                                }
                            }
                        }

                        // Settled History Section
                        if !settledTransactions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("SETTLED REIMBURSEMENTS")
                                    .font(.helveticaTitle(size: 12, weight: .bold))
                                    .tracking(1.5)
                                    .foregroundStyle(KinakoColor.textSecondary)

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
            .navigationTitle("Shared Bills")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
    }

    // MARK: - Subviews

    private var receivablesHeroCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("OWED TO YOU")
                    .font(.helveticaTitle(size: 12, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(KinakoColor.textSecondary)

                Spacer()

                Text("\(pendingTransactions.count) PENDING")
                    .font(.helveticaCaption(size: 11, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(KinakoColor.accentPrimary.opacity(0.12))
                    .clipShape(Capsule())
                    .foregroundStyle(KinakoColor.accentPrimary)
            }

            Text(formatCurrency(amount: totalPendingReceivable, currency: baseCurrency))
                .font(.helveticaNumbers(size: 38, weight: .bold))
                .foregroundStyle(KinakoColor.textPrimary)

            Text("Tracked reimbursements isolated from your personal daily budget burn.")
                .font(.helveticaBody(size: 13))
                .foregroundStyle(KinakoColor.textSecondary)
        }
        .padding(20)
        .astralSurface(cut: 10, accentColor: KinakoColor.accentPrimary)
    }

    private func ghostSplitRow(tx: Transaction, isPending: Bool) -> some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(tx.title.isEmpty ? tx.categoryId.capitalized : tx.title)
                    .font(.helveticaTitle(size: 15, weight: .bold))
                    .foregroundStyle(KinakoColor.textPrimary)

                HStack(spacing: 8) {
                    Text("Total: \(formatCurrency(amount: tx.originalAmount, currency: tx.originalCurrencyCode))")
                    Text("•")
                    Text("My Share: \(formatCurrency(amount: tx.myShareAmount ?? tx.originalAmount, currency: tx.originalCurrencyCode))")
                }
                .font(.helveticaCaption(size: 12, weight: .regular))
                .foregroundStyle(KinakoColor.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(formatCurrency(amount: tx.pendingReimbursement ?? 0, currency: tx.originalCurrencyCode))
                    .font(.helveticaNumbers(size: 16, weight: .bold))
                    .foregroundStyle(isPending ? KinakoColor.accentPrimary : KinakoColor.textSecondary)

                if isPending {
                    Button {
                        KinakoHaptic.commit()
                        withAnimation(.kinakoSnap) {
                            tx.isReimbursed = true
                            try? modelContext.save()
                        }
                    } label: {
                        Text("Settle")
                            .font(.helveticaCaption(size: 11, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(KinakoColor.accentMagenta.opacity(0.18))
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
                        .font(.helveticaCaption(size: 11, weight: .bold))
                        .foregroundStyle(KinakoColor.statusNormal)
                }
            }
        }
        .padding(16)
        .astralSurface(cut: 8, accentColor: isPending ? KinakoColor.accentPrimary : KinakoColor.cardSurface, showGlow: false)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 40))
                .foregroundStyle(KinakoColor.textSecondary.opacity(0.5))

            Text("No Shared Bills")
                .font(.helveticaTitle(size: 18, weight: .bold))
                .foregroundStyle(KinakoColor.textPrimary)

            Text("When you pay for a group, split the cost to track reimbursements without skewing your personal budget.")
                .font(.helveticaBody(size: 14))
                .foregroundStyle(KinakoColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
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
