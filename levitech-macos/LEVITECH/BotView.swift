//
//  BotView.swift
//  KI-Roboter-Maskottchen, komplett in SwiftUI gezeichnet.
//

import SwiftUI

private struct Smile: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY),
                       control: CGPoint(x: r.midX, y: r.maxY))
        return p
    }
}

struct BotView: View {
    var size: CGFloat = 150
    @State private var float = false
    @State private var glow = false

    private var eye: some View {
        Ellipse()
            .fill(RadialGradient(colors: [Color(hex: 0xff6b76), Theme.red2, Theme.redDeep],
                                 center: .init(x: 0.5, y: 0.4), startRadius: 1, endRadius: 16))
            .frame(width: 26, height: 32)
            .overlay(
                Ellipse().fill(Color(hex: 0xffd0d4).opacity(0.9))
                    .frame(width: 10, height: 12).offset(y: -6)
            )
    }

    var body: some View {
        ZStack {
            // Glow
            Circle()
                .fill(RadialGradient(colors: [Theme.red.opacity(0.55), .clear],
                                     center: .center, startRadius: 8, endRadius: size * 0.8))
                .frame(width: size * 1.5, height: size * 1.5)
                .blur(radius: 10)
                .scaleEffect(glow ? 1.1 : 0.9)
                .opacity(glow ? 1 : 0.8)

            robot
                .frame(width: size, height: size)
                .offset(y: float ? -9 : 3)
        }
        .frame(width: size * 1.5, height: size * 1.5)
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) { float = true }
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) { glow = true }
        }
    }

    private var robot: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                // Antenne
                Rectangle().fill(Color(hex: 0x3a3a44))
                    .frame(width: 4, height: 20).offset(y: -w * 0.44)
                Circle().fill(Theme.red2).frame(width: 14, height: 14)
                    .shadow(color: Theme.red, radius: 6).offset(y: -w * 0.54)

                // Ohren
                Capsule().fill(Theme.redGrad).frame(width: 15, height: 42)
                    .offset(x: -w * 0.44)
                Capsule().fill(Theme.redGrad).frame(width: 15, height: 42)
                    .offset(x: w * 0.44)

                // Kopf
                RoundedRectangle(cornerRadius: w * 0.28)
                    .fill(LinearGradient(colors: [Color(hex: 0x2a2a33), Color(hex: 0x141419)],
                                         startPoint: .top, endPoint: .bottom))
                    .overlay(RoundedRectangle(cornerRadius: w * 0.28).stroke(Theme.redGrad, lineWidth: 2.5))
                    .frame(width: w * 0.82, height: w * 0.82)

                // Gesichtsfläche
                RoundedRectangle(cornerRadius: w * 0.2)
                    .fill(LinearGradient(colors: [Color(hex: 0x1a1a20), Color(hex: 0x0c0c0f)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.62, height: w * 0.52)
                    .offset(y: -w * 0.03)

                // Augen
                HStack(spacing: w * 0.14) { eye; eye }
                    .offset(y: -w * 0.05)

                // Mund
                Smile()
                    .stroke(Theme.red2.opacity(0.85), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: w * 0.22, height: w * 0.06)
                    .offset(y: w * 0.16)
            }
            .frame(width: w, height: geo.size.height)
        }
    }
}
