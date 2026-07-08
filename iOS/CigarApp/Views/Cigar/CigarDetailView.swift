import SwiftUI
import PhotosUI
import UIKit

// MARK: - CigarDetailView
// Fullt informasjonskort for en sigar.
// To moduser:
//   - Treff-modus (entry == nil): viser sigarinfo + "Legg i humidor"-knapp → sheet
//   - Humidor-modus (entry != nil): viser sigarinfo + antall + "Har røkt den"-knapp

struct CigarDetailView: View {

    let cigar: Cigar
    // Valgfri handling for "Scan neste sigar" — settes kun i scan-flyten,
    // slik at knappen ikke dukker opp når man åpner en sigar fra humidor/utforsk.
    let onScanNext: (() -> Void)?
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
    // Marker som røkt fra treff-modus (uten humidor)
    @State private var showLogSmokedSheet = false
    // Bekreftelse etter logging
    @State private var showLoggedToast = false

    // Fjern fra humidor
    @State private var showRemoveAlert = false

    // Ønskeliste
    @State private var isInWishlist = false
    @State private var isWishlistLoading = false

    // Bilde-opplasting
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isUploadingPhoto = false
    @State private var photoUploadError: String?

    private let humidorService = HumidorService()
    private let wishlistService = WishlistService()

    @AppStorage("humidorHasNew") private var humidorHasNew: Bool = false

    init(cigar: Cigar, humidorEntry: HumidorEntry? = nil, onScanNext: (() -> Void)? = nil) {
        self.cigar = cigar
        self.onScanNext = onScanNext
        _entry = State(initialValue: humidorEntry)
        _quantity = State(initialValue: humidorEntry?.quantity ?? 1)
        if humidorEntry != nil {
            // ingen isSaved-state nødvendig lenger
        }
    }

    // Vis kort bekreftelse + haptikk etter at en økt er logget
    private func confirmLogged() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation { showLoggedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showLoggedToast = false }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // MARK: Header (med innebygd bilde-opplasting i humidor-modus)
                CigarHeaderSection(
                    cigar: cigar,
                    photoURL: entry?.photoURL,
                    showImage: entry != nil,
                    selectedPhotoItem: entry != nil ? $selectedPhotoItem : nil,
                    isUploading: isUploadingPhoto
                )
                Divider().padding(.horizontal)

