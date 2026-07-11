//
//  Theme.swift
//  Farben & wiederverwendbare Stile (Dark / Rot)
//

import SwiftUI

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8) & 0xff) / 255,
                  blue: Double(hex & 0xff) / 255,
                  opacity: alpha)
    }
}

enum Theme {
    static let bg        = Color(hex: 0x0a0a0c)
    static let surface   = Color(hex: 0x16161c)
    static let surface2  = Color(hex: 0x1c1c23)
    static let surface3  = Color(hex: 0x23232b)
    static let line      = Color.white.opacity(0.08)
    static let lineStrong = Color.white.opacity(0.12)

    static let text  = Color(hex: 0xf4f4f6)
    static let text2 = Color(hex: 0xa6a6b0)
    static let text3 = Color(hex: 0x6e6e78)

    static let red   = Color(hex: 0xe51f2e)
    static let red2  = Color(hex: 0xff3546)
    static let redDeep = Color(hex: 0xb0101c)
    static let green = Color(hex: 0x2ecb6e)
    static let amber = Color(hex: 0xff9f2e)
    static let yellow = Color(hex: 0xf5c518)
    static let blue  = Color(hex: 0x3d8bff)
    static let gray  = Color(hex: 0x7a7a84)

    static let redGrad = LinearGradient(
        colors: [Color(hex: 0xff3546), Color(hex: 0xd4141f), Color(hex: 0xa50f18)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let redGlow = Color(hex: 0xe51f2e).opacity(0.35)
}
