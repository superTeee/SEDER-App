import SwiftUI
import PhotosUI

// MARK: - CigarDetailView
// Fullt informasjonskort for en sigar.
// To moduser:
//   - Treff-modus (entry == nil): viser sigarinfo + "Legg i humidor"-knapp → sheet
//   - Humidor-modus (entry != nil): viser sigarinfo + antall + "Har røkt den"-knapp

struct CigarDetailView: View {

    let cigar: Cigar
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var entry: HumidorEntry?
    @State private var quantity: Int = 1
    @State private var isSaving = false
    @State private var showLoginSheet = false
    @State private var saveError: String?

    // Legg i humidor
    @State private var showAddToHumidorSheet = false

    // Har røkt den
    @State private var showSmokingSheet = false

    // Bilde-opplasting
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isUploadingPhoto = false
    @State private var photoUploadError: String?

    private let humidorService = HumidorService()

    init(cigar: Cigar, humidorEntry: HumidorEntry? = nil) {
        self.cigar = cigar
        _entry = State(initialValue: humidorEntry)
        _quantity = State(initialValue: humidorEntry?.quantity ?? 1)
        if humidorEntry != nil {
            // ingen isSaved-state nødvendig lenger
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // MARK: Bilde-opplasting (kun fra Min humidor)
                if entry != nil {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack(spacing: 6) {
                            Image(systemName: "camera.fill")
                            Text(entry?.photoURL == nil ? "Last opp bilde" : "Bytt bilde")
                                .fontWeight(.semibold)
                            if isUploadingPhoto { ProgressView().padding(.leading, 4) }
                        }
                        .font(.subheadline)
                        .foregroundColor(Color("Accent"))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                }

                // MARK: Header
                CigarHeaderSection(cigar: cigar, photoURL: entry?.photoURL, showImage: entry != nil)
                Divider().padding(.horizontal)

                // MARK: Antall i humidor (kun humidor-modus)
                if entry != nil {
                    DetailSection(title: "Antall i humidor") {
                        HStack(spacing: 20) {
                            Button {
                                if quantity > 0 { quantity -= 1; saveQuantity() }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2).foregroundColor(Color("Accent"))
                            }
                            Text("\(quantity) stk")
                                .font(.title3.bold())
                                .frame(minWidth: 70, alignment: .center)
                            Button {
                                quantity += 1; saveQuantity()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2).foregroundColor(Color("Accent"))
                            }
                            Spacer()
                        }
                    }
                    Divider().padding(.horizontal)
                }

                // MARK: Konstruksjon
                DetailSection(title: "Konstruksjon") {
                    if let wrapper = cigar.wrapperLeaf {
                        DetailRow(label: "Wrapper", value: "\(wrapper)\(cigar.wrapperCountry.map { " (\($0))" } ?? "")")
                    }
                    if let binder = cigar.binder { DetailRow(label: "Binder", value: binder) }
                    if let filler = cigar.filler, !filler.isEmpty {
                        DetailRow(label: "Filler", value: filler.joined(separator: ", "))
                    }
                    if let origin = cigar.countryOrigin { DetailRow(label: "Opprinnelse", value: origin) }
                    if let gauge = cigar.ringGauge, let length = cigar.lengthInches {
                        DetailRow(label: "Størrelse", value: "\(length)\" × \(gauge) RG")
                    }
                }
                Divider().padding(.horizontal)

                // MARK: Smaksprofil
                if let notes = cigar.flavorNotes, !notes.isEmpty {
                    DetailSection(title: "Smaksprofil") {
                        FlavorTagsView(notes: notes)
                    }
                    Divider().padding(.horizontal)
                }

                // MARK: Om sigaren (kun humidor-modus)
                if entry != nil {
                    if let desc = cigar.description {
                        DetailSection(title: "Om sigaren") {
                            Text(desc)
                                .font(.subheadline)
                                .foregroundColor(Color("TextSecondary"))
                                .lineSpacing(4)
                        }
                        Divider().padding(.horizontal)
                    }
                }

