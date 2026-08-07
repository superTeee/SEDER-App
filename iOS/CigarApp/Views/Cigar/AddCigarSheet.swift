import SwiftUI

// MARK: - Legg til sigar
//
// Finner du ikke sigaren, skal du ikke bli stående fast. Du legger den inn selv,
// og den virker umiddelbart i din humidor og journal.
//
// Men FØRST prøver vi å koble deg til en sigar som allerede finnes i basen:
// mens du skriver merke og serie foreslår vi treff fra oppslagsverket, og velger
// du ett av dem, kobles oppføringen rett til den eksisterende raden — med ferdig
// metadata (land, dekkblad, styrke ...). Det er nettopp dette som redder deg når
// skanneren ikke fant et grafisk bånd uten tekst: skriv «Cavalier» → «White
// Series», og velg den faktiske sigaren fra basen.
//
// Skriver du inn en sigar som IKKE finnes, opprettes raden privat
// (`is_public = false`, `created_by = deg`), og et forslag sendes til review-køen.
// Godkjennes det, blir den en del av basen for alle. Uten det skillet ville
// databasen blitt full av dubletter og gjetninger.

struct AddCigarSheet: View {

    /// Forhåndsutfylt merke eller søketekst, hvis brukeren kom fra et tomt søk.
    var prefillBrand: String = ""

    /// Forhåndsutfylt notat (f.eks. OCR-tekst fra et skann som ikke ga treff).
    var prefillNote: String = ""

    /// Kalles med sigaren når den er opprettet ELLER koblet til en eksisterende rad.
    var onCreated: (Cigar) -> Void = { _ in }

    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var brand = ""
    @State private var series = ""
    @State private var vitola = ""
    @State private var country = ""
    @State private var wrapper = ""
    @State private var ringGauge = ""
    @State private var lengthInches = ""
    @State private var note = ""
    @State private var suggestToDatabase = true

    @State private var isSaving = false
    @State private var errorMessage: String?

    // Autocomplete-tilstand
    private enum Field: Hashable { case brand, series, vitola }
    @FocusState private var focus: Field?
    @State private var brandMatches: [String] = []   // merke-forslag mens du skriver merke
    @State private var seriesMatches: [String] = []  // serie-forslag for valgt merke
    @State private var dbCigars: [Cigar] = []        // eksisterende offentlige sigarer å koble til
    @State private var searchTask: Task<Void, Never>? = nil

    private let cigarService = CigarService()

    // Vanlige vitolaer med typisk størrelse (ringmål × lengde i tommer).
    // Trykk på en chip → fyller format + forhåndsutfyller mål (kan justeres).
    private struct VitolaPreset { let name: String; let ring: Int; let length: Double }
    private let vitolaPresets: [VitolaPreset] = [
        .init(name: "Robusto",        ring: 50, length: 5.0),
        .init(name: "Toro",           ring: 52, length: 6.0),
        .init(name: "Churchill",      ring: 48, length: 7.0),
        .init(name: "Corona",         ring: 42, length: 5.5),
        .init(name: "Petit Corona",   ring: 42, length: 4.5),
        .init(name: "Lonsdale",       ring: 42, length: 6.5),
        .init(name: "Double Corona",  ring: 49, length: 7.5),
        .init(name: "Torpedo",        ring: 52, length: 6.1),
        .init(name: "Belicoso",       ring: 52, length: 5.5),
        .init(name: "Rothschild",     ring: 50, length: 4.5),
        .init(name: "Gordo",          ring: 60, length: 6.0),
        .init(name: "Lancero",        ring: 38, length: 7.5),
        .init(name: "Panetela",       ring: 38, length: 6.0),
        .init(name: "Perfecto",       ring: 48, length: 5.0),
        .init(name: "Culebra",        ring: 38, length: 5.75),
    ]

    private func lengthText(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(v)
    }

