import SwiftUI
import PhotosUI
import UIKit

// MARK: - CigarSheets
// Arkene som brukes når man legger en sigar i humidoren eller loggfører en røyk.
// Presenteres fra CigarDetailViewDesign, HumidorView og long-press-hurtigmenyen
// (CigarQuickActions) — derfor bor de her, ikke inne i ett enkelt view.

// MARK: - Butikk-forslag
// Kjent norsk sortiment + brukerens egne tidligere butikker. Fritekst-feltet
// beholder friheten (utland, tax-free, gaver) — forslagene gjør det bare raskt
// og konsistent for det vanlige norske kjøpet.

enum KnownStores {
    static let norway = ["Sol Cigar", "Augusto Cigars", "M. Sørensen", "No Smoke", "Nordic Cigars", "Fuego Cigars"]

    /// Brukerens egne butikker først (mest relevant), så de norske som ikke alt er med.
    static func merged(withUser userStores: [String]) -> [String] {
        var out = userStores
        for s in norway where !out.contains(where: { $0.localizedCaseInsensitiveCompare(s) == .orderedSame }) {
            out.append(s)
        }
        return out
    }
}

/// Horisontal rad med tappbare butikk-forslag, filtrert på det brukeren skriver.
struct StoreSuggestionChips: View {
    @Binding var store: String
    let suggestions: [String]

    private var filtered: [String] {
        let q = store.trimmingCharacters(in: .whitespaces)
        return suggestions.filter { s in
            q.isEmpty || (s.localizedCaseInsensitiveContains(q)
                          && s.localizedCaseInsensitiveCompare(q) != .orderedSame)
        }
    }

