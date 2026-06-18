import SwiftUI
import PhotosUI

// MARK: - CigarDetailView
// Fullt informasjonskort for en sigar + lagre til humidor

struct CigarDetailView: View {

    let cigar: Cigar
    @EnvironmentObject var authService: AuthService
    @State private var isSaved = false
    @State private var showSaveConfirm = false
    @State private var isSaving = false
    @State private var showLoginSheet = false
    private let humidorService = HumidorService()

    // Satt når sigaren åpnes fra "Min humidor" — styrer bilde-opplasting,
    // stjerne-vurdering og antall-editor.
    @State private var entry: HumidorEntry?
    @State private var quantity: Int = 1
    @State private var scoreConstruction: Int?
    @State private var scoreDraw: Int?
    @State private var scoreBurn: Int?
    @State private var scoreFlavor: Int?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isUploadingPhoto = false
    @State private var photoUploadError: String?

    init(cigar: Cigar, humidorEntry: HumidorEntry? = nil) {
        self.cigar = cigar
        _entry = State(initialValue: humidorEntry)
        _quantity = State(initialValue: humidorEntry?.quantity ?? 1)
        _scoreConstruction = State(initialValue: humidorEntry?.scoreConstruction)
        _scoreDraw = State(initialValue: humidorEntry?.scoreDraw)
        _scoreBurn = State(initialValue: humidorEntry?.scoreBurn)
        _scoreFlavor = State(initialValue: humidorEntry?.scoreFlavor)
        if humidorEntry != nil {
            _isSaved = State(initialValue: true)
        }
    }

