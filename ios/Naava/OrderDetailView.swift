import SwiftUI
import PhotosUI

struct OrderDetailView: View {
    @State private var order: Order
    var onUpdate: (Order) -> Void

    @State private var photos: [UIImage] = []
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showStatusPicker = false
    @State private var showDamageAnalysis = false
    @State private var showSignature = false
    @State private var signatureImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var toast: ToastManager

    init(order: Order, onUpdate: @escaping (Order) -> Void) {
        _order = State(initialValue: order)
        self.onUpdate = onUpdate
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                statusHeader
                infoCard
                if !order.description.isEmpty { descriptionCard }
                photosSection
                signatureSection
                notesCard
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
        .background(Color.appBackground)
        .navigationTitle(order.number)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showStatusPicker = true }) {
                    Text("Status")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appBlue)
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showDamageAnalysis) {
            DamageAnalysisView { analysisNote in
                order.notes = order.notes.isEmpty ? analysisNote : order.notes + "\n\n" + analysisNote
                onUpdate(order)
            }
            .environmentObject(toast)
        }
        .sheet(isPresented: $showSignature) {
            SignatureView(customerName: order.customerName, orderNumber: order.number) { image in
                signatureImage = image
                toast.show("Unterschrift gespeichert", style: .success, icon: "signature")
            }
        }
        .confirmationDialog("Status ändern", isPresented: $showStatusPicker, titleVisibility: .visible) {
            ForEach(OrderStatus.allCases, id: \.self) { s in
                Button(s.rawValue) { order.status = s; onUpdate(order) }
            }
        }
        .onChange(of: selectedItems) { _, items in
            Task {
                var loaded: [UIImage] = []
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) { loaded.append(img) }
                }
                photos.append(contentsOf: loaded)
                selectedItems = []
            }
        }
    }

    // MARK: - Status header
    private var statusHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(order.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                Text(order.customerName)
                    .font(.system(size: 14))
                    .foregroundColor(.appTextSecondary)
            }
            Spacer()
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(order.status.color.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: order.status.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(order.status.color)
                }
                Text(order.status.rawValue)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(order.status.color)
            }
        }
        .padding(16)
        .cardStyle()
        .padding(.top, 4)
    }

    // MARK: - Info card
    private var infoCard: some View {
        VStack(spacing: 0) {
            infoRow(icon: "mappin.fill",   color: .appOrange, title: "Adresse",   value: order.address)
            Divider().padding(.leading, 50)
            infoRow(icon: "calendar",       color: .appBlue,   title: "Datum",     value: order.date.formatted(date: .long, time: .omitted))
            if let h = order.estimatedHours {
                Divider().padding(.leading, 50)
                infoRow(icon: "clock.fill", color: .appGreen,  title: "Geschätzt", value: "\(Int(h)) Stunden")
            }
        }
        .cardStyle()
    }

    private func infoRow(icon: String, color: Color, title: String, value: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.appTextSecondary)
                Text(value)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.appTextPrimary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    // MARK: - Description
    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Beschreibung", systemImage: "doc.text")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.appTextSecondary)
                .textCase(.uppercase)
            Text(order.description)
                .font(.system(size: 14))
                .foregroundColor(.appTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .cardStyle()
    }

    // MARK: - Photos
    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("FOTOS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.appTextSecondary)
                    .kerning(0.6)
                Spacer()
                Button(action: { showDamageAnalysis = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .bold))
                        Text("Schaden analysieren")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.appOrange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.appOrange.opacity(0.1))
                    .cornerRadius(8)
                }
                PhotosPicker(selection: $selectedItems, maxSelectionCount: 20, matching: .images) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                        Text("Hinzufügen")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.appBlue)
                }
            }

            if photos.isEmpty {
                Button(action: {}) {
                    PhotosPicker(selection: $selectedItems, maxSelectionCount: 20, matching: .images) {
                        VStack(spacing: 10) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.appTextSecondary.opacity(0.4))
                            Text("Fotos aufnehmen oder aus Galerie wählen")
                                .font(.system(size: 13))
                                .foregroundColor(.appTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                        .background(Color.white)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                                .foregroundColor(.appTextSecondary.opacity(0.3))
                        )
                    }
                }
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 4) {
                    ForEach(photos.indices, id: \.self) { i in
                        Image(uiImage: photos[i])
                            .resizable()
                            .scaledToFill()
                            .frame(height: 110)
                            .clipped()
                            .cornerRadius(8)
                    }
                }
            }
        }
    }

    // MARK: - Signature
    private var signatureSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Kundenunterschrift", systemImage: "signature")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.appTextSecondary)
                    .textCase(.uppercase)
                Spacer()
            }
            if let sig = signatureImage {
                Image(uiImage: sig)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appGreen.opacity(0.3), lineWidth: 1))
            }
            Button(action: { showSignature = true }) {
                HStack(spacing: 6) {
                    Image(systemName: signatureImage == nil ? "hand.point.up.left.fill" : "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .semibold))
                    Text(signatureImage == nil ? "Unterschrift anfordern" : "Neue Unterschrift")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.appBlue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.appBlue.opacity(0.08))
                .cornerRadius(10)
            }
        }
        .padding(14)
        .cardStyle()
    }

    // MARK: - Notes
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notizen", systemImage: "note.text")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.appTextSecondary)
                .textCase(.uppercase)
            TextField("Notiz hinzufügen…", text: $order.notes, axis: .vertical)
                .font(.system(size: 14))
                .foregroundColor(.appTextPrimary)
                .lineLimit(3...8)
                .onChange(of: order.notes) { _, _ in onUpdate(order) }
        }
        .padding(14)
        .cardStyle()
    }
}

#Preview {
    NavigationStack {
        OrderDetailView(order: DummyData.orders[0]) { _ in }
    }
    .environmentObject(ToastManager())
}
