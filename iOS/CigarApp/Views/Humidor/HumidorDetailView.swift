import SwiftUI
import PhotosUI
import Kingfisher

// MARK: - HumidorDetailView
// Viser sigarene i én humidor. Per-sigar kontekstmeny for å flytte mellom humidorer.
// Toolbar: rediger / slett humidor (med bekreftelse).

struct HumidorDetailView: View {

    let humidor: Humidor
    let allHumidors: [Humidor]
    var onChanged: () -> Void

    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    private let humidorService = HumidorService()

    @State private var entries: [HumidorEntry] = []
    @State private var isLoading = true
    @State private var showEdit = false
    @State private var showDeleteConfirm = false

    // RH (relativ luftfuktighet)
    @State private var readings: [HumidorRHReading] = []
    @State private var showRHSheet = false

    // Bilde (cover) — kan lastes opp direkte fra denne visningen
    @State private var coverURL: String?
    @State private var coverItem: PhotosPickerItem?
    @State private var isUploadingCover = false
    @State private var cropRequest: CropRequest?

    private var visibleEntries: [HumidorEntry] {
        entries.filter { $0.quantity > 0 }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                heroImage

                // Navn + metadata (samme stil som origin/vitola i sigar-detalj)
                VStack(alignment: .leading, spacing: 18) {
                    Text(humidor.name)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(Color("TextPrimary"))
                        .tracking(-0.4)

                    VStack(alignment: .leading, spacing: 10) {
                        if let type = humidor.typeEnum {
                            infoRow(icon: type.icon, text: type.displayName)
                        }
                        if let loc = humidor.location, !loc.isEmpty {
                            infoRow(icon: "mappin", text: loc)
                        }
                        infoRowAsset(asset: "CigarCount", text: capacityLabel)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                rhSection
                    .padding(.top, 24)

                cigarListSection
                    .padding(.top, 28)
            }
            .padding(.bottom, 48)
        }
        .background(Color("Background"))
        .overlay {
            if isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(humidor.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEdit = true } label: { Label("Rediger humidor", systemImage: "pencil") }
                    Button(role: .destructive) { showDeleteConfirm = true } label: {
                        Label("Slett humidor", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog("Slett humidoren «\(humidor.name)»?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Slett humidor", role: .destructive) { deleteHumidor() }
            Button("Avbryt", role: .cancel) {}
        } message: {
            Text("Humidoren slettes. Sigarene beholdes, men blir ikke lenger tilknyttet en humidor.")
        }
        .sheet(isPresented: $showEdit) {
            if let userId = authService.userId {
                CreateHumidorSheet(existing: humidor, userId: userId, onSaved: {
                    onChanged()
                    Task { await load() }
                })
            }
        }
        .sheet(isPresented: $showRHSheet) {
            RHReadingSheet(humidorId: humidor.id, onSaved: { Task { await load() } })
        }
        .onChange(of: coverItem) { _, item in
            guard let item else { return }
            Task {
                if let raw = try? await item.loadTransferable(type: Data.self),
                   let img = UIImage(data: raw) {
                    cropRequest = CropRequest(image: img, ratio: 1.7)  // bredt cover
                }
                coverItem = nil
            }
        }
        .fullScreenCover(item: $cropRequest) { req in
            ImageCropper(image: req.image, ratio: req.ratio) { cropped in
                cropRequest = nil
                Task { await uploadCover(cropped) }
            } onCancel: {
                cropRequest = nil
            }
            .ignoresSafeArea()
        }
        .task { await load() }
        .refreshable { await load() }
    }

    // ── Hero image (som i sigar-detalj) ──────────────────────────────────────
    @ViewBuilder
    private var heroImage: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let urlStr = coverURL, let url = URL(string: urlStr) {
                    KFImage(url)
                        .resizable()
                        .placeholder { heroPlaceholder }
                        .fade(duration: 0.15)
                        .scaledToFill()
                        .id(urlStr)
                } else {
                    // Ingen bilde → "Last opp bilde" i midten
                    Rectangle()
                        .fill(LinearGradient(colors: [Color("Surface"), Color("Background")],
                                             startPoint: .top, endPoint: .bottom))
                        .overlay {
                            PhotosPicker(selection: $coverItem, matching: .images) {
                                UploadPhotoPlaceholder(isBusy: isUploadingCover)
                            }
                        }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .clipped()

            // "Endre"-pille (felles stil) — kun når det finnes et bilde
            if coverURL != nil {
                PhotosPicker(selection: $coverItem, matching: .images) {
                    EditPhotoPill(isBusy: isUploadingCover)
                }
            }
        }
    }

    private var heroPlaceholder: some View {
        Rectangle()
            .fill(LinearGradient(colors: [Color("Surface"), Color("Background")],
                                 startPoint: .top, endPoint: .bottom))
            .overlay {
                Image(systemName: humidor.typeEnum?.icon ?? "archivebox")
                    .font(.system(size: 46))
                    .foregroundColor(Color("Accent").opacity(0.5))
            }
    }

    @ViewBuilder
    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundColor(Color("TextPrimary"))
                .frame(width: 20, alignment: .center)
            Text(text)
                .font(.system(size: 18))
                .foregroundColor(Color("TextPrimary"))
        }
    }

    // Variant med et asset-ikon (f.eks. sigar-ikonet) i stedet for SF Symbol.
    @ViewBuilder
    private func infoRowAsset(asset: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(asset)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 19)
                .foregroundColor(Color("TextPrimary"))
                .frame(width: 20, alignment: .center)
            Text(text)
                .font(.system(size: 18))
                .foregroundColor(Color("TextPrimary"))
        }
    }

    // ── RH-seksjon (relativ luftfuktighet) ───────────────────────────────────
    @ViewBuilder
    private var rhSection: some View {
        let latest = readings.first
        VStack(alignment: .leading, spacing: 10) {
            Text("LUFTFUKTIGHET (RH)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color("TextSecondary")).tracking(0.6)
                .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        if let latest {
                            Text("\(rhString(latest.rh)) % RH")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(Color("TextPrimary"))
                        } else {
                            Text("— % RH")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(Color("TextSecondary"))
                        }
                        if let target = humidor.rhTargetLabel {
                            Text("Mål: \(target)").font(.caption).foregroundColor(Color("TextSecondary"))
                        }
                    }
                    Spacer()
                    statusBadge(humidor.rhStatus(for: latest?.rh))
                }

                if let latest {
                    HStack(spacing: 6) {
                        Text("Sist målt \(relativeDate(latest.measuredAt))")
                        if latest.isStale {
                            Text("· Ikke målt nylig").foregroundColor(Color("Accent"))
                        }
                    }
                    .font(.caption).foregroundColor(Color("TextSecondary"))
                }

                Button { showRHSheet = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                        Text("Registrer RH").fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(Color("Accent").opacity(0.12))
                    .foregroundColor(Color("Accent"))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(16)
            .background(Color("Card"))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.horizontal, 16)

            if !readings.isEmpty {
                Text("Historikk")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color("TextSecondary")).tracking(0.6)
                    .padding(.horizontal, 20).padding(.top, 8)

                VStack(spacing: 0) {
                    let shown = Array(readings.prefix(20))
                    ForEach(shown) { r in
                        HStack(spacing: 8) {
                            Text("\(rhString(r.rh)) %")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color("TextPrimary"))
                            if let t = r.temperature {
                                Text("· \(rhString(t)) °C").font(.caption).foregroundColor(Color("TextSecondary"))
                            }
                            if let note = r.note, !note.isEmpty {
                                Text("· \(note)").font(.caption).foregroundColor(Color("TextSecondary")).lineLimit(1)
                            }
                            Spacer()
                            Text(relativeDate(r.measuredAt)).font(.caption).foregroundColor(Color("TextSecondary"))
                        }
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        if r.id != shown.last?.id { Divider().padding(.leading, 16) }
                    }
                }
                .background(Color("Card"))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.horizontal, 16)
            }
        }
    }

    @ViewBuilder
    private func statusBadge(_ status: RHStatus) -> some View {
        let color: Color = {
            switch status {
            case .stable:            return Color("Accent")
            case .none:              return Color(.secondaryLabel)
            case .tooDry, .tooWet:   return Color(.label)
            default:                 return Color(.label)
            }
        }()
        Text(status.label)
            .font(.caption.weight(.semibold))
            .foregroundColor(color)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private func rhString(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.1f", v)
    }

    private func relativeDate(_ d: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "nb_NO")
        f.unitsStyle = .full
        return f.localizedString(for: d, relativeTo: Date())
    }

    // ── Sigarliste ───────────────────────────────────────────────────────────
    @ViewBuilder
    private var cigarListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SIGARER")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color("TextSecondary"))
                .tracking(0.6)
                .padding(.horizontal, 20)

            if visibleEntries.isEmpty && !isLoading {
                VStack(spacing: 12) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 44))
                        .foregroundColor(Color("TextSecondary").opacity(0.5))
                    Text("Ingen sigarer her ennå")
                        .font(.headline)
                        .foregroundColor(Color("TextPrimary"))
                    Text("Legg til sigarer fra Utforsk eller scan,\nog velg denne humidoren.")
                        .font(.subheadline)
                        .foregroundColor(Color("TextSecondary"))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .padding(.horizontal, 32)
            } else {
                VStack(spacing: 0) {
                    ForEach(visibleEntries) { entry in
                        if let cigar = entry.cigar {
                            NavigationLink(destination: CigarDetailViewDesign(cigar: cigar, humidorEntry: entry)) {
                                HumidorRow(entry: entry)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                if allHumidors.count > 1 {
                                    Menu {
                                        ForEach(allHumidors.filter { $0.id != humidor.id }) { h in
                                            Button(h.name) { move(entry, to: h.id) }
                                        }
                                    } label: {
                                        Label("Flytt til humidor", systemImage: "arrow.right.arrow.left")
                                    }
                                }
                                Button(role: .destructive) { remove(entry) } label: {
                                    Label("Fjern fra humidor", systemImage: "trash")
                                }
                            }
                            if entry.id != visibleEntries.last?.id {
                                Divider().padding(.leading, 16)
                            }
                        }
                    }
                }
                .background(Color("Card"))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.horizontal, 16)
            }
        }
    }

    private var capacityLabel: String {
        let count = visibleEntries.reduce(0) { $0 + $1.quantity }
        if let cap = humidor.capacity {
            return "\(count)/\(cap)"
        }
        return "\(count) sigarer"
    }

    private func load() async {
        if coverURL == nil { coverURL = humidor.imageURL }
        guard let userId = authService.userId else { isLoading = false; return }
        isLoading = true
        let all = (try? await humidorService.fetchHumidor(userId: userId)) ?? []
        entries = all.filter { $0.humidorId == humidor.id }
        readings = (try? await humidorService.fetchRHReadings(humidorId: humidor.id)) ?? []
        isLoading = false
    }

    private func uploadCover(_ image: UIImage) async {
        guard let userId = authService.userId,
              let data = image.jpegData(compressionQuality: 1.0) else { return }
        isUploadingCover = true
        defer { isUploadingCover = false }
        if let newURL = await attempt("Last opp humidor-cover", {
            try await humidorService.uploadHumidorCover(
                humidorId: humidor.id, userId: userId, imageData: data)
        }) {
            coverURL = newURL
            onChanged()
        }
    }

    private func move(_ entry: HumidorEntry, to humidorId: UUID) {
        Task {
            try? await humidorService.moveEntry(entryId: entry.id, toHumidorId: humidorId)
            await load()
            onChanged()
        }
    }

    private func remove(_ entry: HumidorEntry) {
        Task {
            try? await humidorService.removeFromHumidor(entryId: entry.id)
            await load()
            onChanged()
        }
    }

    private func deleteHumidor() {
        Task {
            await attempt("Slett humidor") {
                try await humidorService.deleteHumidor(id: humidor.id)
            }
            onChanged()
            dismiss()
        }
    }
}

