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
                            onSave: { smokedAt, rating, notes in
                                guard let userId = authService.userId else { return }
                                Task {
                                    try? await humidorService.logSmokingSession(
                                        humidorEntry: currentEntry,
                                        userId: userId,
                                        smokedAt: smokedAt,
                                        rating: rating,
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
    let onSave: (Date, Int?, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var smokedAt: Date = Date()
    @State private var rating: Int = 0
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let cigar = humidorEntry.cigar {
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
                }

                Section("Røykesession") {
                    DatePicker("Dato", selection: $smokedAt, displayedComponents: .date)
                }

                Section("Rating") {
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.title2)
                                .foregroundColor(star <= rating ? .orange : Color("TextSecondary").opacity(0.4))
                                .onTapGesture {
                                    // Klikk på valgt stjerne nullstiller ratingen
                                    rating = (rating == star) ? 0 : star
                                }
                        }
                        Spacer()
                        if rating > 0 {
                            Text("\(rating)/5")
                                .font(.subheadline)
                                .foregroundColor(Color("TextSecondary"))
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Kommentar") {
                    TextField("Smaksnotat, anledning...", text: $notes, axis: .vertical)
                        .lineLimit(4...)
                }
            }
            .navigationTitle("Har røkt den")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lagre") {
                        onSave(smokedAt, rating > 0 ? rating : nil, notes)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
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
