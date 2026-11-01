//
//  TestModelContainerFactory.swift
//  KinakoAppTests
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

import Foundation
import SwiftData
@testable import KinakoApp

@MainActor
public struct TestModelContainerFactory {
    public static func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            Transaction.self,
            CurrencyRateRecord.self,
            UserSettings.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )

        return try ModelContainer(for: schema, configurations: [configuration])
    }
}

