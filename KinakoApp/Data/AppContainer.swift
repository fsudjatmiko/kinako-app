//
//  AppContainer.swift
//  KinakoApp
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

import Foundation
import SwiftData

@MainActor
final class AppContainer {
    static let shared = AppContainer()
    let container: ModelContainer

    private init() {
        let schema = Schema([
            Transaction.self,
            CurrencyRateRecord.self,
            UserSettings.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.fsudjatmiko.KinakoApp")
        )

        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error.localizedDescription)")
        }
    }
}

