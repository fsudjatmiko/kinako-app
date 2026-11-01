//
//  ProfileView.swift
//  KinakoApp
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userSettingsList: [UserSettings]

    @AppStorage("selectedAppearance") private var selectedAppearance: String = "system"

    @State private var selectedBaseCurrency: String = "USD"
    @State private var monthlyCapString: String = "600"
    @State private var hourlyWageString: String = "25"
    @State private var showSavedAlert: Bool = false

    private let supportedCurrencies: [(code: String, name: String, flag: String)] = [
        ("USD", "US Dollar", "🇺🇸"),
        ("IDR", "Indonesian Rupiah", "🇮🇩"),
        ("EUR", "Euro", "🇪🇺"),
        ("JPY", "Japanese Yen", "🇯🇵"),
        ("GBP", "British Pound", "🇬🇧"),
        ("SGD", "Singapore Dollar", "🇸🇬"),
        ("AUD", "Australian Dollar", "🇦🇺"),
        ("CAD", "Canadian Dollar", "🇨🇦"),
        ("CHF", "Swiss Franc", "🇨🇭"),
        ("CNY", "Chinese Yuan", "🇨🇳"),
        ("KRW", "South Korean Won", "🇰🇷"),
        ("HKD", "Hong Kong Dollar", "🇭🇰"),
        ("NZD", "New Zealand Dollar", "🇳🇿"),
        ("MYR", "Malaysian Ringgit", "🇲🇾"),
        ("THB", "Thai Baht", "🇹🇭")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                KinakoColor.backgroundCanvas
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // User Profile Header Card
                        userProfileHeaderCard

                        // Section 1: Currency & Localization
                        currencySectionCard

                        // Section 2: Budget Targets
                        budgetSectionCard

                        // Section 3: Time-Cost Rate
                        timeCostSectionCard

                        // Section 4: Appearance & Backup
                        appearanceAndBackupCard

                        // Footer Version
                        appFooterView
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSettings()
                    }
                    .font(.helveticaTitle(size: 16, weight: .bold))
                    .foregroundStyle(KinakoColor.accentPrimary)
                }
            }
            .onAppear {
                loadCurrentSettings()
            }
            .alert("Profile Updated", isPresented: $showSavedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your financial parameters, base currency, and preferences have been saved.")
            }
        }
    }

    // MARK: - Subviews

    private var userProfileHeaderCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [KinakoColor.accentPrimary, KinakoColor.accentPrimary.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                Text("FS")
                    .font(.helveticaTitle(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Farrell")
                        .font(.helveticaTitle(size: 20, weight: .bold))
                        .foregroundStyle(KinakoColor.textPrimary)

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(KinakoColor.accentPrimary)
                }

                Text("Personal Discretionary Ledger")
                    .font(.helveticaBody(size: 13))
                    .foregroundStyle(KinakoColor.textSecondary)
            }

            Spacer()
        }
        .padding(18)
        .astralSurface(cut: 10, accentColor: KinakoColor.accentPrimary)
    }

    private var currencySectionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("CURRENCY & LOCALIZATION")
                .font(.helveticaTitle(size: 12, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(KinakoColor.accentPrimary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Home Base Currency")
                    .font(.helveticaTitle(size: 15, weight: .bold))
                    .foregroundStyle(KinakoColor.textPrimary)

                Text("All expenses and safe daily burn pace normalize against this anchor.")
                    .font(.helveticaBody(size: 13))
                    .foregroundStyle(KinakoColor.textSecondary)

                Menu {
                    ForEach(supportedCurrencies, id: \.code) { item in
                        Button {
                            selectedBaseCurrency = item.code
                            KinakoHaptic.keyPress()
                        } label: {
                            HStack {
                                Text("\(item.flag) \(item.code) — \(item.name)")
                                if item.code == selectedBaseCurrency {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        let selected = supportedCurrencies.first(where: { $0.code == selectedBaseCurrency })
                        Text(selected?.flag ?? "🌐")
                            .font(.system(size: 20))
                        Text(selectedBaseCurrency)
                            .font(.helveticaNumbers(size: 16, weight: .bold))
                            .foregroundStyle(KinakoColor.textPrimary)
                        Text(selected?.name ?? "")
                            .font(.helveticaBody(size: 13))
                            .foregroundStyle(KinakoColor.textSecondary)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(KinakoColor.accentPrimary)
                    }
                    .padding(12)
                    .background(KinakoColor.accentSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(KinakoColor.accentPrimary.opacity(0.3), lineWidth: 0.8)
                    )
                }
            }
        }
        .padding(18)
        .astralSurface(cut: 10, accentColor: KinakoColor.cardSurface, showGlow: false)
    }

    private var budgetSectionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("BUDGET TARGETS")
                .font(.helveticaTitle(size: 12, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(KinakoColor.accentPrimary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Monthly Discretionary Budget")
                    .font(.helveticaTitle(size: 15, weight: .bold))
                    .foregroundStyle(KinakoColor.textPrimary)

                Text("Discretionary allowance for safe daily pacing and guilt-free burn.")
                    .font(.helveticaBody(size: 13))
                    .foregroundStyle(KinakoColor.textSecondary)

                HStack {
                    Text(selectedBaseCurrency)
                        .font(.helveticaTitle(size: 14, weight: .bold))
                        .foregroundStyle(KinakoColor.accentPrimary)

                    TextField("600", text: $monthlyCapString)
                        .keyboardType(.decimalPad)
                        .font(.helveticaNumbers(size: 18, weight: .bold))
                        .foregroundStyle(KinakoColor.textPrimary)
                }
                .padding(12)
                .background(KinakoColor.accentSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(KinakoColor.accentPrimary.opacity(0.3), lineWidth: 0.8)
                )
            }
        }
        .padding(18)
        .astralSurface(cut: 10, accentColor: KinakoColor.cardSurface, showGlow: false)
    }

    private var timeCostSectionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("TIME-COST RATE")
                .font(.helveticaTitle(size: 12, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(KinakoColor.accentPrimary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Effective Net Hourly Wage")
                    .font(.helveticaTitle(size: 15, weight: .bold))
                    .foregroundStyle(KinakoColor.textPrimary)

                Text("We calculate how many hours you work to pay for each purchase to curb impulsive decisions.")
                    .font(.helveticaBody(size: 13))
                    .foregroundStyle(KinakoColor.textSecondary)

                HStack {
                    Text("\(selectedBaseCurrency) / hr")
                        .font(.helveticaTitle(size: 14, weight: .bold))
                        .foregroundStyle(KinakoColor.accentPrimary)

                    TextField("25", text: $hourlyWageString)
                        .keyboardType(.decimalPad)
                        .font(.helveticaNumbers(size: 18, weight: .bold))
                        .foregroundStyle(KinakoColor.textPrimary)
                }
                .padding(12)
                .background(KinakoColor.accentSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(KinakoColor.accentPrimary.opacity(0.3), lineWidth: 0.8)
                )
            }
        }
        .padding(18)
        .astralSurface(cut: 10, accentColor: KinakoColor.cardSurface, showGlow: false)
    }

    private var appearanceAndBackupCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("APPEARANCE & BACKUP")
                .font(.helveticaTitle(size: 12, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(KinakoColor.accentPrimary)

            // Appearance Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Theme Appearance")
                    .font(.helveticaTitle(size: 15, weight: .bold))
                    .foregroundStyle(KinakoColor.textPrimary)

                Picker("Theme Appearance", selection: $selectedAppearance) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
            }

            Divider()
                .overlay(KinakoColor.accentSubtle)

            // CloudKit Status
            HStack(spacing: 12) {
                Image(systemName: "icloud.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(KinakoColor.accentPrimary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("CloudKit Sync Active")
                        .font(.helveticaTitle(size: 14, weight: .bold))
                        .foregroundStyle(KinakoColor.textPrimary)

                    Text("Private Apple Database • 100% Offline-First")
                        .font(.helveticaBody(size: 12))
                        .foregroundStyle(KinakoColor.textSecondary)
                }

                Spacer()

                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(18)
        .astralSurface(cut: 10, accentColor: KinakoColor.cardSurface, showGlow: false)
    }

    private var appFooterView: some View {
        VStack(spacing: 4) {
            Text("Kinako v1.0")
                .font(.helveticaTitle(size: 13, weight: .bold))
                .foregroundStyle(KinakoColor.textSecondary)

            Text("Private, offline-first personal finance with CloudKit mirroring.")
                .font(.helveticaBody(size: 11))
                .foregroundStyle(KinakoColor.textSecondary.opacity(0.8))
        }
        .padding(.vertical, 16)
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
    ProfileView()
        .modelContainer(for: [UserSettings.self], inMemory: true)
}