    var body: some View {
        if !filtered.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(filtered.prefix(8), id: \.self) { name in
                        Button { store = name } label: {
                            Text(name)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color("Accent").opacity(0.10))
                                .foregroundColor(Color("Accent"))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Legg i humidor Sheet

struct AddToHumidorSheet: View {

    let cigar: Cigar
    var userId: UUID? = nil
    /// (valgt sigar/vitola, kjøpsdato, humidordato, antall, humidorId, butikk, pris per sigar, bilde)
    let onSave: (Cigar, Date, Date, Int, UUID?, String, Double?, Data?) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var proManager: ProManager
    @State private var purchasedAt: Date = Date()
    @State private var addedAt: Date = Date()
    @State private var quantity: Int = 1
    @State private var priceText: String = ""
    @State private var store: String = ""
    @State private var storeSuggestions: [String] = KnownStores.norway
    @State private var showPurchasePicker = false
    @State private var showHumidorPicker = false

    // Valgfritt bilde av sigaren/båndet — blir oppføringens bilde og mates til
    // visuell gjenkjenning (via trigger på humidor-tabellen).
    @State private var photoItem: PhotosPickerItem? = nil
    @State private var photoData: Data? = nil
    @State private var photoImage: Image? = nil

    // Vitola-valg: en skanning kjenner igjen merke + serie (båndet), ikke
    // størrelsen. Lar brukeren bytte til riktig vitola uten å legge inn på nytt.
    private let cigarService = CigarService()
    @State private var siblings: [Cigar] = []
    @State private var selectedCigarId: UUID? = nil

    // Humidor-valg
    private let humidorService = HumidorService()
    @State private var humidors: [Humidor] = []
    @State private var selectedHumidorId: UUID? = nil
    @State private var showCreateHumidor = false
    @State private var showPaywall = false

    // Gratis-nivå: maks 2 humidorer. Pro: ubegrenset.
    private func attemptCreateHumidor() {
        if proManager.isPro || humidors.count < 2 {
            showCreateHumidor = true
        } else {
            showPaywall = true
        }
    }

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
                    }
                    if siblings.count > 1 {
                        Picker("Vitola", selection: $selectedCigarId) {
                            ForEach(siblings) { c in
                                Text(vitolaLabel(c)).tag(Optional(c.id))
                            }
                        }
                    } else if let vitola = cigar.vitola {
                        HStack {
                            Text("Vitola")
                            Spacer()
                            Text(vitola).foregroundColor(Color("TextSecondary"))
                        }
                    }
                } footer: {
                    if siblings.count > 1 {
                        Text("Skanningen kjenner igjen merke og serie — men båndet er likt for alle størrelser. Velg riktig vitola.")
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
                        attemptCreateHumidor()
                    } label: {
                        Label("Opprett ny humidor", systemImage: "plus.circle.fill")
                            .foregroundColor(Color("Accent"))
                    }
                }

                Section("Antall") {
                    Stepper("\(quantity) stk", value: $quantity, in: 1...100)
                }

                // Valgfritt bilde — hjelper appen å kjenne igjen sigaren neste gang.
                Section {
                    if let photoImage {
                        photoImage
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        HStack(spacing: 6) {
                            Image(systemName: photoImage == nil ? "camera.fill" : "arrow.triangle.2.circlepath")
                            Text(photoImage == nil ? "Legg til bilde" : "Bytt bilde")
                                .font(.subheadline)
                        }
                        .foregroundColor(Color("Accent"))
                    }
                    .onChange(of: photoItem) { _, newItem in
                        Task {
                            guard let newItem,
                                  let data = try? await newItem.loadTransferable(type: Data.self),
                                  let uiImg = UIImage(data: data) else { return }
                            await MainActor.run {
                                photoData = data
                                photoImage = Image(uiImage: uiImg)
                                photoItem = nil
                            }
                        }
                    }
                    if photoImage != nil {
                        Button(role: .destructive) {
                            photoData = nil
                            photoImage = nil
                        } label: {
                            Label("Fjern bilde", systemImage: "trash")
                        }
                    }
                } header: {
                    Text("Bilde")
                } footer: {
                    Text("Valgfritt. Ta et bilde av båndet når du legger sigaren i humidoren — det blir oppføringens bilde og hjelper appen å kjenne igjen sigaren neste gang du skanner.")
                }

                Section {
                    HStack {
                        TextField("0", text: $priceText)
                            .keyboardType(.decimalPad)
                        Text("kr").foregroundColor(Color("TextSecondary"))
                    }
                } header: {
                    Text("Pris per sigar")
                } footer: {
                    Text("Valgfritt. Brukes til å regne ut total verdi i humidoren.")
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

                Section("Kjøpt hos") {
                    TextField("Butikk (valgfritt)", text: $store)
                        .textInputAutocapitalization(.words)
                    StoreSuggestionChips(store: $store, suggestions: storeSuggestions)
                        .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 8, trailing: 8))
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
                        let price = Double(priceText.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces))
                        let chosen = siblings.first(where: { $0.id == selectedCigarId }) ?? cigar
                        onSave(chosen, purchasedAt, addedAt, quantity, selectedHumidorId, store, price, photoData)
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
            .sheet(isPresented: $showPaywall) {
                PaywallView().environmentObject(proManager)
            }
            .task {
                await loadHumidors()
                await loadSiblings()
            }
        }
    }

    // Etikett i vitola-velgeren: «Toro · 54 × 6.0"» — målene hjelper deg å skille
    // to størrelser når du står med sigaren i hånden.
    private func vitolaLabel(_ c: Cigar) -> String {
        let s = [c.vitola, c.dimensionsLabel].compactMap { $0 }.joined(separator: " · ")
        return s.isEmpty ? "Standard" : s
    }

    // Hent alle vitolaer i samme linje, og forhåndsvelg den skannede.
    private func loadSiblings() async {
        selectedCigarId = cigar.id
        siblings = await cigarService.siblingVitolas(for: cigar)
        if !siblings.contains(where: { $0.id == selectedCigarId }) {
            selectedCigarId = siblings.first?.id ?? cigar.id
        }
    }

    private func loadHumidors() async {
        guard let userId else { return }
        humidors = (try? await humidorService.fetchHumidors(userId: userId)) ?? []
        if selectedHumidorId == nil { selectedHumidorId = humidors.first?.id }
        let mine = await humidorService.fetchStoreSuggestions(userId: userId)
        storeSuggestions = KnownStores.merged(withUser: mine)
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
    var userId: UUID? = nil
    /// (smokedAt, score, smokeAgain, draw, burn, flavor, notes, photoData, cutType, store)
    let onSave: (Date, Int?, Bool?, Int?, Int?, Int?, String?, Data?, CutType?, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var smokedAt: Date        = Date()
    @State private var hasScore: Bool        = true
    @State private var score: Int            = 85
    @State private var smokeAgain: Bool?     = nil   // nil = ikke valgt
    @State private var drawRating: Int       = 0     // 0 = ikke satt, 1-5
    @State private var burnRating: Int       = 0
    @State private var flavorRating: Int     = 0
    @State private var notes: String         = ""
    @State private var store: String         = ""
    @State private var storeSuggestions: [String] = KnownStores.norway
    @State private var showSubRatings: Bool  = false
    private let humidorService = HumidorService()
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
                        Text("Prøve igjen?")
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

                    // ── Kjøpt hos ─────────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kjøpt hos")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        TextField("Butikk (valgfritt)", text: $store)
                            .textInputAutocapitalization(.words)
                            .padding(12)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        StoreSuggestionChips(store: $store, suggestions: storeSuggestions)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 4)

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
                                selectedCutType,
                                store.isEmpty ? nil : store
                            )
                            dismiss()
                        } label: {
                            Text("Loggfør sigar")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color("Accent"))
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }

                        Button {
                            onSave(smokedAt, nil, smokeAgain, nil, nil, nil, notes.isEmpty ? nil : notes, photoData, selectedCutType, store.isEmpty ? nil : store)
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
            .navigationTitle("Loggfør sigar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
            }
            .task {
                guard let userId else { return }
                let mine = await humidorService.fetchStoreSuggestions(userId: userId)
                storeSuggestions = KnownStores.merged(withUser: mine)
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

// MARK: - Del etter lagring (ekstern deling)
// Vises etter at et journalinnlegg er lagret. Kun ekstern deling av en offentlig
// katalog-lenke via det native delings-arket. Aldri påtvunget; journalen er privat.

/// Identifiable-wrapper så vi kan presentere del-arket via .sheet(item:).
struct SharePrompt: Identifiable {
    let id = UUID()
    let entryId: UUID
}

/// Identifiable-wrapper for URL til native delings-ark.
struct ShareURLItem: Identifiable {
    let id = UUID()
    let url: URL
}

/// Ekstern deling: bilde + tekst + lenke i ett. Bildet gjør at Facebook/Instagram
/// viser et ekte bilde-innlegg (FB-appen viser aldri lenke-kort fra mobil).
struct ExternalShareItem: Identifiable {
    let id = UUID()
    let url: URL
    let image: UIImage?
    let caption: String
}

struct ShareAfterSaveSheet: View {

    let entryId: UUID
    /// Kalles med den offentlige lenken hvis brukeren valgte «Del eksternt».
    /// Foreldre-viewet presenterer da det native delings-arket (unngår nøstede ark).
    var onExternalShare: (URL) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    private let shareService = ShareService()

    @State private var external = false
    @State private var isSaving = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Dele opplevelsen din?")
                .font(.title3.bold())
                .padding(.top, 22)
            Text("Journalen din er privat. Velg selv hva du deler.")
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .padding(.top, 3)

            toggleRow(
                title: "Del eksternt",
                subtitle: "Del lenken via delings-arket",
                isOn: $external
            )
            .padding(.top, 18)

            Button {
                Task { await share() }
            } label: {
                HStack {
                    if isSaving { ProgressView().tint(.white) }
                    Text("Del").fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(external ? Color("Accent") : Color("TextSecondary").opacity(0.4))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(isSaving || !external)
            .padding(.top, 20)

            Button("Behold privat") { dismiss() }
                .fontWeight(.medium)
                .foregroundColor(Color("TextSecondary"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color("TextSecondary").opacity(0.3), lineWidth: 1))
                .padding(.top, 8)

            Button("Avbryt") { dismiss() }
                .font(.subheadline)
                .foregroundColor(Color("Accent"))
                .frame(maxWidth: .infinity)
                .padding(.top, 10)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .presentationDetents([.height(400)])
        .presentationDragIndicator(.visible)
    }

    private func toggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundColor(Color("TextPrimary"))
                Text(subtitle).font(.caption).foregroundColor(Color("TextSecondary"))
            }
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().tint(Color("Accent"))
        }
        .padding(.vertical, 11)
    }

    private func share() async {
        isSaving = true
        do {
            let res = try await shareService.setSharing(entryId: entryId, community: false, external: external)
            if external, let slug = res.publicSlug, let url = shareService.publicURL(slug: slug) {
                shareService.primeFacebook(slug: slug)   // varm opp FB-cachen i bakgrunnen
                onExternalShare(url)
            }
        } catch {
            print("set_entry_sharing feilet: \(error)")
        }
        isSaving = false
        dismiss()
    }
}

