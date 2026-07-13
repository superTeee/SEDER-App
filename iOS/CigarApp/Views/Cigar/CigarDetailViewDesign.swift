import SwiftUI
import PhotosUI
import UIKit
import Kingfisher

// MARK: - CigarDetailViewDesign
// Pixel-perfect implementasjon fra Figma-design (node 184:197)
// Mørkt tema: bg #131211, surface #24221e, accent #a79164

struct CigarDetailViewDesign: View {

    let cigar: Cigar
    @State private var entry: HumidorEntry?
    let onScanNext: (() -> Void)?

    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var quantity: Int
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isUploadingPhoto = false
    @State private var cropRequest: CropRequest?
    @State private var showSmokingSheet = false
    @State private var showRemoveAlert = false
    @State private var isSaving = false
    @State private var showAddToHumidorSheet = false
    @State private var isInWishlist = false
    @State private var isWishlistLoading = false
    @State private var showLogSmokedSheet = false
    @State private var showLoginSheet = false
    @State private var showLoggedToast = false
    @State private var showReportSheet = false
    @AppStorage("humidorHasNew") private var humidorHasNew: Bool = false

    private let humidorService = HumidorService()
    private let wishlistService = WishlistService()

    // ── Design-tokens fra Figma ─────────────────────────────────────────────
    // Adaptive farger — følger lys/mørk modus via asset-katalogen
    private let pageBg        = Color("Background")
    private let surfacePrimary = Color("Surface")
    private let action        = Color("Accent")
    private let textPrimary   = Color("TextPrimary")
    private let textSecondary = Color("TextSecondary")
    private let textSubtle    = Color("TextSecondary")

    // Smaksnote-ikoner: fast #8F7B51 i lys modus, accent i mørk modus
    private var flavorIconColor: Color {
        colorScheme == .dark ? Color("Accent") : Color(hex: "#8F7B51")
    }

    init(cigar: Cigar, humidorEntry: HumidorEntry? = nil, onScanNext: (() -> Void)? = nil) {
        self.cigar = cigar
        self.onScanNext = onScanNext
        _entry = State(initialValue: humidorEntry)
        _quantity = State(initialValue: humidorEntry?.quantity ?? 1)
    }

