import SwiftUI
import PhotosUI

// MARK: - CigarDetailViewDesign
// Pixel-perfect implementasjon fra Figma-design (node 184:197)
// Mørkt tema: bg #131211, surface #24221e, accent #a79164

struct CigarDetailViewDesign: View {

    let cigar: Cigar
    var entry: HumidorEntry?

    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var quantity: Int
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isUploadingPhoto = false
    @State private var showSmokingSheet = false
    @State private var showRemoveAlert = false
    @State private var isSaving = false
    @State private var showAddToHumidorSheet = false
    @State private var isInWishlist = false

    private let humidorService = HumidorService()
    private let wishlistService = WishlistService()

    // ── Design-tokens fra Figma ─────────────────────────────────────────────
    private let pageBg        = Color(red: 0.075, green: 0.071, blue: 0.067) // #131211
    private let surfacePrimary = Color(red: 0.141, green: 0.133, blue: 0.118) // #24221e
    private let action        = Color(red: 0.655, green: 0.569, blue: 0.392) // #a79164
    private let textPrimary   = Color(red: 0.925, green: 0.922, blue: 0.918) // #ecebea
    private let textSecondary = Color(red: 0.855, green: 0.847, blue: 0.831) // #dad8d4
    private let textSubtle    = Color(red: 0.706, green: 0.694, blue: 0.667) // #b4b1aa

    init(cigar: Cigar, entry: HumidorEntry? = nil) {
        self.cigar = cigar
        self.entry = entry
        _quantity = State(initialValue: entry?.quantity ?? 1)
    }