// MARK: - Kvittering: bekreft-skjerm
// Viser varelinjene appen leste fra kvitteringen, ferdig matchet mot databasen.
// Én standard-humidor øverst gjelder alle rader; hver rad kan overstyres. Ukjente
// varer ligger nederst med «Legg til manuelt». Ett trykk legger alt i humidoren.

/// Én redigerbar rad (matchet ELLER manuelt løst fra en ukjent linje).
private struct EditableReceiptLine: Identifiable {
    let id = UUID()
    var cigarId: UUID
    var title: String
    var brand: String
    let receiptName: String
    var quantity: Int
    var priceText: String
    var humidorId: UUID?
    var included: Bool = true
    var smartAssigned: Bool = false   // forhåndsvalgt til sist-brukte humidor

    var priceValue: Double {
        Double(priceText.replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)) ?? 0
    }
}

/// Kontekst for «bytt vitola»-arket: hvilken linje og hvilket merke.
private struct BrandSwapContext: Identifiable {
    let id = UUID()
    let lineId: UUID
    let brand: String
    let currentCigarId: UUID
}

/// «250» for hele tall, «249,5» ellers — norsk visning av enhetspris.
private func formatReceiptPrice(_ value: Double) -> String {
    if value.truncatingRemainder(dividingBy: 1) == 0 { return String(Int(value)) }
    return String(format: "%.1f", value).replacingOccurrences(of: ".", with: ",")
}