    private var totalScore: Double? {
        let scores = [scoreConstruction, scoreDraw, scoreBurn, scoreFlavor].compactMap { $0 }
        guard !scores.isEmpty else { return nil }
        return Double(scores.reduce(0, +)) / Double(scores.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // MARK: Last opp bilde (kun fra Min humidor)
                if entry != nil {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack(spacing: 6) {
                            Image(systemName: "camera.fill")
                            Text(entry?.photoURL == nil ? "Last opp bilde" : "Bytt bilde")
                                .fontWeight(.semibold)
                            if isUploadingPhoto {
                                ProgressView()
                                    .padding(.leading, 4)
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(Color("Accent"))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                }

                // MARK: Header
                // Bilde vises kun når sigaren er lagret i humidoren — på et
                // "treff" (ikke lagret) finnes det ennå ikke noe brukerbilde.
                CigarHeaderSection(cigar: cigar, photoURL: entry?.photoURL, showImage: entry != nil)

                Divider().padding(.horizontal)

                // MARK: Din vurdering + antall (kun fra Min humidor)
                if entry != nil {
                    DetailSection(title: "Din vurdering") {
                        VStack(spacing: 10) {
                            StarRatingRow(label: "Konstruksjon", rating: $scoreConstruction)
                            StarRatingRow(label: "Trekk", rating: $scoreDraw)
                            StarRatingRow(label: "Aske", rating: $scoreBurn)
                            StarRatingRow(label: "Smak", rating: $scoreFlavor)

                            if let total = totalScore {
                                Divider()
                                HStack {
                                    Text("Totalscore")
                                        .font(.subheadline.bold())
                                    Spacer()
                                    Text(String(format: "%.1f", total))
                                        .font(.subheadline.bold())
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .onChange(of: scoreConstruction) { _, _ in saveScores() }
                    .onChange(of: scoreDraw) { _, _ in saveScores() }
                    .onChange(of: scoreBurn) { _, _ in saveScores() }
                    .onChange(of: scoreFlavor) { _, _ in saveScores() }

                    Divider().padding(.horizontal)

                    DetailSection(title: "Antall i humidor") {
                        HStack(spacing: 20) {
                            Button {
                                if quantity > 0 {
                                    quantity -= 1
                                    saveQuantity()
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(Color("Accent"))
                            }

                            Text("\(quantity) stk")
                                .font(.title3.bold())
                                .frame(minWidth: 70, alignment: .center)

                            Button {
                                quantity += 1
                                saveQuantity()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(Color("Accent"))
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
                    if let binder = cigar.binder {
                        DetailRow(label: "Binder", value: binder)
                    }
                    if let filler = cigar.filler, !filler.isEmpty {
                        DetailRow(label: "Filler", value: filler.joined(separator: ", "))
                    }
                    if let origin = cigar.countryOrigin {
                        DetailRow(label: "Opprinnelse", value: origin)
                    }
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

                // MARK: Om sigaren + Pris (kun nøkkelinfo vises for et "treff" —
                // disse to skjules når sigaren ikke er lagret i humidoren)
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

                    if let price = cigar.priceRange {
                        DetailSection(title: "Prisnivå") {
                            Text(price)
                                .font(.subheadline)
                                .foregroundColor(Color("TextSecondary"))
                        }
                    }
                }

                // MARK: Lagre- og dele-knapper
                if entry != nil {
                    // Allerede i humidoren — full "Fjern fra humidor"-knapp + del
                    VStack(spacing: 12) {
                        Button(action: removeFromHumidorAction) {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "minus.circle.fill")
                                }
                                Text("Fjern fra humidor")
                                    .fontWeight(.semibold)
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
                                Text("Del med andre")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("Surface"))
                            .foregroundColor(Color("Accent"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(24)
                } else {
                    // Et "treff" som ikke er lagret — kompakt humidor+pluss-ikon
                    // i stedet for full-bredde tekstknapp.
                    VStack(spacing: 12) {
                        Button(action: saveToHumidor) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "archivebox.fill")
                                    .font(.system(size: 28))
                                    .frame(width: 68, height: 68)
                                    .foregroundColor(.white)
                                    .background(Color("Accent"))
                                    .clipShape(Circle())

                                if isSaving {
                                    ProgressView()
                                        .tint(.white)
                                        .frame(width: 68, height: 68)
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color("Accent")))
                                        .clipShape(Circle())
                                        .offset(x: 4, y: -4)
                                }
                            }
                            .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
                        }
                        .disabled(isSaving)

                        Text("Legg til i humidor")
                            .font(.caption)
                            .foregroundColor(Color("TextSecondary"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)

                    ShareLink(item: shareText) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Del med andre")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("Surface"))
                        .foregroundColor(Color("Accent"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle(cigar.brand)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLoginSheet) {
            AuthView(onSuccess: { saveToHumidor() })
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
            }
        }
        .alert("Feil", isPresented: .constant(photoUploadError != nil)) {
            Button("OK") { photoUploadError = nil }
        } message: {
            Text(photoUploadError ?? "")
        }
    }

    // MARK: - Lagre vurdering/antall
    private func saveScores() {
        guard let entry else { return }
        Task {
            try? await humidorService.updateScores(
                entryId: entry.id,
                construction: scoreConstruction,
                draw: scoreDraw,
                burn: scoreBurn,
                flavor: scoreFlavor
            )
        }
    }

    private func saveQuantity() {
        guard let entry else { return }
        Task {
            try? await humidorService.updateQuantity(entryId: entry.id, quantity: quantity)
        }
    }

    // MARK: - Deletekst
    private var shareText: String {
        var lines = [cigar.fullName]
        if cigar.strength != nil {
            lines.append("Styrke: \(cigar.strengthLabel)")
        }
        if let notes = cigar.flavorNotes, !notes.isEmpty {
            lines.append("Smaksnotater: \(notes.joined(separator: ", "))")
        }
        if let desc = cigar.description {
            lines.append(desc)
        }
        lines.append("Funnet med Vitola 🍃")
        return lines.joined(separator: "\n")
    }

    private func saveToHumidor() {
        guard let userId = authService.userId else {
            showLoginSheet = true
            return
        }
        isSaving = true

        Task {
            do {
                let newEntry = try await humidorService.addToHumidor(cigarId: cigar.id, userId: userId)
                self.entry = newEntry
                quantity = newEntry.quantity
                isSaved = true
            } catch {
                print("Feil ved lagring: \(error)")
            }
            isSaving = false
        }
    }

    private func removeFromHumidorAction() {
        guard let entry else { return }
        isSaving = true

        Task {
            do {
                try await humidorService.removeFromHumidor(entryId: entry.id)
                self.entry = nil
                isSaved = false
            } catch {
                print("Feil ved fjerning: \(error)")
            }
            isSaving = false
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
            // Bilde (opplastet) — vises kun når sigaren er lagret i humidoren.
            // For et "treff" finnes det ennå ikke noe brukerbilde, så hele
            // bilde-området (inkl. placeholder) utelates.
            if showImage {
                ZStack {
                    if let photoURL, let url = URL(string: photoURL) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Rectangle().fill(Color("Surface"))
                            }
                        }
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
                Text(cigar.brand)
                    .font(.title2.bold())
                if let series = cigar.series {
                    Text(series)
                        .font(.title3)
                        .foregroundColor(Color("TextSecondary"))
                }

                HStack(spacing: 12) {
                    // Styrke-badge
                    if let strength = cigar.strength {
                        Label(cigar.strengthLabel, systemImage: "flame.fill")
                            .font(.caption.bold())
                            .foregroundColor(strengthColor(strength))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(strengthColor(strength).opacity(0.12))
                            .clipShape(Capsule())
                    }

                    // Vitola
                    if let vitola = cigar.vitola {
                        Text(vitola)
                            .font(.caption)
                            .foregroundColor(Color("TextSecondary"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
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
            Text(title)
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.top, 16)
            content
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
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
            Text(value)
                .font(.subheadline)
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
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
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
                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
                x += size.width + spacing
                rowHeight = max(rowHeight, size.height)
            }
            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}