    // ── Body ────────────────────────────────────────────────────────────────
    var body: some View {
        ZStack(alignment: .top) {
            pageBg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    heroImage
                    contentBody
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle(cigar.brand)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(textPrimary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: cigar.fullName) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(textPrimary)
                }
            }
        }
        .alert("Fjern fra humidor", isPresented: $showRemoveAlert) {
            Button("Fjern", role: .destructive) { removeEntry() }
            Button("Avbryt", role: .cancel) {}
        } message: { Text("Er du sikker på at du vil fjerne denne sigaren?") }
        .sheet(isPresented: $showSmokingSheet) {
            if let currentEntry = entry {
                SmokingLogSheet(cigar: cigar) { smokedAt, rating, smokeAgain, draw, burn, flavor, notes, photoData, cutType in
                    guard let userId = authService.userId else { return }
                    Task {
                        do {
                            let logId = try await humidorService.logSmokingSession(
                                humidorEntry: currentEntry,
                                userId: userId,
                                smokedAt: smokedAt,
                                rating: rating,
                                smokeAgain: smokeAgain,
                                drawRating: draw,
                                burnRating: burn,
                                flavorRating: flavor,
                                notes: notes,
                                cutType: cutType
                            )
                            if let data = photoData {
                                let ts = TastingService()
                                try? await ts.uploadLogPhoto(logId: logId, userId: userId, imageData: data)
                            }
                        } catch { print("Røyke-logg feil: \(error)") }
                        quantity = max(0, quantity - 1)
                    }
                }
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem, let entry, let userId = authService.userId else { return }
            Task {
                isUploadingPhoto = true
                defer { isUploadingPhoto = false }
                guard let data = try? await newItem.loadTransferable(type: Data.self) else { return }
                let url = try? await humidorService.uploadPhoto(entryId: entry.id, userId: userId, imageData: data)
                if url != nil { selectedPhotoItem = nil }
            }
        }
        .onAppear {
            guard entry == nil, let userId = authService.userId else { return }
            Task {
                isInWishlist = (try? await wishlistService.isInWishlist(userId: userId, cigarId: cigar.id)) ?? false
            }
        }
    }

    // ── Hero image ──────────────────────────────────────────────────────────
    @ViewBuilder
    private var heroImage: some View {
        ZStack(alignment: .topLeading) {
            // Bilde
            Group {
                if let photoURL = entry?.photoURL, let url = URL(string: photoURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img): img.resizable().scaledToFill()
                        default: Rectangle().fill(surfacePrimary)
                        }
                    }
                    .id(photoURL)
                } else if let productURL = cigar.productImageUrl, let url = URL(string: productURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img): img.resizable().scaledToFill()
                        default: Rectangle().fill(surfacePrimary)
                        }
                    }
                } else {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [surfacePrimary, pageBg],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay {
                            CigarIcon(color: textSubtle.opacity(0.3))
                                .frame(width: 60, height: 60)
                        }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 240)
            .clipped()

            // "Endre bilde"-pill (frosted glass, top-left)
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                HStack(spacing: 6) {
                    if isUploadingPhoto {
                        ProgressView().scaleEffect(0.75).tint(textPrimary)
                    } else {
                        Image(systemName: "camera.fill").font(.system(size: 12))
                    }
                    Text("Endre bilde")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(Color(red: 0.965, green: 0.953, blue: 0.941))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial.opacity(0.85))
                .clipShape(Capsule())
            }
            .padding(.leading, 20)
            .padding(.top, 66) // ← under navigasjonsbaren
        }
        // Quantity-pill flytende i nederkant av bildet
        .overlay(alignment: .bottom) {
            quantityPill
                .offset(y: 28)
                .padding(.bottom, -28)
        }
    }

    // ── Quantity pill ───────────────────────────────────────────────────────
    @ViewBuilder
    private var quantityPill: some View {
        ZStack {
            Capsule()
                .fill(surfacePrimary)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                .frame(width: 180, height: 56)

            HStack(spacing: 0) {
                // Minus FAB
                Button {
                    guard quantity > 0 else { return }
                    quantity -= 1; saveQuantity()
                } label: {
                    Circle()
                        .fill(action)
                        .frame(width: 40, height: 40)
                        .overlay {
                            Image(systemName: "minus")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                }
                .padding(.leading, 8)

                Spacer()

                Text("\(quantity)")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(textPrimary)
                    .monospacedDigit()

                Spacer()

                // Plus FAB
                Button {
                    quantity += 1; saveQuantity()
                } label: {
                    Circle()
                        .fill(action)
                        .frame(width: 40, height: 40)
                        .overlay {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                }
                .padding(.trailing, 8)
            }
            .frame(width: 180)
        }
    }

    // ── Scrollbar-innhold ───────────────────────────────────────────────────
    @ViewBuilder
    private var contentBody: some View {
        VStack(alignment: .leading, spacing: 36) {
            infoSection
            mainNotesCard
            if let description = cigar.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(textSecondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ratingsSection
            constructionSection
            priceSection

            // Action-knapp
            if entry != nil {
                Button { showSmokingSheet = true } label: {
                    HStack {
                        Image(systemName: "flame.fill")
                        Text("Marker som røkt").fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(action)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            } else {
                Button {
                    showAddToHumidorSheet = true
                } label: {
                    HStack {
                        Image(systemName: "archivebox.fill")
                        Text("Legg i humidor").fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(action)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 48) // plass til quantity-pill som overlapper
        .padding(.bottom, 100)
    }

    // ── Info section ────────────────────────────────────────────────────────
    @ViewBuilder
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let series = cigar.series {
                Text(series)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(textPrimary)
                    .tracking(-0.4)
            }

            VStack(alignment: .leading, spacing: 10) {
                if let purchased = entry?.purchaseDate {
                    infoRow(icon: "cart.fill",
                            text: purchased.formatted(.dateTime.day().month(.wide).year()))
                }
                if let added = entry?.addedToHumidorAt {
                    infoRow(icon: "archivebox.fill",
                            text: added.formatted(.dateTime.day().month(.wide).year()))
                }
                if let vitola = cigar.vitola {
                    infoRow(icon: "oval", text: vitola)
                }
                if let gauge = cigar.ringGauge, let length = cigar.lengthInches {
                    let sizeLabel = cigar.commonFormat ?? cigar.vitola ?? "—"
                    let lenStr = length.truncatingRemainder(dividingBy: 1) == 0
                        ? String(Int(length))
                        : String(format: "%.1f", length)
                    infoRow(icon: "arrow.up.left.and.arrow.down.right",
                            text: "\(sizeLabel) (\(lenStr)\" × \(gauge))")
                }
                if let origin = cigar.countryOrigin {
                    infoRow(icon: "mappin", text: origin)
                }
            }
        }
    }

    @ViewBuilder
    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(textPrimary)
                .frame(width: 20, alignment: .center)
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(textPrimary)
                .tracking(-0.32)
        }
    }

    // ── Main Notes card ─────────────────────────────────────────────────────
    @ViewBuilder
    private var mainNotesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header-rad
            HStack {
                Text("MAIN NOTES")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(textSubtle)
                    .tracking(0.6)
                Spacer()
                Button {} label: {
                    Text("Edit notes  +")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(action)
                }
            }
            .padding(.horizontal, 19)
            .padding(.top, 17)
            .padding(.bottom, 20)

            // Smaksikoner
            HStack(spacing: 0) {
                let notes = cigar.flavorNotes ?? []
                let icons = notesWithIcons(notes)
                ForEach(Array(icons.prefix(4).enumerated()), id: \.offset) { _, pair in
                    VStack(spacing: 9) {
                        Image(systemName: pair.icon)
                            .font(.system(size: 22))
                            .foregroundColor(pair.isEmpty ? textSubtle.opacity(0.35) : textPrimary)
                            .frame(width: 26, height: 26)
                        Text(pair.label)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(pair.isEmpty ? textSubtle.opacity(0.35) : textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 18)
        }
        .background(surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .frame(maxWidth: .infinity)
        .frame(minHeight: 144)
    }

    private struct NoteIcon {
        let label: String
        let icon: String
        let isEmpty: Bool
    }

    private func notesWithIcons(_ notes: [String]) -> [NoteIcon] {
        let placeholders: [(String, String)] = [
            ("Kakao", "cup.and.saucer.fill"),
            ("Tre", "tree.fill"),
            ("Seder", "leaf.fill"),
            ("Kanel", "flame.fill")
        ]
        if notes.isEmpty {
            return placeholders.map { NoteIcon(label: $0.0, icon: $0.1, isEmpty: true) }
        }
        return notes.prefix(4).map { note -> NoteIcon in
            let l = note.lowercased()
            let icon: String
            if l.contains("cocoa") || l.contains("chocolate") || l.contains("kakao") { icon = "cup.and.saucer.fill" }
            else if l.contains("wood") || l.contains("cedar") || l.contains("tre") || l.contains("seder") { icon = "tree.fill" }
            else if l.contains("coffee") || l.contains("espresso") || l.contains("kaffe") { icon = "cup.and.saucer.fill" }
            else if l.contains("spice") || l.contains("cinnamon") || l.contains("pepper") || l.contains("kanel") { icon = "flame.fill" }
            else if l.contains("earth") || l.contains("leather") || l.contains("jord") { icon = "globe.europe.africa.fill" }
            else if l.contains("fruit") || l.contains("cherry") || l.contains("frukt") { icon = "leaf.fill" }
            else if l.contains("cream") || l.contains("vanilla") { icon = "drop.fill" }
            else if l.contains("nut") || l.contains("almond") { icon = "leaf.circle.fill" }
            else { icon = "circle.fill" }
            return NoteIcon(label: note, icon: icon, isEmpty: false)
        }
    }

    // ── Ratings section ─────────────────────────────────────────────────────
    @ViewBuilder
    private var ratingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ratingBar(label: "STYRKE",           value: cigar.strength ?? 2.0)
            ratingBar(label: "KROPP",            value: cigar.body ?? 2.0)
            ratingBar(label: "SMAKSINTENSITET",  value: cigar.flavorIntensity ?? 2.0)
            ratingBar(label: "SØDME",            value: cigar.sweetness ?? 2.0)
        }
    }

    @ViewBuilder
    private func ratingBar(label: String, value: Double) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(textSubtle)
                .tracking(0.5)
                .lineLimit(1)
                .frame(width: 110, alignment: .leading)
            HStack(spacing: 5) {
                ForEach(1...5, id: \.self) { i in
                    Capsule()
                        .fill(Double(i) <= value ? action : surfacePrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 8)
                }
            }
        }
    }

    // ── Construction section ─────────────────────────────────────────────────
    @ViewBuilder
    private var constructionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            constructionRow(label: "Wrapper", value: wrapperText)
            constructionRow(label: "Binder",  value: cigar.binder ?? "—")
            constructionRow(label: "Filler",  value: cigar.filler?.joined(separator: ", ") ?? "—")
        }
    }

    @ViewBuilder
    private func constructionRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Text(label)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(textSecondary)
                .frame(width: 88, alignment: .leading)
            Text(value)
                .font(.system(size: 16))
                .foregroundColor(textSecondary)
                .multilineTextAlignment(.leading)
            Spacer()
        }
    }

    private var wrapperText: String {
        var parts: [String] = []
        if let w = cigar.wrapperLeaf    { parts.append(w) }
        if let c = cigar.wrapperCountry { parts.append("(\(c))") }
        return parts.isEmpty ? "—" : parts.joined(separator: " ")
    }

    // ── Price section ────────────────────────────────────────────────────────
    @ViewBuilder
    private var priceSection: some View {
        if let price = cigar.priceRange {
            VStack(alignment: .leading, spacing: 10) {
                Text("PRISESTIMAT")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(textSubtle)
                    .tracking(0.6)
                Text(price)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(textPrimary)
                    .tracking(-0.48)
            }
        }
    }

    // ── Helpers ──────────────────────────────────────────────────────────────
    private func saveQuantity() {
        guard let entry else { return }
        Task { try? await humidorService.updateQuantity(entryId: entry.id, quantity: quantity) }
    }

    private func removeEntry() {
        guard let entry else { return }
        isSaving = true
        Task {
            try? await humidorService.removeFromHumidor(entryId: entry.id)
            isSaving = false
        }
    }
}

