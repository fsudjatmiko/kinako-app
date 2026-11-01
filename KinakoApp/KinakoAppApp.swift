//
//  KinakoAppApp.swift
//  KinakoApp
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

import SwiftUI
import SwiftData

@main
struct KinakoAppApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(AppContainer.shared.container)
    }
}