    private var canSave: Bool {
        !brand.trimmingCharacters(in: .whitespaces).isEmpty && !isSaving
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Merke", text: $brand)
                        .textInputAutocapitalization(.words)
                        .focused($focus, equals: .brand)
                        .onChange(of: brand) { _, _ in onBrandChange() }

                    if focus == .brand, !brandMatches.isEmpty {
                        ForEach(brandMatches, id: \.self) { name in
                            Button { pickBrand(name) } label: { suggestionRow(name) }
                                .buttonStyle(.plain)
                        }
                    }

                    TextField("Serie (valgfritt)", text: $series)
                        .textInputAutocapitalization(.words)
                        .focused($focus, equals: .series)
                        .onChange(of: series) { _, _ in onSeriesChange() }

                    if focus == .series, !seriesMatches.isEmpty {
                        ForEach(seriesMatches, id: \.self) { name in
                            Button { pickSeries(name) } label: { suggestionRow(name) }
                                .buttonStyle(.plain)
                        }
                    }

                    TextField("Format eller vitola (valgfritt)", text: $vitola)
                        .textInputAutocapitalization(.words)
                        .focused($focus, equals: .vitola)

                    // Chips med vanlige vitolaer — trykk for å fylle inn format + typisk størrelse.
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(vitolaPresets, id: \.name) { preset in
                                Button {
                                    vitola = preset.name
                                    if ringGauge.trimmingCharacters(in: .whitespaces).isEmpty {
                                        ringGauge = "\(preset.ring)"
                                    }
                                    if lengthInches.trimmingCharacters(in: .whitespaces).isEmpty {
                                        lengthInches = lengthText(preset.length)
                                    }
                                } label: {
                                    Text(preset.name)
                                        .font(.system(size: 13, weight: .medium))
                                        .padding(.horizontal, 12).padding(.vertical, 6)
                                        .background(Capsule().fill(
                                            vitola == preset.name ? Color("Accent") : Color("Accent").opacity(0.12)))
                                        .foregroundColor(vitola == preset.name ? .white : Color("Accent"))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 6, trailing: 8))
                } header: {
                    Text("Sigaren")
                } footer: {
                    Text("Begynn å skrive merket — finnes sigaren i basen fra før, foreslår vi den så du kobler deg rett på med ferdig metadata. Bare merket er påkrevd.")
                }

                // Eksisterende sigarer i basen som matcher det du skriver.
                // Velger du én, kobles oppføringen din direkte til den raden —
                // ingen duplikat, all metadata ferdig utfylt.
                if !dbCigars.isEmpty {
                    Section {
                        ForEach(dbCigars) { c in
                            Button { linkExisting(c) } label: { existingCigarRow(c) }
                                .buttonStyle(.plain)
                        }
                    } header: {
                        Text("Finnes i basen")
                    } footer: {
                        Text("Velg den riktige for å koble sigaren til basen — da unngår vi et duplikat, og land, dekkblad og styrke er allerede fylt ut.")
                    }
                }

                Section("Detaljer") {
                    TextField("Opprinnelsesland", text: $country)
                        .textInputAutocapitalization(.words)
                    TextField("Dekkblad", text: $wrapper)
                        .textInputAutocapitalization(.words)
                    HStack {
                        TextField("Ringmål", text: $ringGauge)
                            .keyboardType(.numberPad)
                        Divider()
                        TextField("Lengde i tommer", text: $lengthInches)
                            .keyboardType(.decimalPad)
                    }
                }

