import SwiftUI

struct SignatureView: View {
    let customerName: String
    let orderNumber: String
    var onSave: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var lines: [[CGPoint]] = []
    @State private var currentLine: [CGPoint] = []
    @State private var canvasSize: CGSize = .zero
    @State private var saved = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                infoStrip
                Divider()
                canvas
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                Divider()
                customerBar
                actionBar
            }
            .background(Color.appBackground)
            .navigationTitle("Kundenunterschrift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Info strip

    private var infoStrip: some View {
        VStack(spacing: 3) {
            Text(orderNumber)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.appTextSecondary)
            Text("Auftrag bestätigen und unterschreiben")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.appTextPrimary)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color.appBackground)
    }

    // MARK: - Drawing canvas

    private var canvas: some View {
        ZStack {
            Color.white

            Canvas { ctx, _ in
                for line in lines + [currentLine] {
                    guard line.count > 1 else { continue }
                    var path = Path()
                    path.move(to: line[0])
                    for pt in line.dropFirst() { path.addLine(to: pt) }
                    ctx.stroke(path, with: .color(.black),
                               style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }
            }
            .background(
                GeometryReader { geo in
                    Color.clear.onAppear { canvasSize = geo.size }
                }
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in currentLine.append(v.location) }
                    .onEnded   { _  in lines.append(currentLine); currentLine = [] }
            )

            if lines.isEmpty && currentLine.isEmpty {
                Text("Bitte hier unterschreiben")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.gray.opacity(0.28))
                    .allowsHitTesting(false)
            }

            VStack {
                Spacer()
                Rectangle()
                    .fill(Color.gray.opacity(0.22))
                    .frame(height: 1)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 52)
            }
            .allowsHitTesting(false)
        }
    }

    // MARK: - Customer bar

    private var customerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(customerName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                Text(Date().formatted(
                    .dateTime.day().month().year().locale(Locale(identifier: "de_DE"))
                ))
                .font(.system(size: 12))
                .foregroundColor(.appTextSecondary)
            }
            Spacer()
            Button(action: { lines = []; currentLine = [] }) {
                Label("Löschen", systemImage: "arrow.counterclockwise")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.appTextSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.appBackground)
                    .cornerRadius(8)
            }
            .disabled(lines.isEmpty && currentLine.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
    }

    // MARK: - Action bar

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button("Abbrechen") { dismiss() }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.appTextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appTextSecondary.opacity(0.2)))

            Button(action: saveSignature) {
                HStack(spacing: 6) {
                    Image(systemName: saved ? "checkmark.circle.fill" : "signature")
                    Text(saved ? "Gespeichert!" : "Unterschrift speichern")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(lines.isEmpty ? Color.gray.opacity(0.3) : Color.appBlue)
                .cornerRadius(12)
            }
            .disabled(lines.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.appBackground)
    }

    // MARK: - Save

    private func saveSignature() {
        guard !canvasSize.width.isZero else { return }
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, 2.0)
        defer { UIGraphicsEndImageContext() }
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        UIColor.white.setFill()
        ctx.fill(CGRect(origin: .zero, size: canvasSize))

        ctx.setStrokeColor(UIColor.black.cgColor)
        ctx.setLineWidth(1.5)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)

        for line in lines {
            guard line.count > 1 else { continue }
            ctx.beginPath()
            ctx.move(to: line[0])
            for pt in line.dropFirst() { ctx.addLine(to: pt) }
            ctx.strokePath()
        }

        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            onSave(image)
        }
        saved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { dismiss() }
    }
}

#Preview {
    SignatureView(customerName: "Klaus Müller", orderNumber: "AU-2026-012") { _ in }
}
