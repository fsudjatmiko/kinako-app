//
//  RootTabView.swift
//  KinakoApp
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

import SwiftUI
import SwiftData

struct RootTabView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Ledger", systemImage: "creditcard.fill")
                }
                .tag(0)

            GhostSplitView()
                .tabItem {
                    Label("Shared Bills", systemImage: "person.2.fill")
                }
                .tag(1)

            RegretAuditView()
                .tabItem {
                    Label("Spending Insights", systemImage: "sparkles")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
                .tag(3)
        }
        .tint(KinakoColor.accentPrimary)
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [Transaction.self, CurrencyRateRecord.self, UserSettings.self], inMemory: true)
}
