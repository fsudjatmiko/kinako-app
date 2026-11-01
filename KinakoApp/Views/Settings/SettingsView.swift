//
//  SettingsView.swift
//  KinakoApp
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userSettingsList: [UserSettings]

    @State private var selectedBaseCurrency: String = "USD"
    @State private var monthlyCapString: String = "600"
    @State private var hourlyWageString: String = "25"
    @State private var showSavedAlert: Bool = false

    private let supportedCurrencies = [
        "USD", "EUR", "JPY", "GBP", "AUD", "CAD", "CHF", "CNY",
        "HKD", "NZD", "SEK", "KRW", "SGD", "NOK", "IDR"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                KinakoColor.canvasMidnight
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header / Identity Card
                        identityCard

                        // Core Financial Parameters Card
                        parametersCard

                        // About & Version Card
                        aboutCard
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSettings()
                    }
                    .foregroundStyle(KinakoColor.accentLavender)
                }
            }
            .onAppear {
                loadCurrentSettings()
            }
            .alert("Settings Saved", isPresented: $showSavedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your financial parameters and base currency have been updated.")
            }
        }
    }

    // MARK: - Subviews

    private var identityCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [KinakoColor.accentLavender, KinakoColor.accentMagenta],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)

                Image(systemName: "bolt.shield.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Kinako Core")
                    .font(.kinakoSectionHeader)
                    .foregroundStyle(KinakoColor.textPrimary)

                Text("Tohka Engine v1.0 • Sandalphon GFX")
                    .font(.kinakoTelemetry)
                    .foregroundStyle(KinakoColor.textSecondary)
            }

            Spacer()
        }
        .padding(18)
        .astralSurface(cut: 10, accentColor: KinakoColor.accentLavender)
    }

    private var parametersCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("FINANCIAL PARAMETERS")
                .font(.kinakoSectionHeader)
                .tracking(1.5)
                .foregroundStyle(KinakoColor.accentLavender)

            // Base Currency Picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Home Base Currency")
                    .font(.kinakoBody)
                    .foregroundStyle(KinakoColor.textPrimary)

                Text("All expenses and buffer pacing will normalize against this anchor currency.")
                    .font(.kinakoTelemetry)
                    .foregroundStyle(KinakoColor.textMuted)

                Picker("Base Currency", selection: $selectedBaseCurrency) {
                    ForEach(supportedCurrencies, id: \.self) { curr in
                        Text(curr).tag(curr)
                    }
                }
                .pickerStyle(.menu)
                .tint(KinakoColor.accentLavender)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(KinakoColor.canvasMidnight.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(KinakoColor.accentLavender.opacity(0.3), lineWidth: 0.8)
                )
            }

            Divider()
                .overlay(KinakoColor.canvasCard)

            // Monthly Discretionary Cap
            VStack(alignment: .leading, spacing: 6) {
                Text("Monthly Discretionary Cap")
                    .font(.kinakoBody)
                    .foregroundStyle(KinakoColor.textPrimary)

                Text("Maximum spend allocated per billing month for safe daily burn calculations.")
                    .font(.kinakoTelemetry)
                    .foregroundStyle(KinakoColor.textMuted)

                HStack {
                    Text(selectedBaseCurrency)
                        .font(.kinakoTelemetry)
                        .foregroundStyle(KinakoColor.textSecondary)

                    TextField("600", text: $monthlyCapString)
                        .keyboardType(.decimalPad)
                        .font(.kinakoCardAmount)
                        .foregroundStyle(KinakoColor.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(KinakoColor.canvasMidnight.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(KinakoColor.accentLavender.opacity(0.3), lineWidth: 0.8)
                )
            }

            Divider()
                .overlay(KinakoColor.canvasCard)

            // Net Hourly Wage
            VStack(alignment: .leading, spacing: 6) {
                Text("Effective Net Hourly Wage")
                    .font(.kinakoBody)
                    .foregroundStyle(KinakoColor.textPrimary)

                Text("Used to calculate Time-Cost Equivalency (converting price tags to working hours).")
                    .font(.kinakoTelemetry)
                    .foregroundStyle(KinakoColor.textMuted)

                HStack {
                    Text("\(selectedBaseCurrency) / hr")
                        .font(.kinakoTelemetry)
                        .foregroundStyle(KinakoColor.textSecondary)

                    TextField("25", text: $hourlyWageString)
                        .keyboardType(.decimalPad)
                        .font(.kinakoCardAmount)
                        .foregroundStyle(KinakoColor.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(KinakoColor.canvasMidnight.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(KinakoColor.accentLavender.opacity(0.3), lineWidth: 0.8)
                )
            }
        }
        .padding(20)
        .astralSurface(cut: 10, accentColor: KinakoColor.accentLavender)
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DATA & PRIVACY")
                .font(.kinakoSectionHeader)
                .tracking(1.5)
                .foregroundStyle(KinakoColor.textMuted)

            Text("Kinako is 100% offline-first. Historical exchange rates are frozen at transaction creation. Data is synced privately via your personal CloudKit container with zero external tracking servers.")
                .font(.kinakoTelemetry)
                .foregroundStyle(KinakoColor.textMuted)
                .lineSpacing(3)
        }
        .padding(20)
        .astralSurface(cut: 8, accentColor: KinakoColor.canvasCard, showGlow: false)
    }

    // MARK: - Actions

    private func loadCurrentSettings() {
        if let current = userSettingsList.first {
            selectedBaseCurrency = current.homeCurrencyCode
            monthlyCapString = "\(current.monthlyBudgetCap)"
            if let wage = current.effectiveHourlyWage {
                hourlyWageString = "\(wage)"
            }
        }
    }

    private func saveSettings() {
        KinakoHaptic.commit()
        let cap = Decimal(string: monthlyCapString) ?? 600
        let wage = Decimal(string: hourlyWageString)

        if let current = userSettingsList.first {
            current.homeCurrencyCode = selectedBaseCurrency
            current.monthlyBudgetCap = cap
            current.effectiveHourlyWage = wage
        } else {
            let newSettings = UserSettings(
                homeCurrencyCode: selectedBaseCurrency,
                activeDisplayCurrencyCode: selectedBaseCurrency,
                monthlyBudgetCap: cap,
                effectiveHourlyWage: wage
            )
            modelContext.insert(newSettings)
        }

        try? modelContext.save()
        showSavedAlert = true
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [UserSettings.self], inMemory: true)
}
