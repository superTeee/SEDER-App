import SwiftUI
import PhotosUI
import UIKit

// MARK: - CigarSheets
// Arkene som brukes når man legger en sigar i humidoren eller loggfører en røyk.
// Presenteres fra CigarDetailViewDesign, HumidorView og long-press-hurtigmenyen
// (CigarQuickActions) — derfor bor de her, ikke inne i ett enkelt view.

// MARK: - Legg i humidor Sheet

struct AddToHumidorSheet: View {

    let cigar: Cigar
    var userId: UUID? = nil
    let onSave: (Date, Date, Int, UUID?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var purchasedAt: Date = Date()
    @State private var addedAt: Date = Date()
    @State private var quantity: Int = 1
    @State private var showPurchasePicker = false
    @State private var showHumidorPicker = false

    // Humidor-valg
    private let humidorService = HumidorService()
    @State private var humidors: [Humidor] = []
    @State private var selectedHumidorId: UUID? = nil
    @State private var showCreateHumidor = false

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        f.locale = Locale(identifier: "nb_NO")
        return f
    }()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(cigar.brand).font(.headline)
                        if let series = cigar.series {
                            Text(series).font(.subheadline).foregroundColor(Color("TextSecondary"))
                        }
                        if let vitola = cigar.vitola {
                            Text(vitola).font(.caption).foregroundColor(Color("TextSecondary"))
                        }
                    }
                }

                // Humidor-valg øverst — velg hvilken humidor sigaren skal i,
                // eller opprett en ny på stedet.
                Section("Humidor") {
                    if !humidors.isEmpty {
                        Picker("Velg humidor", selection: $selectedHumidorId) {
                            ForEach(humidors) { h in
                                Text(h.name).tag(Optional(h.id))
                            }
                        }
                    }
                    Button {
                        showCreateHumidor = true
                    } label: {
                        Label("Opprett ny humidor", systemImage: "plus.circle.fill")
                            .foregroundColor(Color("Accent"))
                    }
                }

                Section("Datoer") {
                    // Kjøpsdato — klikk for å åpne, velg dato for å lukke
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showPurchasePicker.toggle()
                            if showPurchasePicker { showHumidorPicker = false }
                        }
                    } label: {
                        HStack {
                            Text("Kjøpsdato")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(dateFormatter.string(from: purchasedAt))
                                .foregroundColor(Color("TextSecondary"))
                            Image(systemName: showPurchasePicker ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundColor(Color("TextSecondary"))
                        }
                    }
                    if showPurchasePicker {
                        DatePicker("", selection: $purchasedAt, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .onChange(of: purchasedAt) { _, _ in
                                withAnimation(.easeInOut(duration: 0.2)) { showPurchasePicker = false }
                            }
                    }

                    // Humidordato
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showHumidorPicker.toggle()
                            if showHumidorPicker { showPurchasePicker = false }
                        }
                    } label: {
                        HStack {
                            Text("Lagt i humidor")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(dateFormatter.string(from: addedAt))
                                .foregroundColor(Color("TextSecondary"))
                            Image(systemName: showHumidorPicker ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundColor(Color("TextSecondary"))
                        }
                    }
                    if showHumidorPicker {
                        DatePicker("", selection: $addedAt, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .onChange(of: addedAt) { _, _ in
                                withAnimation(.easeInOut(duration: 0.2)) { showHumidorPicker = false }
                            }
                    }
                }

                Section("Antall") {
                    Stepper("\(quantity) stk", value: $quantity, in: 1...100)
                }
            }
            .navigationTitle("Legg i humidor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Legg til") {
                        onSave(purchasedAt, addedAt, quantity, selectedHumidorId)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showCreateHumidor) {
                if let userId {
                    CreateHumidorSheet(userId: userId, onSaved: {
                        Task { await reloadAndSelectNewest() }
                    })
                }
            }
            .task { await loadHumidors() }
        }
    }

    private func loadHumidors() async {
        guard let userId else { return }
        humidors = (try? await humidorService.fetchHumidors(userId: userId)) ?? []
        if selectedHumidorId == nil { selectedHumidorId = humidors.first?.id }
    }

    // Etter at en ny humidor er opprettet: hent lista på nytt og velg den nye.
    private func reloadAndSelectNewest() async {
        guard let userId else { return }
        let before = Set(humidors.map(\.id))
        humidors = (try? await humidorService.fetchHumidors(userId: userId)) ?? []
        if let newOne = humidors.first(where: { !before.contains($0.id) }) {
            selectedHumidorId = newOne.id
        } else if selectedHumidorId == nil {
            selectedHumidorId = humidors.first?.id
        }
    }
}

