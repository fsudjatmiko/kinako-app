//
//  SandalphonChamfer.swift
//  KinakoApp
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

import SwiftUI

public struct SandalphonChamfer: Shape {
    public var cut: CGFloat

    public init(cut: CGFloat = 10) {
        self.cut = cut
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let c = min(cut, min(rect.width, rect.height) / 2)

        path.move(to: CGPoint(x: c, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX - c, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: c))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - c))
        path.addLine(to: CGPoint(x: rect.maxX - c, y: rect.maxY))
        path.addLine(to: CGPoint(x: c, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: rect.maxY - c))
        path.addLine(to: CGPoint(x: 0, y: c))
        path.closeSubpath()
        return path
    }
}

