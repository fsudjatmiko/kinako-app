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
                    Label("Splits", systemImage: "person.2.fill")
                }
                .tag(1)

            RegretAuditView()
                .tabItem {
                    Label("Audits", systemImage: "sparkles")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(KinakoColor.accentLavender)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [Transaction.self, CurrencyRateRecord.self, UserSettings.self], inMemory: true)
}