    // ── Body ────────────────────────────────────────────────────────────────
    var body: some View {
        ZStack(alignment: .top) {
            pageBg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    if entry != nil { heroImage }
                    contentBody
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle(cigar.brand)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
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
                SmokingLogSheet(cigar: cigar, userId: authService.userId) { smokedAt, rating, smokeAgain, draw, burn, flavor, notes, photoData, cutType, store in
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
                                cutType: cutType,
                                store: store
                            )
                            if let data = photoData {
                                let ts = TastingService()
                                await attempt("Last opp loggbilde") {
                                    try await ts.uploadLogPhoto(logId: logId, userId: userId, imageData: data)
                                }
                            }
                            await MainActor.run { confirmLogged() }
                        } catch { print("Røyke-logg feil: \(error)") }
                        quantity = max(0, quantity - 1)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddToHumidorSheet) {
            AddToHumidorSheet(cigar: cigar, userId: authService.userId) { purchasedAt, addedAt, qty, humidorId, store in
                guard let userId = authService.userId else { return }
                isSaving = true
                Task {
                    do {
                        let newEntry = try await humidorService.addToHumidor(
                            cigarId: cigar.id, userId: userId, humidorId: humidorId, quantity: qty,
                            purchasedAt: purchasedAt, addedToHumidorAt: addedAt, store: store)
                        self.entry = newEntry
                        self.quantity = newEntry.quantity
                        humidorHasNew = true
                    } catch { print("Feil ved lagring: \(error)") }
                    isSaving = false
                }
            }
        }
        .sheet(isPresented: $showLogSmokedSheet) {
            SmokingLogSheet(cigar: cigar, userId: authService.userId) { smokedAt, rating, smokeAgain, draw, burn, flavor, notes, photoData, cutType, store in
                guard let userId = authService.userId else { return }
                Task {
                    do {
                        let logId = try await humidorService.logTastingForCigar(
                            cigarId: cigar.id, userId: userId, smokedAt: smokedAt,
                            rating: rating, smokeAgain: smokeAgain, drawRating: draw,
                            burnRating: burn, flavorRating: flavor, notes: notes, cutType: cutType, store: store)
                        if let data = photoData {
                            let ts = TastingService()
                            await attempt("Last opp loggbilde") {
                                try await ts.uploadLogPhoto(logId: logId, userId: userId, imageData: data)
                            }
                        }
                        await MainActor.run { confirmLogged() }
                    } catch { print("Treff-logg feil: \(error)") }
                }
            }
        }
        .sheet(isPresented: $showLoginSheet) {
            AuthView(onSuccess: { showAddToHumidorSheet = true })
        }
        .overlay(alignment: .bottom) {
            if showLoggedToast {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Logget i journalen").fontWeight(.semibold)
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 18).padding(.vertical, 12)
                .background(Color("Accent"))
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.2), radius: 8, y: 2)
                .padding(.bottom, 28)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let raw = try? await newItem.loadTransferable(type: Data.self),
                   let img = UIImage(data: raw) {
                    cropRequest = CropRequest(image: img, ratio: 1.6)  // bredt hero-bilde
                }
                selectedPhotoItem = nil
            }
        }
        .fullScreenCover(item: $cropRequest) { req in
            ImageCropper(image: req.image, ratio: req.ratio) { cropped in
                cropRequest = nil
                uploadPhoto(cropped)
            } onCancel: {
                cropRequest = nil
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showReportSheet) {
            CigarReportSheet(cigar: cigar)
                .environmentObject(authService)
        }
        .onAppear {
            guard entry == nil, let userId = authService.userId else { return }
            Task {
                isInWishlist = (try? await wishlistService.isInWishlist(userId: userId, cigarId: cigar.id)) ?? false
            }
        }
    }

    // Har sigaren et bilde (enten opplastet i humidor eller produktbilde)?
    private var hasPhoto: Bool {
        if let p = entry?.photoURL, !p.isEmpty { return true }
        if let p = cigar.productImageUrl, !p.isEmpty { return true }
        return false
    }

    // ── Hero image ──────────────────────────────────────────────────────────
    @ViewBuilder
    private var heroImage: some View {
        ZStack(alignment: .topTrailing) {
            // Bilde
            Group {
                if let photoURL = entry?.photoURL, let url = URL(string: photoURL) {
                    KFImage(url)
                        .resizable()
                        .placeholder { Rectangle().fill(surfacePrimary) }
                        .fade(duration: 0.15)
                        .scaledToFill()
                        .id(photoURL)
                } else if let productURL = cigar.productImageUrl, let url = URL(string: productURL) {
                    KFImage(url)
                        .resizable()
                        .placeholder { Rectangle().fill(surfacePrimary) }
                        .fade(duration: 0.15)
                        .scaledToFill()
                } else if entry != nil {
                    // I humidor uten bilde → "Last opp bilde" i midten
                    Rectangle()
                        .fill(LinearGradient(colors: [surfacePrimary, pageBg], startPoint: .top, endPoint: .bottom))
                        .overlay {
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                UploadPhotoPlaceholder(isBusy: isUploadingPhoto)
                            }
                        }
                } else {
                    // Ikke i humidor, ingen bilde → nøytralt sigarikon
                    Rectangle()
                        .fill(LinearGradient(colors: [surfacePrimary, pageBg], startPoint: .top, endPoint: .bottom))
                        .overlay {
                            CigarIcon(color: textSubtle.opacity(0.3))
                                .frame(width: 60, height: 60)
                        }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 240)
            .clipped()

            // "Endre"-pille (felles stil) — kun for humidor-entry med et bilde
            if entry != nil, hasPhoto {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    EditPhotoPill(isBusy: isUploadingPhoto)
                }
            }
        }
        // Quantity-pill flytende i nederkant av bildet (50% overlapp)
        .overlay(alignment: .bottom) {
            quantityPill
                .offset(y: 28)
        }
    }

    // ── Quantity pill ───────────────────────────────────────────────────────
    @ViewBuilder
    private var quantityPill: some View {
        ZStack {
            Capsule()
                .fill(surfacePrimary)
                .shadow(color: colorScheme == .dark ? .black.opacity(0.3) : .clear,
                        radius: colorScheme == .dark ? 4 : 0, x: 0, y: colorScheme == .dark ? 2 : 0)
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
                .padding(.horizontal, 6)
            mainNotesCard
            constructionSection
                .padding(.horizontal, 6)
            ratingsSection
                .padding(.horizontal, 6)
            if let description = cigar.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(textSecondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 6)
            }

            // Sier ærlig fra om spesifikasjonene er sjekket mot en kilde,
            // og lar brukeren rette oss når de ikke er det.
            if cigar.isPrivate {
                PrivateCigarBadge()
                    .padding(.horizontal, 6)
            } else {
                VerificationBadge(cigar: cigar) {
                    guard authService.userId != nil else { showLoginSheet = true; return }
                    showReportSheet = true
                }
                .padding(.horizontal, 6)
            }

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
                VStack(spacing: 12) {
                    Button {
                        guard authService.userId != nil else { showLoginSheet = true; return }
                        showAddToHumidorSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "archivebox.fill")
                            Text("Legg i humidor").fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(action).foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    Button {
                        guard authService.userId != nil else { showLoginSheet = true; return }
                        showLogSmokedSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "flame.fill")
                            Text("Marker som røkt").fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(surfacePrimary).foregroundColor(action)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    Button { toggleWishlist() } label: {
                        HStack {
                            if isWishlistLoading { ProgressView().tint(action) }
                            else { Image(systemName: isInWishlist ? "bookmark.fill" : "bookmark") }
                            Text(isInWishlist ? "I ønskelisten" : "Legg i ønskeliste").fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(surfacePrimary).foregroundColor(action)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .disabled(isWishlistLoading)
                    if let onScanNext {
                        Button { onScanNext() } label: {
                            HStack {
                                Image(systemName: "camera.viewfinder")
                                Text("Scan neste sigar").fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(surfacePrimary).foregroundColor(action)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, entry != nil ? 48 : 20) // plass til quantity-pill kun i humidor
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
                if let origin = cigar.countryOrigin {
                    infoRow(icon: "mappin", text: origin)
                }
                let hasSize = cigar.ringGauge != nil && cigar.lengthInches != nil
                // Vis frittstående vitola kun når størrelse-raden ikke vises —
                // størrelse-raden inneholder allerede vitola-navnet + målene.
                if let vitola = cigar.vitola, !hasSize {
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
                if let purchased = entry?.purchaseDate {
                    infoRow(icon: "cart.fill",
                            text: purchased.formatted(.dateTime.day().month(.wide).year()))
                }
                if let added = entry?.addedToHumidorAt {
                    infoRow(icon: "archivebox.fill",
                            text: added.formatted(.dateTime.day().month(.wide).year()))
                }
            }
        }
    }

    @ViewBuilder
    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundColor(textPrimary)
                .frame(width: 20, alignment: .center)
            Text(text)
                // 2px større enn konstruksjons-radene (wrapper/binder) — dette er viktigere info.
                .font(.system(size: 18))
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
                Text("SMAKSNOTER")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(textSubtle)
                    .tracking(0.6)
                Spacer()
            }
            .padding(.horizontal, 19)
            .padding(.top, 17)
            .padding(.bottom, 20)

            // Smaksikoner
            let notes = cigar.flavorNotes ?? []
            let icons = notesWithIcons(notes)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 4), spacing: 18) {
                ForEach(Array(icons.enumerated()), id: \.offset) { _, pair in
                    VStack(spacing: 5) {
                        Image(pair.icon)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(pair.isEmpty ? textSubtle.opacity(0.35) : flavorIconColor)
                        Text(pair.label)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(pair.isEmpty ? textSubtle.opacity(0.35) : textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 22)
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
        // Tom-tilstand: vis noen representative ikoner dempet
        let placeholders = ["cocoa", "cedar", "leather", "pepper"]
        func empty() -> [NoteIcon] {
            placeholders.map { NoteIcon(label: FlavorIcon.displayLabel(for: $0), icon: $0, isEmpty: true) }
        }
        if notes.isEmpty { return empty() }

        // Map til ikon, deduper på ikon-familie, maks 5, norske etiketter
        var seen = Set<String>()
        var result: [NoteIcon] = []
        for note in notes {
            guard let icon = FlavorIcon.name(for: note), !seen.contains(icon) else { continue }
            seen.insert(icon)
            result.append(NoteIcon(label: FlavorIcon.displayLabel(for: icon), icon: icon, isEmpty: false))
            if result.count == 8 { break }
        }
        return result.isEmpty ? empty() : result
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
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(textSubtle)
                .tracking(0.5)
                .lineLimit(1)
            HStack(spacing: 9) {
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

    // ── Helpers ──────────────────────────────────────────────────────────────
    private func saveQuantity() {
        guard let entry else { return }
        Task {
            await attempt("Oppdater antall") {
                try await humidorService.updateQuantity(entryId: entry.id, quantity: quantity)
            }
        }
    }

    // Laster opp croppet sigarbilde (kun for sigarer i humidor).
    private func uploadPhoto(_ image: UIImage) {
        guard let entry, let userId = authService.userId,
              let data = image.jpegData(compressionQuality: 1.0) else { return }
        Task {
            isUploadingPhoto = true
            defer { isUploadingPhoto = false }
            if let url = await attempt("Last opp sigarbilde", {
                try await humidorService.uploadPhoto(entryId: entry.id, userId: userId, imageData: data)
            }) {
                self.entry?.photoURL = url
            }
        }
    }

    private func confirmLogged() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation { showLoggedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showLoggedToast = false }
        }
    }

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
            } catch { print("Ønskeliste-feil: \(error)") }
            isWishlistLoading = false
        }
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
        createdAt: nil,
        sourceUrl: nil,
        verifiedAt: nil,
        sourceTier: nil,
        createdBy: nil,
        isPublic: true
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
        store: nil,
        createdAt: Date(),
        photoURL: nil,
        cigar: mockCigar
    )

    NavigationStack {
        CigarDetailViewDesign(cigar: mockCigar, humidorEntry: mockEntry)
    }
    .environmentObject(AuthService())
}
