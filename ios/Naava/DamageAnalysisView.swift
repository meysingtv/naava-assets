import SwiftUI
import PhotosUI

struct DamageReport {
    let schadenstyp: String
    let beschreibung: String
    let massnahmen: [String]
    let kostenSchaetzung: String
    let dringlichkeit: String
    let zeitrahmen: String
}

struct DamageAnalysisView: View {
    var onAddToOrder: ((String) -> Void)? = nil

    @State private var pickerItem: PhotosPickerItem?
    @State private var image: UIImage?
    @State private var report: DamageReport?
    @State private var loading = false
    @State private var errorMsg: String?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var toast: ToastManager
    private let ai = AIService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    photoPicker
                    if let img = image {
                        previewImage(img)
                        if report == nil && !loading { analyzeButton }
                    }
                    if loading  { loadingView  }
                    if let e = errorMsg { errorView(e) }
                    if let r = report  { reportCard(r) }
                }
                .padding(16)
            }
            .background(Color.appBackground)
            .navigationTitle("KI-Schadenserkennung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }.foregroundColor(.appBlue)
                }
            }
        }
        .onChange(of: pickerItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let ui   = UIImage(data: data) {
                    image    = ui
                    report   = nil
                    errorMsg = nil
                }
            }
        }
    }

    // MARK: - Photo Picker

    private var photoPicker: some View {
        PhotosPicker(selection: $pickerItem, matching: .images) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.appOrange.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.appOrange)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(image == nil ? "Foto auswählen" : "Foto ändern")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                    Text("Mache ein Foto vom Dachschaden")
                        .font(.system(size: 12))
                        .foregroundColor(.appTextSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.appTextSecondary.opacity(0.4))
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
    }

    // MARK: - Preview

    private func previewImage(_ img: UIImage) -> some View {
        Image(uiImage: img)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .clipped()
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }

    // MARK: - Analyze button

    private var analyzeButton: some View {
        Button(action: analyze) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .semibold))
                Text("KI-Analyse starten")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [Color.appOrange, Color(red: 1.0, green: 0.45, blue: 0.2)],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .cornerRadius(14)
            .shadow(color: Color.appOrange.opacity(0.4), radius: 8, x: 0, y: 4)
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView().scaleEffect(1.2).tint(.appOrange)
            Text("KI analysiert das Foto…")
                .font(.system(size: 13))
                .foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Error

    private func errorView(_ msg: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(msg)
                .font(.system(size: 13))
                .foregroundColor(.red)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Color.red.opacity(0.07))
        .cornerRadius(10)
    }

    // MARK: - Report

    private func reportCard(_ rep: DamageReport) -> some View {
        VStack(spacing: 10) {

            // Title + urgency
            HStack(spacing: 10) {
                urgencyBadge(rep.dringlichkeit)
                VStack(alignment: .leading, spacing: 2) {
                    Text(rep.schadenstyp)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                    Text(rep.zeitrahmen)
                        .font(.system(size: 12))
                        .foregroundColor(.appTextSecondary)
                }
                Spacer()
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(14)

            // Description
            infoTile(icon: "text.alignleft", label: "Schadensbeschreibung") {
                Text(rep.beschreibung)
                    .font(.system(size: 14))
                    .foregroundColor(.appTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Measures
            infoTile(icon: "wrench.and.screwdriver.fill", label: "Empfohlene Maßnahmen") {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(rep.massnahmen.indices, id: \.self) { i in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(i + 1).")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.appOrange)
                                .frame(width: 18, alignment: .leading)
                            Text(rep.massnahmen[i])
                                .font(.system(size: 13))
                                .foregroundColor(.appTextPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            // Cost + action
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("KOSTEN CA.")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.appTextSecondary)
                        .kerning(0.5)
                    Text(rep.kostenSchaetzung)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                }
                Spacer()
                if let onAdd = onAddToOrder {
                    Button(action: {
                        let note = "[\(rep.schadenstyp)] \(rep.beschreibung)\nMaßnahmen: \(rep.massnahmen.joined(separator: " / "))\nGeschätzte Kosten: \(rep.kostenSchaetzung)"
                        onAdd(note)
                        toast.show("Zur Auftragsnotiz hinzugefügt", style: .success, icon: "checkmark.circle.fill")
                        dismiss()
                    }) {
                        Label("Zu Auftrag", systemImage: "plus.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.appGreen)
                            .cornerRadius(10)
                    }
                }
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(14)
        }
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    // MARK: - Helpers

    private func urgencyBadge(_ level: String) -> some View {
        let color: Color = level == "Hoch" ? .red : level == "Mittel" ? .appOrange : .appGreen
        return Text(level)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .cornerRadius(6)
    }

    private func infoTile<C: View>(icon: String, label: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.appTextSecondary)
                .kerning(0.4)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    // MARK: - Analyze

    private func analyze() {
        guard let img  = image,
              let jpeg = img.jpegData(compressionQuality: 0.75) else { return }
        loading  = true
        errorMsg = nil

        Task {
            do {
                let raw = try await ai.analyzeImage(jpeg, prompt: AIPrompts.damageAnalysis)

                let cleaned = raw
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "```json", with: "")
                    .replacingOccurrences(of: "```", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard
                    let data = cleaned.data(using: .utf8),
                    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                else {
                    errorMsg = "Analyse konnte nicht gelesen werden. Bitte erneut versuchen."
                    loading  = false
                    return
                }

                report = DamageReport(
                    schadenstyp:      json["schadenstyp"]      as? String   ?? "Unbekannter Schaden",
                    beschreibung:     json["beschreibung"]     as? String   ?? "",
                    massnahmen:       json["massnahmen"]       as? [String] ?? [],
                    kostenSchaetzung: json["kostenSchaetzung"] as? String   ?? "k.A.",
                    dringlichkeit:    json["dringlichkeit"]    as? String   ?? "Mittel",
                    zeitrahmen:       json["zeitrahmen"]       as? String   ?? ""
                )
            } catch {
                errorMsg = error.localizedDescription
            }
            loading = false
        }
    }
}

#Preview {
    DamageAnalysisView()
        .environmentObject(ToastManager())
}