// MARK: - Preview

#Preview {
    let mockCigar = Cigar(
        id: UUID(),
        brand: "Ashton",
        manufacturer: "General Cigar",
        series: "Classic White Label",
        vitola: "Magnum",
        commonFormat: "Robusto",
        wrapperCountry: "Ecuador",
        wrapperLeaf: "Connecticut Shade",
        binder: "Dominican Republic",
        filler: ["Dominican Republic", "Honduras"],
        strength: 2.5,
        body: 3.5,
        sweetness: 2.0,
        flavorIntensity: 2.5,
        countryOrigin: "Dominican Republic",
        flavorNotes: ["Cocoa", "Wood", "Cedar", "Cinnamon"],
        description: nil,
        bandImageUrl: nil,
        productImageUrl: nil,
        priceRange: "132,-",
        avgRating: 4.2,
        ringGauge: 50,
        lengthInches: 5.0,
        shape: "Parejo",
        crossSection: nil,
        bodyType: nil,
        headType: nil,
        footType: nil,
        createdAt: nil
    )

    let mockEntry = HumidorEntry(
        id: UUID(),
        userId: UUID(),
        cigarId: mockCigar.id,
        quantity: 5,
        purchaseDate: Calendar.current.date(byAdding: .month, value: -2, to: Date()),
        addedToHumidorAt: Calendar.current.date(byAdding: .month, value: -2, to: Date()),
        purchasePrice: nil,
        storageNotes: nil,
        createdAt: Date(),
        photoURL: nil,
        cigar: mockCigar
    )

    NavigationStack {
        CigarDetailViewDesign(cigar: mockCigar, entry: mockEntry)
    }
    .environmentObject(AuthService())
}