                // MARK: Handlingsknapper
                if let currentEntry = entry {
                    // --- Humidor-modus ---
                    VStack(spacing: 12) {
                        // Har røkt den
                        Button(action: { showSmokingSheet = true }) {
                            HStack {
                                Image(systemName: "flame.fill")
                                Text("Har røkt den")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("Accent"))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Fjern fra humidor
                        Button(action: removeFromHumidorAction) {
                            HStack {
                                if isSaving {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "minus.circle.fill")
                                }
                                Text("Fjern fra humidor").fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.85))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(isSaving)

                        ShareLink(item: shareText) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Del med andre").fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("Surface"))
                            .foregroundColor(Color("Accent"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(24)
                    .sheet(isPresented: $showSmokingSheet) {
                        SmokingLogSheet(
                            humidorEntry: currentEntry,
                            onSave: { smokedAt, rating, smokeAgain, drawRating, burnRating, flavorRating, notes in
                                guard let userId = authService.userId else { return }
                                Task {
                                    try? await humidorService.logSmokingSession(
                                        humidorEntry: currentEntry,
                                        userId: userId,
                                        smokedAt: smokedAt,
                                        rating: rating,
                                        smokeAgain: smokeAgain,
                                        drawRating: drawRating,
                                        burnRating: burnRating,
                                        flavorRating: flavorRating,
                                        notes: notes
                                    )
                                    // Oppdater lokal antall
                                    quantity = max(0, quantity - 1)
                                    // Oppdater entry.quantity for videre logging
                                    if var updatedEntry = self.entry {
                                        updatedEntry.quantity = quantity
                                        self.entry = updatedEntry
                                    }
                                }
                            }
                        )
                    }

                } else {
                    // --- Treff-modus ---
                    VStack(spacing: 12) {
                        Button(action: {
                            guard authService.userId != nil else { showLoginSheet = true; return }
                            showAddToHumidorSheet = true
                        }) {
                            HStack {
                                if isSaving {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "archivebox.fill")
                                }
                                Text("Legg i humidor").fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("Accent"))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(isSaving)

                        ShareLink(item: shareText) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Del med andre").fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("Surface"))
                            .foregroundColor(Color("Accent"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(24)
                    .sheet(isPresented: $showAddToHumidorSheet) {
                        AddToHumidorSheet(cigar: cigar) { purchasedAt, addedAt, qty in
                            guard let userId = authService.userId else { return }
                            isSaving = true
                            Task {
                                do {
                                    let newEntry = try await humidorService.addToHumidor(
                                        cigarId: cigar.id,
                                        userId: userId,
                                        quantity: qty,
                                        purchasedAt: purchasedAt,
                                        addedToHumidorAt: addedAt
                                    )
                                    self.entry = newEntry
                                    self.quantity = newEntry.quantity
                                } catch {
                                    print("Feil ved lagring: \(error)")
                                    saveError = error.localizedDescription
                                }
                                isSaving = false
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(cigar.brand)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLoginSheet) {
            AuthView(onSuccess: { showAddToHumidorSheet = true })
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem, let entry, let userId = authService.userId else { return }
            Task {
                isUploadingPhoto = true
                defer { isUploadingPhoto = false }
                do {
                    guard let data = try await newItem.loadTransferable(type: Data.self) else {
                        photoUploadError = "Kunne ikke lese det valgte bildet."
                        return
                    }
                    let url = try await humidorService.uploadPhoto(entryId: entry.id, userId: userId, imageData: data)
                    self.entry?.photoURL = url
                } catch {
                    print("Feil ved bildeopplasting: \(error)")
                    photoUploadError = "Opplasting av bilde feilet. Sjekk internettforbindelsen og prøv igjen."
                }
                selectedPhotoItem = nil
            }
        }
        .alert("Feil", isPresented: .constant(photoUploadError != nil)) {
            Button("OK") { photoUploadError = nil }
        } message: {
            Text(photoUploadError ?? "")
        }
        .alert("Kunne ikke lagre", isPresented: .constant(saveError != nil)) {
            Button("OK") { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
    }

    // MARK: - Handlinger

    private func saveQuantity() {
        guard let entry else { return }
        Task { try? await humidorService.updateQuantity(entryId: entry.id, quantity: quantity) }
    }

    private func removeFromHumidorAction() {
        guard let entry else { return }
        isSaving = true
        Task {
            do {
                try await humidorService.removeFromHumidor(entryId: entry.id)
                self.entry = nil
            } catch { print("Feil ved fjerning: \(error)") }
            isSaving = false
        }
    }

    private var shareText: String {
        var lines = [cigar.fullName]
        if cigar.strength != nil { lines.append("Styrke: \(cigar.strengthLabel)") }
        if let notes = cigar.flavorNotes, !notes.isEmpty {
            lines.append("Smaksnotater: \(notes.joined(separator: ", "))")
        }
        if let desc = cigar.description { lines.append(desc) }
        lines.append("Funnet med Vitola 🍃")
        return lines.joined(separator: "\n")
    }
}

// MARK: - Legg i humidor Sheet

struct AddToHumidorSheet: View {

    let cigar: Cigar
    let onSave: (Date, Date, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var purchasedAt: Date = Date()
    @State private var addedAt: Date = Date()
    @State private var quantity: Int = 1
    @State private var showPurchasePicker = false
    @State private var showHumidorPicker = false

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
                        onSave(purchasedAt, addedAt, quantity)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Røyke-logg Sheet ("Har røkt den")

struct SmokingLogSheet: View {

    let humidorEntry: HumidorEntry
    /// (smokedAt, score, smokeAgain, draw, burn, flavor, notes)
    let onSave: (Date, Int?, Bool?, Int?, Int?, Int?, String?) -> Void

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
                    if let cigar = humidorEntry.cigar {
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
                    }

                    // ── Dato ─────────────────────────────────────────
                    DatePicker("Dato", selection: $smokedAt, displayedComponents: .date)
                        .padding(.horizontal, 20)
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
                            .tint(scoreColor)
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
                                    .tint(scoreColor)
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
                            .clipShape(RoundedRectangle(cornerRadius: 10))
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
                                notes.isEmpty ? nil : notes
                            )
                            dismiss()
                        } label: {
                            Text("Logg røykesession")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(scoreColor)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Button {
                            onSave(smokedAt, nil, smokeAgain, nil, nil, nil, notes.isEmpty ? nil : notes)
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
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
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
                        .fill(dot <= value.wrappedValue ? scoreColor : Color(.tertiarySystemBackground))
                        .frame(width: 26, height: 26)
                        .overlay(
                            Circle().stroke(dot <= value.wrappedValue ? scoreColor : Color(.systemGray4), lineWidth: 1.5)
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

// MARK: - Header Section

struct CigarHeaderSection: View {

    let cigar: Cigar
    var photoURL: String? = nil
    var showImage: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showImage {
                ZStack {
                    if let photoURL, let url = URL(string: photoURL) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill()
                            } else {
                                Rectangle().fill(Color("Surface"))
                            }
                        }
                        .id(photoURL)
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipped()
                    } else {
                        Rectangle()
                            .fill(Color("Surface"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                        VStack(spacing: 8) {
                            CigarIcon(color: Color("TextPrimary").opacity(0.4))
                                .frame(width: 56, height: 56)
                            Text("Bilde mangler")
                                .font(.caption)
                                .foregroundColor(Color("TextSecondary"))
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(cigar.brand).font(.title2.bold())
                if let series = cigar.series {
                    Text(series).font(.title3).foregroundColor(Color("TextSecondary"))
                }
                HStack(spacing: 12) {
                    if let strength = cigar.strength {
                        Label(cigar.strengthLabel, systemImage: "flame.fill")
                            .font(.caption.bold())
                            .foregroundColor(strengthColor(strength))
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(strengthColor(strength).opacity(0.12))
                            .clipShape(Capsule())
                    }
                    if let vitola = cigar.vitola {
                        Text(vitola)
                            .font(.caption)
                            .foregroundColor(Color("TextSecondary"))
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color("Surface"))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, showImage ? 0 : 16)
            .padding(.bottom, 16)
        }
    }

    func strengthColor(_ strength: Int) -> Color {
        switch strength {
        case 1, 2: return .green
        case 3: return .orange
        default: return .red
        }
    }
}

// MARK: - Detail Section

struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline).padding(.horizontal, 20).padding(.top, 16)
            content.padding(.horizontal, 20).padding(.bottom, 16)
        }
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .frame(width: 90, alignment: .leading)
            Text(value).font(.subheadline)
        }
    }
}

// MARK: - Flavor Tags

struct FlavorTagsView: View {
    let notes: [String]

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(notes, id: \.self) { note in
                Text(note)
                    .font(.caption)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color("Accent").opacity(0.12))
                    .foregroundColor(Color("TextPrimary"))
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Flow Layout (for tags)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: frame.minX + bounds.minX, y: frame.minY + bounds.minY), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth, x > 0 { x = 0; y += rowHeight + spacing; rowHeight = 0 }
                frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
                x += size.width + spacing
                rowHeight = max(rowHeight, size.height)
            }
            size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}