                Section {
                    Toggle("Foreslå for sigardatabasen", isOn: $suggestToDatabase)
                    if suggestToDatabase {
                        TextField("Kilde eller kommentar (valgfritt)", text: $note, axis: .vertical)
                            .lineLimit(2...5)
                    }
                } footer: {
                    Text(suggestToDatabase
                         ? "Sigaren blir din med én gang. Vi sjekker den mot kilden, og godkjennes den blir den synlig for alle."
                         : "Sigaren blir kun liggende i din egen samling.")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                }
            }
            .background(Color("Background"))
            .navigationTitle("Legg til sigar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Avbryt") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving { ProgressView() } else { Text("Lagre").fontWeight(.semibold) }
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                if brand.isEmpty { brand = prefillBrand }
                if note.isEmpty { note = prefillNote }
                if !brand.trimmingCharacters(in: .whitespaces).isEmpty {
                    Task { await refreshDBMatches() }
                }
            }
        }
    }

    // MARK: - Autocomplete-rader

    @ViewBuilder
    private func suggestionRow(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundColor(Color("TextSecondary"))
            Text(text)
                .foregroundColor(Color("Accent"))
            Spacer()
            Image(systemName: "arrow.up.left")
                .font(.system(size: 11))
                .foregroundColor(Color("TextSecondary"))
        }
        .contentShape(Rectangle())
    }

    private func existingSubtitle(_ c: Cigar) -> String {
        [c.series, c.vitola, c.dimensionsLabel]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    @ViewBuilder
    private func existingCigarRow(_ c: Cigar) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(c.brand)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                if !existingSubtitle(c).isEmpty {
                    Text(existingSubtitle(c))
                        .font(.caption)
                        .foregroundColor(Color("TextSecondary"))
                }
            }
            Spacer()
            Image(systemName: "link")
                .font(.system(size: 13))
                .foregroundColor(Color("Accent"))
        }
        .contentShape(Rectangle())
        .padding(.vertical, 2)
    }

    // MARK: - Autocomplete-logikk

    private func onBrandChange() {
        searchTask?.cancel()
        let currentBrand = brand
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            if Task.isCancelled { return }
            let matches = await cigarService.searchBrands(query: currentBrand)
            if Task.isCancelled { return }
            brandMatches = matches.filter { $0.lowercased() != currentBrand.lowercased() }
            await refreshDBMatches()
        }
    }

    private func onSeriesChange() {
        searchTask?.cancel()
        let currentBrand = brand
        let currentSeries = series
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            if Task.isCancelled { return }
            var matches = await cigarService.seriesForBrand(currentBrand)
            let sl = currentSeries.lowercased()
            if !sl.isEmpty {
                matches = matches.filter { $0.lowercased().contains(sl) && $0.lowercased() != sl }
            }
            if Task.isCancelled { return }
            seriesMatches = matches
            await refreshDBMatches()
        }
    }

    private func refreshDBMatches() async {
        let matches = await cigarService.matchingCigars(brand: brand, series: series)
        dbCigars = matches
    }

    private func pickBrand(_ name: String) {
        brand = name
        brandMatches = []
        focus = .series
        Task {
            seriesMatches = await cigarService.seriesForBrand(name)
            await refreshDBMatches()
        }
    }

    private func pickSeries(_ name: String) {
        series = name
        seriesMatches = []
        Task { await refreshDBMatches() }
    }

    /// Koble oppføringen til en eksisterende rad i basen — ingen ny (dublett-)rad.
    private func linkExisting(_ cigar: Cigar) {
        onCreated(cigar)
        dismiss()
    }

    private func save() async {
        guard authService.userId != nil else {
            errorMessage = "Du må være innlogget for å legge til en sigar."
            return
        }
        isSaving = true
        defer { isSaving = false }
        do {
            let cigar = try await cigarService.createOwnCigar(
                brand:        brand,
                series:       series,
                vitola:       vitola,
                country:      country,
                wrapper:      wrapper,
                ringGauge:    Int(ringGauge),
                lengthInches: Double(lengthInches.replacingOccurrences(of: ",", with: ".")),
                note:         note,
                suggest:      suggestToDatabase
            )
            onCreated(cigar)
            dismiss()
        } catch {
            errorMessage = "Kunne ikke lagre sigaren — prøv igjen."
            print("createOwnCigar feilet: \(error)")
        }
    }
}

// MARK: - PrivateCigarBadge
// Vises på detaljsiden for en sigar bare du kan se.

struct PrivateCigarBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.system(size: 11))
            Text("Din egen sigar — kun synlig for deg")
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(Color(.secondaryLabel))
    }
}
