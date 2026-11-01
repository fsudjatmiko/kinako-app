//
//  KinakoFeedback.swift
//  KinakoApp
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

import SwiftUI
import UIKit

public extension Animation {
    /// Crisp, high-tension spring for sheets, cards, and numeric counter hops
    static let kinakoSnap = Animation.spring(response: 0.28, dampingFraction: 0.68, blendDuration: 0)

    /// Slash effect spring when completing a transaction or checking off an audit
    static let kinakoSlash = Animation.interpolatingSpring(mass: 0.4, stiffness: 220, damping: 14)
}

@MainActor
public enum KinakoHaptic {
    /// Standard keypress on numeric entry pad
    public static func keyPress() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.7)
    }

    /// Slash commit when logging a transaction
    public static func commit() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 1.0)
    }

    /// Deficit warning or budget breach
    public static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