// MARK: - RHReadingSheet
// Registrer én RH-måling. Brukeren skriver inn selve målingen — appen måler ikke
// automatisk. Standard tidspunkt = nå.

struct RHReadingSheet: View {

    let humidorId: UUID
    var onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    private let humidorService = HumidorService()

    @State private var rhText = ""
    @State private var tempText = ""
    @State private var note = ""
    @State private var measuredAt = Date()
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var rhValue: Double? { Double(rhText.replacingOccurrences(of: ",", with: ".")) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("F.eks. 68", text: $rhText).keyboardType(.decimalPad)
                        Text("% RH").foregroundColor(Color("TextSecondary"))
                    }
                } header: {
                    Text("Målt RH")
                } footer: {
                    Text("RH = relativ luftfuktighet, altså hvor fuktig det er inne i humidoren akkurat nå. Du registrerer selve målingen fra hygrometeret ditt — appen måler ikke automatisk.")
                }

                Section("Temperatur (valgfritt)") {
                    HStack {
                        TextField("F.eks. 20", text: $tempText).keyboardType(.decimalPad)
                        Text("°C").foregroundColor(Color("TextSecondary"))
                    }
                }

                Section("Tidspunkt") {
                    DatePicker("Målt", selection: $measuredAt, in: ...Date(),
                               displayedComponents: [.date, .hourAndMinute])
                }

                Section("Notat (valgfritt)") {
                    TextField("F.eks. etter bytte av Boveda", text: $note, axis: .vertical)
                        .lineLimit(2...5)
                }

                if let errorMessage {
                    Section { Text(errorMessage).font(.caption).foregroundColor(.red) }
                }
            }
            .navigationTitle("Registrer RH")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Avbryt") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lagre") { save() }
                        .fontWeight(.semibold)
                        .disabled(rhValue == nil || isSaving)
                }
            }
        }
    }

    private func save() {
        guard let rh = rhValue else { return }
        let temp = Double(tempText.replacingOccurrences(of: ",", with: "."))
        isSaving = true
        errorMessage = nil
        Task {
            do {
                try await humidorService.addRHReading(
                    humidorId: humidorId, rh: rh, temperature: temp,
                    note: note.trimmingCharacters(in: .whitespacesAndNewlines), measuredAt: measuredAt
                )
                onSaved()
                dismiss()
            } catch {
                errorMessage = "Kunne ikke lagre målingen. Prøv igjen."
            }
            isSaving = false
        }
    }
}