                // MARK: Antall i humidor (kun humidor-modus)
                if let currentEntry = entry {
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

                        // Datoer
                        if currentEntry.purchaseDate != nil || currentEntry.addedToHumidorAt != nil {
                            VStack(spacing: 6) {
                                if let purchased = currentEntry.purchaseDate {
                                    HStack {
                                        Image(systemName: "cart.fill")
                                            .font(.caption)
                                            .foregroundColor(Color("TextSecondary"))
                                        Text("Kjøpt \(purchased.formatted(.dateTime.day().month(.wide).year()))")
                                            .font(.subheadline)
                                            .foregroundColor(Color("TextSecondary"))
                                        Spacer()
                                    }
                                }
                                if let added = currentEntry.addedToHumidorAt {
                                    HStack {
                                        Image(systemName: "archivebox.fill")
                                            .font(.caption)
                                            .foregroundColor(Color("TextSecondary"))
                                        Text("Lagt i humidor \(added.formatted(.dateTime.day().month(.wide).year()))")
                                            .font(.subheadline)
                                            .foregroundColor(Color("TextSecondary"))
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                    Divider().padding(.horizontal)
                }

                // MARK: Konstruksjon
                DetailSection(title: "Konstruksjon") {
                    VStack(alignment: .leading, spacing: 6) {
                        if let manufacturer = cigar.manufacturer {
                            DetailRow(label: "Produsent", value: manufacturer)
                        }
                        if let origin = cigar.countryOrigin { DetailRow(label: "Land", value: origin) }
                        if let wrapper = cigar.wrapperLeaf {
                            DetailRow(label: "Dekkblad", value: "\(wrapper)\(cigar.wrapperCountry.map { " (\($0))" } ?? "")")
                        }
                        if let binder = cigar.binder { DetailRow(label: "Omblad", value: binder) }
                        if let filler = cigar.filler, !filler.isEmpty {
                            DetailRow(label: "Innlegg", value: filler.joined(separator: ", "))
                        }
                        if let gauge = cigar.ringGauge, let length = cigar.lengthInches {
                            DetailRow(label: "Størrelse", value: "\(length)\" × \(gauge) RG")
                        }
                    }
                }
                Divider().padding(.horizontal)

                // MARK: Smaksprofil (bars)
                let hasProfile = cigar.strength != nil || cigar.body != nil || cigar.sweetness != nil || cigar.flavorIntensity != nil
                if hasProfile {
                    DetailSection(title: "Smaksprofil") {
                        VStack(spacing: 14) {
                            if let v = cigar.strength {
                                ProfileBarRow(label: "Styrke", value: v, color: Color("Accent"))
                            }
                            if let v = cigar.body {
                                ProfileBarRow(label: "Fylde", value: v, color: Color("Accent"))
                            }
                            if let v = cigar.sweetness {
                                ProfileBarRow(label: "Sødme", value: v, color: Color("Accent"))
                            }
                            if let v = cigar.flavorIntensity {
                                ProfileBarRow(label: "Smaksintensitet", value: v, color: Color("Accent"))
                            }
                        }
                    }
                    Divider().padding(.horizontal)
                }

                // MARK: Smaksnotater (tags)
                if let notes = cigar.flavorNotes, !notes.isEmpty {
                    DetailSection(title: "Smaksnotater") {
                        FlavorTagsView(notes: notes)
                    }
                    Divider().padding(.horizontal)
                }

                // MARK: Om sigaren (vises i begge moduser når beskrivelsen finnes)
                if let desc = cigar.description {
                    DetailSection(title: "Om sigaren") {
                        Text(desc)
                            .font(.subheadline)
                            .foregroundColor(Color("TextSecondary"))
                            .lineSpacing(4)
                    }
                    Divider().padding(.horizontal)
                }

                // MARK: Handlingsknapper
                if let currentEntry = entry {
                    // --- Humidor-modus ---
                    VStack(spacing: 12) {
                        // Marker som røkt
                        Button(action: { showSmokingSheet = true }) {
                            HStack {
                                Image(systemName: "flame.fill")
                                Text("Marker som røkt")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("Accent"))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }

                        // Scan neste sigar — kun i scan-flyten (rask batch-innlegging)
                        if let onScanNext {
                            Button(action: { onScanNext() }) {
                                HStack {
                                    Image(systemName: "camera.viewfinder")
                                    Text("Scan neste sigar")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("Surface"))
                                .foregroundColor(Color("Accent"))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }

                    }
                    .padding(24)
                    .sheet(isPresented: $showSmokingSheet) {
                        SmokingLogSheet(
                            cigar: cigar,
                            onSave: { smokedAt, rating, smokeAgain, drawRating, burnRating, flavorRating, notes, photoData, cutType in
                                guard let userId = authService.userId else { return }
                                Task {
                                    do {
                                        let logId = try await humidorService.logSmokingSession(
                                            humidorEntry: currentEntry,
                                            userId: userId,
                                            smokedAt: smokedAt,
                                            rating: rating,
                                            smokeAgain: smokeAgain,
                                            drawRating: drawRating,
                                            burnRating: burnRating,
                                            flavorRating: flavorRating,
                                            notes: notes,
                                            cutType: cutType
                                        )
                                        // Last opp bilde i bakgrunnen hvis valgt
                                        if let data = photoData {
                                            let tastingService = TastingService()
                                            try? await tastingService.uploadLogPhoto(
                                                logId: logId,
                                                userId: userId,
                                                imageData: data
                                            )
                                        }
                                        await MainActor.run { confirmLogged() }
                                    } catch {
                                        print("Feil ved logging: \(error)")
                                    }
                                    // Oppdater lokal antall
                                    quantity = max(0, quantity - 1)
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
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .disabled(isSaving)

                        // Marker som røkt — logg uten å eie sigaren i humidoren
                        Button(action: {
                            guard authService.userId != nil else { showLoginSheet = true; return }
                            showLogSmokedSheet = true
                        }) {
                            HStack {
                                Image(systemName: "flame.fill")
                                Text("Marker som røkt").fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("Surface"))
                            .foregroundColor(Color("Accent"))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }

                        Button(action: { toggleWishlist() }) {
                            HStack {
                                if isWishlistLoading {
                                    ProgressView().tint(Color("Accent"))
                                } else {
                                    Image(systemName: isInWishlist ? "bookmark.fill" : "bookmark")
                                }
                                Text(isInWishlist ? "I ønskelisten" : "Legg i ønskeliste").fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("Surface"))
                            .foregroundColor(Color("Accent"))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .disabled(isWishlistLoading || authService.userId == nil)
                    }
                    .padding(24)
                    .sheet(isPresented: $showLogSmokedSheet) {
                        SmokingLogSheet(cigar: cigar) { smokedAt, rating, smokeAgain, drawRating, burnRating, flavorRating, notes, photoData, cutType in
                            guard let userId = authService.userId else { return }
                            Task {
                                do {
                                    let logId = try await humidorService.logTastingForCigar(
                                        cigarId: cigar.id,
                                        userId: userId,
                                        smokedAt: smokedAt,
                                        rating: rating,
                                        smokeAgain: smokeAgain,
                                        drawRating: drawRating,
                                        burnRating: burnRating,
                                        flavorRating: flavorRating,
                                        notes: notes,
                                        cutType: cutType
                                    )
                                    if let data = photoData {
                                        let tastingService = TastingService()
                                        try? await tastingService.uploadLogPhoto(logId: logId, userId: userId, imageData: data)
                                    }
                                    await MainActor.run { confirmLogged() }
                                } catch {
                                    print("Feil ved logging (uten humidor): \(error)")
                                }
                            }
                        }
                    }
                    .sheet(isPresented: $showAddToHumidorSheet) {
                        AddToHumidorSheet(cigar: cigar, userId: authService.userId) { purchasedAt, addedAt, qty, humidorId in
                            guard let userId = authService.userId else { return }
                            isSaving = true
                            Task {
                                do {
                                    let newEntry = try await humidorService.addToHumidor(
                                        cigarId: cigar.id,
                                        userId: userId,
                                        humidorId: humidorId,
                                        quantity: qty,
                                        purchasedAt: purchasedAt,
                                        addedToHumidorAt: addedAt
                                    )
                                    self.entry = newEntry
                                    self.quantity = newEntry.quantity
                                    humidorHasNew = true
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
        .overlay(alignment: .bottom) {
            if showLoggedToast {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Logget i journalen").fontWeight(.semibold)
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(Color("Accent"))
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.2), radius: 8, y: 2)
                .padding(.bottom, 28)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle(cigar.brand)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            if entry != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showRemoveAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .disabled(isSaving)
                }
            }
        }
        .alert("Fjern fra humidor", isPresented: $showRemoveAlert) {
            Button("Fjern", role: .destructive) { removeFromHumidorAction() }
            Button("Avbryt", role: .cancel) { }
        } message: {
            Text("Er du sikker på at du vil fjerne denne sigaren fra humidoren?")
        }
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
        .onAppear {
            guard entry == nil, let userId = authService.userId else { return }
            Task {
                isInWishlist = (try? await wishlistService.isInWishlist(userId: userId, cigarId: cigar.id)) ?? false
            }
        }
    }

    // MARK: - Handlinger

    private func toggleWishlist() {
        guard let userId = authService.userId else { showLoginSheet = true; return }
        isWishlistLoading = true
        Task {
            do {
                if isInWishlist {
                    try await wishlistService.removeFromWishlist(userId: userId, cigarId: cigar.id)
                    isInWishlist = false
                } else {
                    try await wishlistService.addToWishlist(userId: userId, cigarId: cigar.id)
                    isInWishlist = true
                    humidorHasNew = true
                }
            } catch {
                print("Feil ved ønskeliste-oppdatering: \(error)")
            }
            isWishlistLoading = false
        }
    }

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

// MARK: - Header Section

struct CigarHeaderSection: View {

    let cigar: Cigar
    var photoURL: String? = nil
    var showImage: Bool = true
    // Sett til non-nil for å vise opplastingsknapper (kun i humidor-modus)
    var selectedPhotoItem: Binding<PhotosPickerItem?>? = nil
    var isUploading: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showImage {
                ZStack(alignment: .bottomTrailing) {
                    if let photoURL, let url = URL(string: photoURL) {
                        // ── Bilde lastet opp ────────────────────────────────
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill()
                            } else {
                                Rectangle().fill(Color("Surface"))
                            }
                        }
                        .id(photoURL)
                        .frame(maxWidth: .infinity)
                        .frame(height: 224)
                        .clipped()

                        // Floating "Endre bilde"-knapp nede til høyre
                        if let binding = selectedPhotoItem {
                            PhotosPicker(selection: binding, matching: .images) {
                                ZStack {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 36, height: 36)
                                    if isUploading {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                    } else {
                                        Image(systemName: "pencil")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color("TextPrimary"))
                                    }
                                }
                            }
                            .padding(12)
                        }
                    } else {
                        // ── Ingen bilde ─────────────────────────────────────
                        Rectangle()
                            .fill(Color("Surface"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 224)

                        if let binding = selectedPhotoItem {
                            // "Last opp bilde" sentrert i placeholder
                            PhotosPicker(selection: binding, matching: .images) {
                                VStack(spacing: 10) {
                                    if isUploading {
                                        ProgressView()
                                            .scaleEffect(1.2)
                                    } else {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 28))
                                            .foregroundColor(Color("Accent"))
                                        Text("Last opp bilde")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(Color("Accent"))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 224)
                                .contentShape(Rectangle())
                            }
                        } else {
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
                            .foregroundColor(strengthColor(Double(strength)))
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(strengthColor(Double(strength)).opacity(0.12))
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

    func strengthColor(_ strength: Double) -> Color {
        switch strength {
        case ..<2.5: return .green
        case 2.5..<3.5: return .orange
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
                .frame(width: 110, alignment: .leading)
            Text(value).font(.subheadline)
        }
    }
}

// MARK: - Flavor Tags

struct FlavorTagsView: View {
    let notes: [String]

    // Note → ikon-familie, deduplisert, med norsk etikett
    private var items: [(icon: String, label: String)] {
        var seen = Set<String>()
        var result: [(icon: String, label: String)] = []
        for note in notes {
            guard let icon = FlavorIcon.name(for: note), !seen.contains(icon) else { continue }
            seen.insert(icon)
            result.append((icon, FlavorIcon.displayLabel(for: icon)))
        }
        return result
    }

    // 4 i bredden
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(items, id: \.icon) { item in
                VStack(spacing: 6) {
                    Image(item.icon)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 38, height: 38)
                        .foregroundColor(Color("Accent"))
                    Text(item.label)
                        .font(.caption)
                        .foregroundColor(Color("TextSecondary"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Profile Bar Row

struct ProfileBarRow: View {
    let label: String
    let value: Double   // 0–5
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .frame(width: 110, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("Surface"))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(min(value, 5.0) / 5.0), height: 8)
                }
            }
            .frame(height: 8)

            Text(String(format: "%.1f", value))
                .font(.caption.monospacedDigit())
                .foregroundColor(Color("TextSecondary"))
                .frame(width: 28, alignment: .trailing)
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