struct ReceiptConfirmView: View {

    let humidors: [Humidor]
    let userId: UUID
    var onFinished: () -> Void   // foreldre laster humidor-lista på nytt

    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    private let humidorService = HumidorService()

    @State private var lines: [EditableReceiptLine]
    @State private var unmatched: [ReceiptUnmatchedLine]
    @State private var defaultHumidorId: UUID?
    @State private var store: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var manualResolving: ReceiptUnmatchedLine?
    @State private var swapContext: BrandSwapContext?
    @State private var groupByHumidor = false
    @State private var smartApplied = false

    init(result: ReceiptParseResult, humidors: [Humidor], userId: UUID, onFinished: @escaping () -> Void) {
        self.humidors = humidors
        self.userId = userId
        self.onFinished = onFinished
        let defId = humidors.first?.id
        _defaultHumidorId = State(initialValue: defId)
        _store = State(initialValue: result.store ?? "")
        _lines = State(initialValue: result.matched.map { m in
            EditableReceiptLine(
                cigarId: m.cigarId,
                title: [m.brand, m.series, m.vitola].compactMap { $0 }.joined(separator: " · "),
                brand: m.brand,
                receiptName: m.receiptName,
                quantity: m.quantity,
                priceText: m.unitPrice.map(formatReceiptPrice) ?? "",
                humidorId: defId
            )
        })
        _unmatched = State(initialValue: result.unmatched)
    }

