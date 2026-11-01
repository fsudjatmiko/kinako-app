//
//  KinakoAppUITests.swift
//  KinakoAppUITests
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

import XCTest

final class KinakoAppUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testExample() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui_testing_mode"]
        app.launch()
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchArguments = ["-ui_testing_mode"]
            app.launch()
        }
    }
}
