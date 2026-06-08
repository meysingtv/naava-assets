import SwiftUI

struct MaterialCalculatorView: View {
    @State private var laenge: Double   = 10
    @State private var breite: Double   = 8
    @State private var neigung: Double  = 35
    @State private var dachtyp: DachTyp = .satteldach
    @State private var deckung: Deckung = .tonziegel
    @State private var mitDaemmung      = true

    // MARK: - Supporting types

    enum DachTyp: String, CaseIterable {
        case satteldach = "Satteldach"
        case pultdach   = "Pultdach"
        case walmdach   = "Walmdach"
        case flachdach  = "Flachdach"

        var isFlat: Bool { self == .flachdach }
    }

    enum Deckung: String, CaseIterable {
        case tonziegel    = "Tonziegel"
        case betonziegel  = "Betonziegel"
        case biberschwanz = "Biberschwanz"
        case schiefer     = "Schiefer"

        var stueckProM2: Double {
            switch self {
            case .tonziegel:    return 12
            case .betonziegel:  return 11
            case .biberschwanz: return 28
            case .schiefer:     return 20
            }
        }
        var preisProStueck: Double {
            switch self {
            case .tonziegel:    return 1.40
            case .betonziegel:  return 1.10
            case .biberschwanz: return 2.50
            case .schiefer:     return 3.80
            }
        }
        var lattenAbstandMM: Double {
            switch self {
            case .tonziegel:    return 320
            case .betonziegel:  return 330
            case .biberschwanz: return 145
            case .schiefer:     return 200
            }
        }
    }

    // MARK: - Calculations

    private var neigungsRad: Double { neigung * .pi / 180 }

    private var dachFlaeche: Double {
        dachtyp.isFlat ? laenge * breite : laenge * breite / cos(neigungsRad)
    }

    private var ziegelStueck: Int    { Int(ceil(dachFlaeche * 1.10 * deckung.stueckProM2)) }
    private var ziegelKosten: Double { Double(ziegelStueck) * deckung.preisProStueck }

    private var lattungMeter: Double { dachFlaeche / (deckung.lattenAbstandMM / 1000) * 1.05 }
    private var lattungKosten: Double { lattungMeter * 2.80 }

    private var spannbahnM2: Double    { dachFlaeche * 1.15 }
    private var spannbahnKosten: Double { spannbahnM2 * 3.20 }

    private var daemmungM2: Double    { dachFlaeche }
    private var daemmungKosten: Double { mitDaemmung ? daemmungM2 * 18.50 : 0 }

    private var materialGesamt: Double { ziegelKosten + lattungKosten + spannbahnKosten + daemmungKosten }
    private var arbeitRichwert: Double { dachFlaeche * 45 }
    private var gesamtNetto: Double    { materialGesamt + arbeitRichwert }
    private var gesamtBrutto: Double   { gesamtNetto * 1.19 }