    private var totalCigars: Int {
        lines.filter { $0.included }.reduce(0) { $0 + $1.quantity }
    }

    private func humidorName(_ id: UUID?) -> String {
        humidors.first { $0.id == id }?.name ?? "Velg humidor"
    }

    var body: some View {
        NavigationStack {
            Group {
                if humidors.isEmpty {
                    noHumidorState
                } else {
                    VStack(spacing: 0) {
                        receiptHeader
                        List {
                            matchedSection
                            if !unmatched.isEmpty { unmatchedSection }
                        }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                    }
                    .background(Color("Background"))
                    .safeAreaInset(edge: .bottom) { addBar }
                    .task { await applySmartHumidors() }
                }
            }
            .navigationTitle("Fra kvittering")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
            }
            .sheet(item: $manualResolving) { pending in
                AddCigarSheet(prefillBrand: pending.name) { cigar in
                    resolveManually(pending: pending, cigar: cigar)
                }
                .environmentObject(authService)
            }
            .sheet(item: $swapContext) { ctx in
                BrandCigarPickerSheet(brand: ctx.brand, currentCigarId: ctx.currentCigarId) { cigar in
                    swapCigar(lineId: ctx.lineId, to: cigar)
                    swapContext = nil
                }
            }
        }
    }

    // MARK: Seksjoner

    // Butikk (redigerbart) + dato som ren tekst i toppen — ikke i et kort.
    private var todayString: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "nb_NO")
        df.dateFormat = "d. MMM yyyy"
        return df.string(from: Date())
    }

    private var receiptHeader: some View {
        HStack(spacing: 6) {
            Text("Kjøpt hos")
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
            TextField("butikk", text: $store)
                .font(.subheadline)
                .foregroundColor(Color("TextPrimary"))
            Text("· \(todayString)")
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .fixedSize()
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    private var matchedSection: some View {
        Section(header: Text("Funnet i basen (\(lines.count))")) {
            ForEach($lines) { $line in
                lineRow($line)
            }
        }
    }

    private var unmatchedSection: some View {
        Section {
            ForEach(unmatched) { item in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.subheadline)
                            .foregroundColor(Color("TextPrimary"))
                        Text("\(item.quantity) stk\(item.unitPrice.map { " · \(formatReceiptPrice($0)) kr" } ?? "")")
                            .font(.caption)
                            .foregroundColor(Color("TextSecondary"))
                    }
                    Spacer()
                    Button("Legg til manuelt") { manualResolving = item }
                        .font(.caption.weight(.semibold))
                        .buttonStyle(.borderless)
                        .foregroundColor(Color("Accent"))
                }
                .padding(.vertical, 2)
            }
        } header: {
            Text("Fant ikke i basen (\(unmatched.count))")
        } footer: {
            Text("Disse kjente vi ikke igjen fra kvitteringen. Legg dem til manuelt, eller la dem stå.")
        }
    }

    // Én matchet rad: tittel, antall-stepper, pris, humidor-overstyring.
    private func lineRow(_ line: Binding<EditableReceiptLine>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Image(systemName: line.wrappedValue.included ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(line.wrappedValue.included ? Color("Accent") : Color("TextSecondary"))
                    .onTapGesture { line.wrappedValue.included.toggle() }
                VStack(alignment: .leading, spacing: 2) {
                    Text(line.wrappedValue.title.isEmpty ? line.wrappedValue.receiptName : line.wrappedValue.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color("TextPrimary"))
                    Text("«\(line.wrappedValue.receiptName)»")
                        .font(.caption2)
                        .foregroundColor(Color("TextSecondary"))
                        .lineLimit(1)
                }
                Spacer()
                // Feil vitola? Bytt til en annen sigar fra samme merke.
                Button {
                    swapContext = BrandSwapContext(
                        lineId: line.wrappedValue.id,
                        brand: line.wrappedValue.brand,
                        currentCigarId: line.wrappedValue.cigarId
                    )
                } label: {
                    Image(systemName: "arrow.left.arrow.right.circle")
                        .font(.system(size: 20))
                        .foregroundColor(Color("Accent"))
                }
                .buttonStyle(.borderless)
            }

            HStack(spacing: 14) {
                // Antall-stepper
                HStack(spacing: 10) {
                    Button {
                        if line.wrappedValue.quantity > 1 { line.wrappedValue.quantity -= 1 }
                    } label: { Image(systemName: "minus.circle") }
                        .buttonStyle(.borderless)
                    Text("\(line.wrappedValue.quantity) stk")
                        .font(.footnote.weight(.semibold))
                        .frame(minWidth: 44)
                    Button {
                        if line.wrappedValue.quantity < 100 { line.wrappedValue.quantity += 1 }
                    } label: { Image(systemName: "plus.circle") }
                        .buttonStyle(.borderless)
                }
                .foregroundColor(Color("Accent"))

                // Pris
                HStack(spacing: 2) {
                    TextField("0", text: line.priceText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 52)
                    Text("kr").font(.caption).foregroundColor(Color("TextSecondary"))
                }

                Spacer()
            }
            .opacity(line.wrappedValue.included ? 1 : 0.4)

            // Humidor-overstyring per rad
            HStack {
                Menu {
                    ForEach(humidors) { h in
                        Button(h.name) { line.wrappedValue.humidorId = h.id }
                    }
                } label: {
                    humidorChip(humidorName(line.wrappedValue.humidorId))
                }
                if line.wrappedValue.smartAssigned {
                    Text("sist her")
                        .font(.caption2)
                        .foregroundColor(Color("Accent").opacity(0.7))
                }
                Spacer()
            }
            .opacity(line.wrappedValue.included ? 1 : 0.4)
        }
        .padding(.vertical, 4)
    }

    private func humidorChip(_ text: String) -> some View {
        HStack(spacing: 4) {
            Text(text).font(.footnote.weight(.medium))
            Image(systemName: "chevron.up.chevron.down").font(.system(size: 10))
        }
        .foregroundColor(Color("Accent"))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color("Accent").opacity(0.12)))
    }

    private var addBar: some View {
        VStack(spacing: 6) {
            if let errorMessage {
                Text(errorMessage).font(.caption).foregroundColor(.red)
            }
            Button {
                Task { await save() }
            } label: {
                HStack {
                    if isSaving { ProgressView().tint(.white) }
                    Text(totalCigars > 0 ? "Legg til \(totalCigars) sigarer" : "Ingen valgt")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(totalCigars > 0 ? Color("Accent") : Color("TextSecondary").opacity(0.4))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .disabled(isSaving || totalCigars == 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
    }

    private var noHumidorState: some View {
        VStack(spacing: 16) {
            Image(systemName: "archivebox")
                .font(.system(size: 52))
                .foregroundColor(Color("TextSecondary").opacity(0.5))
            Text("Opprett en humidor først")
                .font(.title3.bold())
            Text("Du trenger minst én humidor å legge\nsigarene fra kvitteringen i.")
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
        .background(Color("Background"))
    }

    // MARK: Handlinger

    private func setDefaultHumidor(_ id: UUID) {
        defaultHumidorId = id
        for i in lines.indices {
            lines[i].humidorId = id
            lines[i].smartAssigned = false   // brukeren valgte «alle i én»
        }
    }

    /// Smart forhåndsvalg: rut hver sigar til humidoren den lå i sist (hvis noen).
    /// Kjøres én gang når arket åpnes.
    private func applySmartHumidors() async {
        guard !smartApplied, !lines.isEmpty else { return }
        smartApplied = true
        let ids = Array(Set(lines.map { $0.cigarId }))
        let map = await humidorService.lastHumidorByCigar(userId: userId, cigarIds: ids)
        guard !map.isEmpty else { return }
        await MainActor.run {
            for i in lines.indices {
                if let h = map[lines[i].cigarId], humidors.contains(where: { $0.id == h }) {
                    lines[i].humidorId = h
                    lines[i].smartAssigned = (h != defaultHumidorId)
                }
            }
        }
    }

    // Ukjent linje ble løst via manuell innlegging — flytt den opp til de matchede.
    private func resolveManually(pending: ReceiptUnmatchedLine, cigar: Cigar) {
        unmatched.removeAll { $0.id == pending.id }
        lines.append(EditableReceiptLine(
            cigarId: cigar.id,
            title: [cigar.brand, cigar.series, cigar.vitola].compactMap { $0 }.joined(separator: " · "),
            brand: cigar.brand,
            receiptName: pending.name,
            quantity: pending.quantity,
            priceText: pending.unitPrice.map(formatReceiptPrice) ?? "",
            humidorId: defaultHumidorId
        ))
    }

    // Feil vitola matchet fra kvitteringen — bytt linjen til en annen sigar
    // fra samme merke (beholder antall, pris og humidor).
    private func swapCigar(lineId: UUID, to cigar: Cigar) {
        guard let idx = lines.firstIndex(where: { $0.id == lineId }) else { return }
        lines[idx].cigarId = cigar.id
        lines[idx].title = [cigar.brand, cigar.series, cigar.vitola]
            .compactMap { $0 }.joined(separator: " · ")
        lines[idx].brand = cigar.brand
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        let trimmedStore = store.trimmingCharacters(in: .whitespaces)
        do {
            for line in lines where line.included {
                let price = Double(line.priceText
                    .replacingOccurrences(of: ",", with: ".")
                    .trimmingCharacters(in: .whitespaces))
                try await humidorService.addToHumidor(
                    cigarId: line.cigarId,
                    userId: userId,
                    humidorId: line.humidorId ?? defaultHumidorId,
                    quantity: line.quantity,
                    purchasedAt: nil,
                    addedToHumidorAt: Date(),
                    store: trimmedStore.isEmpty ? nil : trimmedStore,
                    purchasePrice: price
                )
            }
            onFinished()
            dismiss()
        } catch {
            errorMessage = "Kunne ikke legge til alt. Prøv igjen."
            isSaving = false
        }
    }
}

// MARK: - Bytt vitola-ark
// Åpnes fra en kvittering-linje: lister alle sigarer fra samme merke slik at
// brukeren kan velge riktig vitola/variant hvis skanneren traff feil.
private struct BrandCigarPickerSheet: View {
    let brand: String
    let currentCigarId: UUID
    var onPick: (Cigar) -> Void

    @Environment(\.dismiss) private var dismiss
    private let cigarService = CigarService()

    @State private var cigars: [Cigar] = []
    @State private var isLoading = true
    @State private var query = ""

    private var filtered: [Cigar] {
        guard !query.isEmpty else { return cigars }
        let q = query.lowercased()
        return cigars.filter {
            [$0.brand, $0.series, $0.vitola].compactMap { $0 }
                .joined(separator: " ").lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if cigars.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(filtered) { c in
                            Button { onPick(c) } label: { row(c) }
                                .buttonStyle(.plain)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .searchable(text: $query, prompt: "Søk serie eller vitola")
                }
            }
            .background(Color("Background"))
            .navigationTitle(brand)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
            }
            .task { await load() }
        }
    }

    private func row(_ c: Cigar) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text([c.series, c.vitola].compactMap { $0 }.joined(separator: " · "))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color("TextPrimary"))
                if c.id == currentCigarId {
                    Text("Nåværende treff")
                        .font(.caption2)
                        .foregroundColor(Color("Accent"))
                }
            }
            Spacer()
            if c.id == currentCigarId {
                Image(systemName: "checkmark")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(Color("Accent"))
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 2)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(Color("TextSecondary").opacity(0.5))
            Text("Fant ingen andre sigarer fra \(brand)")
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }

    private func load() async {
        do {
            let list = try await cigarService.fetchCigarsByBrand(brand)
            await MainActor.run {
                cigars = list
                isLoading = false
            }
        } catch {
            await MainActor.run { isLoading = false }
        }
    }
}
