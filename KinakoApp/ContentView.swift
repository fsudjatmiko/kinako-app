//
//  ContentView.swift
//  KinakoApp
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        RootTabView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Transaction.self, CurrencyRateRecord.self, UserSettings.self], inMemory: true)
}