    // MARK: - Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                inputCard
                if dachFlaeche > 0 {
                    flaecheCard
                    materialCard
                    kostenCard
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Color.appBackground)
        .navigationTitle("Materialrechner")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: - Input card

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("DACHPARAMETER")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.appTextSecondary)
                .kerning(0.6)

            chipPicker("Dachtyp", options: DachTyp.allCases, selection: $dachtyp)
            dimSlider("Länge", value: $laenge, range: 3...60, unit: "m")
            dimSlider("Breite", value: $breite, range: 3...30, unit: "m")

            if !dachtyp.isFlat {
                dimSlider("Neigung", value: $neigung, range: 10...60, unit: "°", step: 1)
                chipPicker("Eindeckung", options: Deckung.allCases, selection: $deckung)
            }

            Toggle(isOn: $mitDaemmung) {
                Text("Dämmmaterial einrechnen")
                    .font(.system(size: 14))
                    .foregroundColor(.appTextPrimary)
            }
            .tint(.appBlue)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    private func chipPicker<T: RawRepresentable & Hashable>(
        _ title: String,
        options: [T],
        selection: Binding<T>
    ) -> some View where T.RawValue == String {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.appTextSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(options, id: \.self) { opt in
                        Button(action: { selection.wrappedValue = opt }) {
                            Text(opt.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(selection.wrappedValue == opt ? .white : .appTextSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(selection.wrappedValue == opt ? Color.appBlue : Color.appBackground)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }

    private func dimSlider(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        unit: String,
        step: Double = 0.5
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.appTextSecondary)
                Spacer()
                Text("\(fmt(value.wrappedValue)) \(unit)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.appTextPrimary)
            }
            Slider(value: value, in: range, step: step).tint(.appBlue)
        }
    }

    // MARK: - Fläche card

    private var flaecheCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("DACHFLÄCHE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.appTextSecondary)
                    .kerning(0.6)
                Spacer()
            }
            .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 12)

            HStack(spacing: 0) {
                areaCell("Grundfläche",  "\(fmt(laenge * breite)) m²", .appBlue)
                Divider()
                areaCell("Dachfläche",   "\(fmt(dachFlaeche)) m²",    .appOrange)
                if !dachtyp.isFlat {
                    Divider()
                    areaCell("Neigung", "\(Int(neigung))°",              .appGreen)
                }
            }
            .padding(.bottom, 14)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    private func areaCell(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 17, weight: .bold)).foregroundColor(color)
            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Material card

    private var materialCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("MATERIALMENGEN")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.appTextSecondary)
                    .kerning(0.6)
                Spacer()
                Text("+10% Verschnitt inkl.")
                    .font(.system(size: 10))
                    .foregroundColor(.appTextSecondary)
            }
            .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 10)

            if !dachtyp.isFlat {
                matRow("square.grid.2x2.fill", .appOrange,
                       label: deckung.rawValue,
                       sub: "\(Int(deckung.stueckProM2)) Stk./m²",
                       val: "\(ziegelStueck) Stk.",
                       cost: Invoice.format(ziegelKosten))
                Divider().padding(.leading, 52)
                matRow("line.3.horizontal", .appBlue,
                       label: "Dachlattung",
                       sub: "Fichte, \(Int(deckung.lattenAbstandMM)) mm Abstand",
                       val: "\(fmt(lattungMeter)) m",
                       cost: Invoice.format(lattungKosten))
                Divider().padding(.leading, 52)
            }

            matRow("rectangle.fill", .appGreen,
                   label: "Unterspannbahn",
                   sub: "inkl. 15% Überlappung",
                   val: "\(fmt(spannbahnM2)) m²",
                   cost: Invoice.format(spannbahnKosten))

            if mitDaemmung {
                Divider().padding(.leading, 52)
                matRow("thermometer.medium", .appPurple,
                       label: "Dämmmaterial",
                       sub: "z.B. Glaswolle 160 mm WLG 035",
                       val: "\(fmt(daemmungM2)) m²",
                       cost: Invoice.format(daemmungKosten))
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    private func matRow(
        _ icon: String, _ color: Color,
        label: String, sub: String,
        val: String, cost: String
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.system(size: 14, weight: .semibold)).foregroundColor(.appTextPrimary)
                Text(sub).font(.system(size: 11)).foregroundColor(.appTextSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text(val).font(.system(size: 13, weight: .bold)).foregroundColor(.appTextPrimary)
                Text(cost).font(.system(size: 11)).foregroundColor(.appTextSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    // MARK: - Kosten card

    private var kostenCard: some View {
        VStack(spacing: 8) {
            HStack {
                Text("KOSTENSCHÄTZUNG")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.appTextSecondary)
                    .kerning(0.6)
                Spacer()
            }
            .padding(.bottom, 4)

            kostenRow("Material gesamt",       Invoice.format(materialGesamt), false)
            kostenRow("Arbeitszeit (Richtwert)", Invoice.format(arbeitRichwert), false)
            Divider()
            kostenRow("Netto",   Invoice.format(gesamtNetto),          false)
            kostenRow("MwSt. 19%", Invoice.format(gesamtNetto * 0.19), false)
            Divider()

            HStack {
                Text("Gesamt brutto (ca.)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                Spacer()
                Text(Invoice.format(gesamtBrutto))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.appGreen)
            }

            Text("* Schätzwerte für Planung — individuelle Preise können je nach Region und Lieferant abweichen")
                .font(.system(size: 10))
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    private func kostenRow(_ label: String, _ value: String, _ bold: Bool) -> some View {
        HStack {
            Text(label).font(.system(size: 14)).foregroundColor(.appTextSecondary)
            Spacer()
            Text(value).font(.system(size: 14)).foregroundColor(.appTextPrimary)
        }
    }

    private func fmt(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(v))" : String(format: "%.1f", v)
    }
}

#Preview {
    NavigationStack { MaterialCalculatorView() }
}
