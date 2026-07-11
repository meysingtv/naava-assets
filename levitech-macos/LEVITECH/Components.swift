//
//  Components.swift
//  Wiederverwendbare UI-Bausteine (Karten, Badges, Ring, Buttons …)
//

import SwiftUI

// MARK: - Karte

struct Card<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content() }
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Badge / Pill

struct Pill: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

// MARK: - Roter Button

struct RedButton: View {
    let title: String
    var systemImage: String? = nil
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let s = systemImage { Image(systemName: s) }
                Text(title)
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Theme.redGrad)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Theme.redGlow, radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }
}

struct GhostButton: View {
    let title: String
    var systemImage: String? = nil
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let s = systemImage { Image(systemName: s) }
                Text(title)
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(Theme.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Theme.surface2)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.lineStrong, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section-Kopf

struct SectionHead: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(Theme.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 2)
    }
}

// MARK: - Stat-Kachel

struct StatTile: View {
    let n: String
    let label: String
    var color: Color = Theme.text
    var body: some View {
        VStack(spacing: 4) {
            Text(n).font(.system(size: 24, weight: .bold)).foregroundColor(color)
            Text(label).font(.system(size: 10.5)).foregroundColor(Theme.text2)
                .multilineTextAlignment(.center).lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12).padding(.horizontal, 6)
        .background(Theme.surface)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Fortschritts-Ring

struct ProgressRing: View {
    let pct: Int
    var sub: String = ""
    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.08), lineWidth: 8)
            Circle()
                .trim(from: 0, to: CGFloat(pct) / 100)
                .stroke(Theme.red, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 1) {
                Text("\(pct)%").font(.system(size: 18, weight: .bold)).foregroundColor(Theme.text)
                if !sub.isEmpty {
                    Text(sub).font(.system(size: 9)).foregroundColor(Theme.text2)
                }
            }
        }
        .frame(width: 84, height: 84)
    }
}

// MARK: - Listenzeile (Icon · Label · Wert)

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    var valueColor: Color = Theme.text
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).foregroundColor(Theme.text2).frame(width: 22)
            Text(label).font(.system(size: 14)).foregroundColor(Theme.text2)
            Spacer()
            Text(value).font(.system(size: 15, weight: .bold)).foregroundColor(valueColor)
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Kontaktzeile

struct ContactRow: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 13)).foregroundColor(Theme.text3).frame(width: 18)
            Text(text).font(.system(size: 14)).foregroundColor(Theme.text)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 5)
    }
}

// MARK: - Tabs (Segment)

struct SegTabs: View {
    let items: [String]
    @Binding var selection: Int
    var body: some View {
        HStack(spacing: 6) {
            ForEach(items.indices, id: \.self) { i in
                Text(items[i])
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(i == selection ? .white : Theme.text2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(i == selection ? AnyView(Theme.redGrad) : AnyView(Color.clear))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .contentShape(Rectangle())
                    .onTapGesture { withAnimation(.easeOut(duration: 0.15)) { selection = i } }
            }
        }
        .padding(4)
        .background(Theme.surface2)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Runde Icon-Schaltfläche

struct IconButton: View {
    let system: String
    var action: () -> Void = {}
    var body: some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Theme.text)
                .frame(width: 40, height: 40)
                .background(Theme.surface2)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - App-Header (Logo + Avatar)

struct BrandHeader: View {
    var badge: Int? = nil
    var body: some View {
        HStack {
            HStack(spacing: 10) {
                Text("Ł")
                    .font(.system(size: 22, weight: .black, design: .serif)).italic()
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Theme.redGrad)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Theme.redGlow, radius: 10, y: 4)
                Text("LEVITECH")
                    .font(.system(size: 22, weight: .heavy)).tracking(3)
                    .foregroundColor(Theme.text)
            }
            Spacer()
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: 0x3a3a44), Color(hex: 0x22222a)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 44)
                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 2))
                    .overlay(Image(systemName: "person.fill").foregroundColor(Theme.text2))
                if let b = badge {
                    Text("\(b)")
                        .font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                        .frame(minWidth: 20, minHeight: 20)
                        .background(Theme.red)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Theme.bg, lineWidth: 2))
                        .offset(x: 4, y: -4)
                }
            }
        }
    }
}

// MARK: - Große Seitenüberschrift

struct PageTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 26, weight: .heavy))
            .foregroundColor(Theme.text)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Suchleiste

struct SearchBar: View {
    var placeholder: String = "Suchen"
    @Binding var text: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundColor(Theme.text3)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .foregroundColor(Theme.text)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(Theme.surface)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
