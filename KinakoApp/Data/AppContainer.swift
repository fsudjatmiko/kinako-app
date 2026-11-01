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

        let isTesting = NSClassFromString("XCTestCase") != nil ||
            ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
            ProcessInfo.processInfo.arguments.contains("-ui_testing_mode")

        #if targetEnvironment(simulator)
        let isSimulator = true
        #else
        let isSimulator = false
        #endif

        if isTesting {
            let testConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
            do {
                container = try ModelContainer(for: schema, configurations: [testConfig])
                return
            } catch {
                fatalError("Failed to initialize test SwiftData container: \(error.localizedDescription)")
            }
        }

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: isSimulator ? .none : .private("iCloud.com.fsudjatmiko.KinakoApp")
        )

        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
            if let fallback = try? ModelContainer(for: schema, configurations: [fallbackConfig]) {
                container = fallback
            } else {
                fatalError("Failed to initialize SwiftData container: \(error.localizedDescription)")
            }
        }
    }
}