// MARK: - Røyke-logg Sheet ("Har røkt den")

struct SmokingLogSheet: View {

    let cigar: Cigar
    /// (smokedAt, score, smokeAgain, draw, burn, flavor, notes, photoData, cutType)
    let onSave: (Date, Int?, Bool?, Int?, Int?, Int?, String?, Data?, CutType?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var smokedAt: Date        = Date()
    @State private var hasScore: Bool        = true
    @State private var score: Int            = 85
    @State private var smokeAgain: Bool?     = nil   // nil = ikke valgt
    @State private var drawRating: Int       = 0     // 0 = ikke satt, 1-5
    @State private var burnRating: Int       = 0
    @State private var flavorRating: Int     = 0
    @State private var notes: String         = ""
    @State private var showSubRatings: Bool  = false
    @State private var selectedCutType: CutType? = nil

    // Foto
    @State private var photoItem: PhotosPickerItem? = nil
    @State private var photoData: Data?             = nil
    @State private var photoImage: Image?           = nil
    @State private var cropRequest: CropRequest?    = nil

    // MARK: Hjelpere

    private var scoreLabel: String {
        switch score {
        case 95...100: return "Exceptional"
        case 90...94:  return "Excellent"
        case 85...89:  return "Very good"
        case 80...84:  return "Good"
        case 70...79:  return "Average"
        default:       return "Not for me"
        }
    }

    private var scoreColor: Color {
        switch score {
        case 90...100: return Color(red: 0.85, green: 0.65, blue: 0.2)   // gull
        case 80...89:  return Color(red: 0.75, green: 0.55, blue: 0.15)  // mørk gull
        case 70...79:  return Color(red: 0.5,  green: 0.5,  blue: 0.5)   // grå
        default:       return Color(red: 0.55, green: 0.35, blue: 0.25)  // brun-rød
        }
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {

                    // ── Sigar-header ──────────────────────────────────
                    VStack(spacing: 4) {
                        Text(cigar.brand)
                            .font(.headline)
                        if let series = cigar.series {
                            Text(series)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        if let vitola = cigar.vitola {
                            Text(vitola)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                    // ── Dato ─────────────────────────────────────────
                    DatePicker("Dato", selection: $smokedAt, displayedComponents: .date)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)

                    Divider().padding(.horizontal, 20)

                    // ── Foto (valgfritt) ──────────────────────────────
                    VStack(spacing: 10) {
                        if let photoImage {
                            photoImage
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 180)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .padding(.horizontal, 20)
                        }
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            HStack(spacing: 6) {
                                Image(systemName: photoImage == nil ? "camera.fill" : "arrow.triangle.2.circlepath")
                                Text(photoImage == nil ? "Legg til bilde" : "Bytt bilde")
                                    .font(.subheadline)
                            }
                            .foregroundColor(Color("Accent"))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity, alignment: photoImage == nil ? .leading : .center)
                        }
                        .onChange(of: photoItem) { _, newItem in
                            Task {
                                guard let newItem,
                                      let data = try? await newItem.loadTransferable(type: Data.self),
                                      let uiImg = UIImage(data: data) else { return }
                                cropRequest = CropRequest(image: uiImg, ratio: 1.6)
                                photoItem = nil
                            }
                        }
                        .fullScreenCover(item: $cropRequest) { req in
                            ImageCropper(image: req.image, ratio: req.ratio) { cropped in
                                cropRequest = nil
                                photoData = cropped.jpegData(compressionQuality: 0.9)
                                photoImage = Image(uiImage: cropped)
                            } onCancel: {
                                cropRequest = nil
                            }
                            .ignoresSafeArea()
                        }
                    }
                    .padding(.vertical, 12)

                    Divider().padding(.horizontal, 20)

                    // ── Score-seksjon ─────────────────────────────────
                    VStack(spacing: 16) {

                        // Stor score-visning
                        VStack(spacing: 4) {
                            if hasScore {
                                Text("\(score)")
                                    .font(.system(size: 80, weight: .semibold, design: .rounded))
                                    .foregroundColor(scoreColor)
                                    .contentTransition(.numericText())
                                    .animation(.spring(duration: 0.2), value: score)

                                Text(scoreLabel)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .animation(.easeInOut, value: scoreLabel)
                            } else {
                                Text("–")
                                    .font(.system(size: 80, weight: .thin, design: .rounded))
                                    .foregroundColor(.secondary)
                                Text("Ingen score")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 20)

                        // Slider
                        if hasScore {
                            Slider(
                                value: Binding(
                                    get: { Double(score) },
                                    set: { score = Int($0) }
                                ),
                                in: 50...100,
                                step: 1
                            )
                            .tint(Color("Accent"))
                            .padding(.horizontal, 24)

                            // ±1/±5 justeringsknapper
                            HStack(spacing: 10) {
                                ForEach([-5, -1], id: \.self) { delta in
                                    Button("\(delta)") {
                                        score = max(50, min(100, score + delta))
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.secondary)
                                    .font(.subheadline)
                                }
                                Spacer()
                                ForEach([1, 5], id: \.self) { delta in
                                    Button("+\(delta)") {
                                        score = max(50, min(100, score + delta))
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(Color("Accent"))
                                    .font(.subheadline)
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                    }
                    .padding(.vertical, 8)

                    Divider().padding(.horizontal, 20).padding(.top, 8)

                    // ── Smoke again ───────────────────────────────────
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Ville røkt igjen?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 10) {
                            smokeAgainButton(label: "Ja", icon: "checkmark.circle.fill", value: true)
                            smokeAgainButton(label: "Kanskje", icon: "minus.circle.fill", value: nil)
                            smokeAgainButton(label: "Nei",    icon: "xmark.circle.fill",   value: false)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                    Divider().padding(.horizontal, 20)

                    // ── Cut type ──────────────────────────────────────
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Klipp")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 8) {
                            ForEach(CutType.allCases) { cut in
                                let isSelected = selectedCutType == cut
                                Button {
                                    selectedCutType = (selectedCutType == cut) ? nil : cut
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: cut.icon)
                                            .font(.system(size: 16))
                                        Text(cut.displayName)
                                            .font(.caption2)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(isSelected ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
                                    .foregroundColor(isSelected ? Color.accentColor : .secondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                    Divider().padding(.horizontal, 20)

                    // ── Sub-ratings (valgfritt) ───────────────────────
                    VStack(spacing: 12) {
                        Button {
                            withAnimation { showSubRatings.toggle() }
                        } label: {
                            HStack {
                                Text("Detaljer (valgfritt)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Image(systemName: showSubRatings ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 14)

                        if showSubRatings {
                            VStack(spacing: 14) {
                                dotRatingRow(label: "Trekk",    value: $drawRating)
                                dotRatingRow(label: "Brenning", value: $burnRating)
                                dotRatingRow(label: "Smak",     value: $flavorRating)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 4)
                        }
                    }

                    Divider().padding(.horizontal, 20).padding(.top, 12)

                    // ── Notater ───────────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kommentar")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        TextField("Smaksnotat, anledning, pairing...", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(12)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                    // ── Handlingsknapper ──────────────────────────────
                    VStack(spacing: 10) {
                        Button {
                            onSave(
                                smokedAt,
                                hasScore ? score : nil,
                                smokeAgain,
                                drawRating > 0 ? drawRating : nil,
                                burnRating > 0 ? burnRating : nil,
                                flavorRating > 0 ? flavorRating : nil,
                                notes.isEmpty ? nil : notes,
                                photoData,
                                selectedCutType
                            )
                            dismiss()
                        } label: {
                            Text("Logg røykesession")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color("Accent"))
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }

                        Button {
                            onSave(smokedAt, nil, smokeAgain, nil, nil, nil, notes.isEmpty ? nil : notes, photoData, selectedCutType)
                            dismiss()
                        } label: {
                            Text("Logg uten score")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Har røkt den")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
            }
        }
    }

    // MARK: Sub-views

    @ViewBuilder
    private func smokeAgainButton(label: String, icon: String, value: Bool?) -> some View {
        let isSelected: Bool = {
            switch (smokeAgain, value) {
            case (.none, .none): return true    // "Kanskje"-knappen
            case (.some(let a), .some(let b)): return a == b
            default: return false
            }
        }()

        Button {
            smokeAgain = value
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(label)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
            .foregroundColor(isSelected ? Color.accentColor : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func dotRatingRow(label: String, value: Binding<Int>) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .frame(width: 80, alignment: .leading)
            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { dot in
                    Circle()
                        .fill(dot <= value.wrappedValue ? Color("Accent") : Color(.tertiarySystemBackground))
                        .frame(width: 26, height: 26)
                        .overlay(
                            Circle().stroke(dot <= value.wrappedValue ? Color("Accent") : Color(.systemGray4), lineWidth: 1.5)
                        )
                        .onTapGesture {
                            value.wrappedValue = (value.wrappedValue == dot) ? 0 : dot
                        }
                }
            }
            Spacer()
        }
    }
}
