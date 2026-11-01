//
//  RegretAuditView.swift
//  KinakoApp
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

import SwiftUI
import SwiftData

struct RegretAuditView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.timestamp, order: .reverse) private var transactions: [Transaction]
    @Query private var userSettingsList: [UserSettings]

    private var baseCurrency: String {
        userSettingsList.first?.homeCurrencyCode ?? "USD"
    }

    private var auditedTransactions: [Transaction] {
        transactions.filter { $0.satisfactionRating != nil }
    }

    private var pendingAuditTransactions: [Transaction] {
        transactions.filter { $0.satisfactionRating == nil }
    }

    /// Calculates percentage of audited transactions that scored 3 or higher (Worth It / High ROI)
    private var impulseRoiPercentage: Int {
        guard !auditedTransactions.isEmpty else { return 100 }
        let highValueCount = auditedTransactions.filter { ($0.satisfactionRating ?? 0) >= 3 }.count
        return Int(round(Double(highValueCount) / Double(auditedTransactions.count) * 100.0))
    }

    /// Total regret expenditure (scores 1 or 2) in base currency
    private var totalRegretSpent: Decimal {
        auditedTransactions
            .filter { ($0.satisfactionRating ?? 0) <= 2 }
            .reduce(Decimal.zero) { $0 + $1.baseAmount }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                KinakoColor.canvasMidnight
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Impulse ROI Hero Card
                        impulseRoiHeroCard

                        // Pending Audits Section
                        if !pendingAuditTransactions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("AWAITING SATISFACTION AUDIT")
                                        .font(.kinakoSectionHeader)
                                        .tracking(1.5)
                                        .foregroundStyle(KinakoColor.accentLavender)

                                    Spacer()

                                    Text("\(pendingAuditTransactions.count)")
                                        .font(.kinakoTelemetry)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(KinakoColor.accentLavender.opacity(0.15))
                                        .clipShape(Capsule())
                                        .foregroundStyle(KinakoColor.accentLavender)
                                }

                                ForEach(pendingAuditTransactions) { tx in
                                    pendingAuditRow(tx: tx)
                                }
                            }
                        }

                        // Completed Audits Section
                        if !auditedTransactions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("COMPLETED AUDITS")
                                    .font(.kinakoSectionHeader)
                                    .tracking(1.5)
                                    .foregroundStyle(KinakoColor.textMuted)

                                ForEach(auditedTransactions) { tx in
                                    completedAuditRow(tx: tx)
                                }
                            }
                        }

                        if transactions.isEmpty {
                            emptyStateView
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Audits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
    }

    // MARK: - Subviews

    private var impulseRoiHeroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("IMPULSE ROI INDEX")
                    .font(.kinakoTelemetry)
                    .tracking(1.2)
                    .foregroundStyle(KinakoColor.textSecondary)

                Spacer()

                Text(impulseRoiPercentage >= 70 ? "HIGH JOY" : "AUDIT PRESSURE")
                    .font(.kinakoTelemetry)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(impulseRoiPercentage >= 70 ? KinakoColor.statusNormal.opacity(0.15) : KinakoColor.statusWarning.opacity(0.15))
                    .clipShape(Capsule())
                    .foregroundStyle(impulseRoiPercentage >= 70 ? KinakoColor.statusNormal : KinakoColor.statusWarning)
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(impulseRoiPercentage)%")
                    .font(.kinakoHeroBalance)
                    .foregroundStyle(KinakoColor.textPrimary)

                Text("Satisfied Spend")
                    .font(.kinakoBody)
                    .foregroundStyle(KinakoColor.textSecondary)
            }

            if totalRegretSpent > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(KinakoColor.statusWarning)
                    Text("Regret Leakage: \(formatCurrency(amount: totalRegretSpent, currency: baseCurrency)) flagged as impulse waste.")
                        .font(.kinakoTelemetry)
                        .foregroundStyle(KinakoColor.textMuted)
                }
            } else {
                Text("Zero regret leakage recorded across audited purchases.")
                    .font(.kinakoTelemetry)
                    .foregroundStyle(KinakoColor.textMuted)
            }
        }
        .padding(20)
        .astralSurface(cut: 10, accentColor: impulseRoiPercentage >= 70 ? KinakoColor.accentLavender : KinakoColor.statusWarning)
    }

    private func pendingAuditRow(tx: Transaction) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tx.title.isEmpty ? tx.categoryId.capitalized : tx.title)
                        .font(.kinakoBody)
                        .foregroundStyle(KinakoColor.textPrimary)

                    Text("\(tx.categoryId.capitalized) • \(formatCurrency(amount: tx.originalAmount, currency: tx.originalCurrencyCode))")
                        .font(.kinakoTelemetry)
                        .foregroundStyle(KinakoColor.textSecondary)
                }

                Spacer()

                Text("Rate ROI")
                    .font(.kinakoTelemetry)
                    .foregroundStyle(KinakoColor.accentLavender)
            }

            // 1 to 5 Rating Button Row
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { score in
                    Button {
                        KinakoHaptic.commit()
                        withAnimation(.kinakoSnap) {
                            tx.satisfactionRating = score
                            tx.auditedAt = Date.now
                            try? modelContext.save()
                        }
                    } label: {
                        VStack(spacing: 2) {
                            Text("\(score)")
                                .font(.system(size: 13, weight: .bold))
                            Text(shortRatingLabel(score))
                                .font(.system(size: 8, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(KinakoColor.canvasMidnight.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(ratingColor(score).opacity(0.4), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .foregroundStyle(ratingColor(score))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .astralSurface(cut: 8, accentColor: KinakoColor.accentLavender, showGlow: false)
    }

    private func completedAuditRow(tx: Transaction) -> some View {
        let score = tx.satisfactionRating ?? 3
        return HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(tx.title.isEmpty ? tx.categoryId.capitalized : tx.title)
                    .font(.kinakoBody)
                    .foregroundStyle(KinakoColor.textPrimary)

                Text("\(tx.categoryId.capitalized) • \(formatCurrency(amount: tx.originalAmount, currency: tx.originalCurrencyCode))")
                    .font(.kinakoTelemetry)
                    .foregroundStyle(KinakoColor.textMuted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: score >= 4 ? "star.fill" : "star")
                        .font(.system(size: 11))
                        .foregroundStyle(ratingColor(score))
                    Text("\(score)/5 — \(shortRatingLabel(score))")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(ratingColor(score))
                }

                if let auditedAt = tx.auditedAt {
                    Text("Audited \(auditedAt.formatted(.dateTime.month().day()))")
                        .font(.system(size: 10))
                        .foregroundStyle(KinakoColor.textMuted)
                }
            }
        }
        .padding(14)
        .astralSurface(cut: 8, accentColor: ratingColor(score).opacity(0.5), showGlow: false)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(KinakoColor.textMuted.opacity(0.5))

            Text("No Transactions to Audit")
                .font(.kinakoBody)
                .foregroundStyle(KinakoColor.textSecondary)

            Text("Transactions logged in Kinako will surface here so you can score their psychological satisfaction (1–5) and track impulse spending leakage.")
                .font(.kinakoTelemetry)
                .foregroundStyle(KinakoColor.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(.vertical, 40)
    }

    private func shortRatingLabel(_ score: Int) -> String {
        switch score {
        case 5: return "Joy"
        case 4: return "Good"
        case 3: return "Meh"
        case 2: return "Low"
        case 1: return "Regret"
        default: return ""
        }
    }

    private func ratingColor(_ score: Int) -> Color {
        switch score {
        case 4, 5: return KinakoColor.accentLavender
        case 3: return KinakoColor.bladeSilver
        case 2: return KinakoColor.statusWarning
        case 1: return KinakoColor.statusInverse
        default: return KinakoColor.textMuted
        }
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
    RegretAuditView()
        .modelContainer(for: [Transaction.self, UserSettings.self], inMemory: true)
}
