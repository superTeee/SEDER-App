import SwiftUI
import UIKit

// MARK: - ResultsView (SEDER-design)
// Leder med det klareste treffet i et framhevet kort (2 px kant), så et
// nav-kort «Flere fra samme serie» som fører til en egen side, så
// «Andre muligheter» (andre sigarer). Beholder manuelt søk + «legg til
// selv» + «skann på nytt».

struct ResultsView: View {

    let results: [ScanResult]
    let ocrText: String
    // Bånd-bildet fra skanningen — tas videre til CigarDetailViewDesign og
    // brukes som oppføringens bilde + driver bildegjenkjenningen over tid.
    var bandImage: UIImage? = nil
    var onScanNext: (() -> Void)? = nil
    // Merket appen leste ved en bom — forhåndsutfyller «Legg til sigaren selv»
    // når brukeren ikke har søkt på noe annet først.
    var prefillBrand: String? = nil

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService

    @StateObject private var cigarService = CigarService()
    @State private var searchQuery: String = ""
    @State private var searchResults: [Cigar] = []
    @State private var isSearching = false
    @State private var searchError: String?
    @State private var hasSearched = false

    // Alle sigarer fra samme merke (hentes én gang) — brukes til både vitola-
    // velgeren i kortet (samme serie) og «Flere fra samme merke»-kortet.
    @State private var brandCigars: [Cigar] = []
    // Valgt vitola i kortet. nil = vis det skannede treffet.
    @State private var chosenVariant: Cigar?

    @State private var showAddCigar = false
    @State private var selectedCigar: Cigar?
    @State private var openHumidorOnDetail = false   // «Legg i humidor» → åpne arket i detaljvisning
    @State private var showBrand = false             // nav til «Flere fra samme merke»

    // «Legg i humidor» åpner nå arket DIREKTE fra treffsiden (ett trykk),
    // i stedet for å ta brukeren til detaljsiden først.
    @State private var humidorCigar: Cigar?
    @State private var pendingHumidorCigar: Cigar?   // venter på innlogging
    @State private var showLoginForHumidor = false
    @State private var humidorConfirmCigar: Cigar?   // driver «Lagt i humidor»-bekreftelsen
    @State private var humidorConfirmEntry: HumidorEntry?   // oppføringen som nettopp ble lagt inn
    @State private var openHumidorEntry: HumidorEntry?      // sendes til detaljsiden ved «Gå til sigaren»
    @State private var logCigar: Cigar?                     // driver «Logg sigar»-arket
    @State private var pendingLogCigar: Cigar?              // venter på innlogging før logg-arket
    @State private var showLoginForLog = false
    @AppStorage("humidorHasNew") private var humidorHasNew: Bool = false
    private let humidorService = HumidorService()
    private let tastingService = TastingService()

    // MARK: Avledet
    private var top: ScanResult? { results.first }

    /// Sigaren kortet viser. Prioritet: brukerens valg → treffet (når størrelsen
    /// er bekreftet) → en vanlig standard-størrelse når båndet bare ga serien.
    private var displayCigar: Cigar? {
        if let chosen = chosenVariant { return chosen }
        guard let t = top?.cigar else { return nil }
        return sizeConfirmed ? t : (centralDefaultCigar ?? t)
    }

    /// Har vi faktisk fastslått STØRRELSEN, eller bare serien? Et bånd som Alma
    /// Fuerte er likt på alle størrelser, så da er størrelsen en gjetning.
    private var sizeConfirmed: Bool {
        guard let t = top?.cigar,
              let v = t.vitola?.trimmingCharacters(in: .whitespacesAndNewlines),
              !v.isEmpty else { return true }
        if sizeOptions.count <= 1 { return true }   // bare én størrelse i serien
        if chosenVariant != nil { return true }     // brukeren har valgt selv
        if isBandMatch { return true }              // fingeravtrykk kjente igjen akkurat denne
        if textNames(v, in: ocrText) { return true }              // båndet nevnte størrelsen
        if textNames(v, in: top?.matchReason ?? "") { return true } // begrunnelsen nevnte den
        return false
    }

    /// Treff basert på bilde/fingeravtrykk peker på en konkret sigar (m/størrelse).
    private var isBandMatch: Bool {
        let r = fold(top?.matchReason ?? "")
        return r.contains("bandtreff") || r.contains("ligner et band") || r.contains("fingeravtrykk")
    }

    /// En «vanlig» standard-størrelse — nærmest en robusto (50 × 5.5"), så vi aldri
    /// defaulter til en figurado/ytterpunkt når størrelsen egentlig er ukjent.
    private var centralDefaultCigar: Cigar? {
        sizeOptions.min(by: { centrality($0) < centrality($1) })
    }
    private func centrality(_ c: Cigar) -> Double {
        let dim = abs(Double(c.ringGauge ?? 50) - 50) + abs((c.lengthInches ?? 5.5) - 5.5) * 8
        // Figurado (torpedo, belicoso …) skyves bakerst: en rett parejo er nesten
        // alltid en riktigere gjetning enn en spiss form når størrelsen er ukjent.
        return dim + (isFigurado(c) ? 1000 : 0)
    }
    private func isFigurado(_ c: Cigar) -> Bool {
        let s = fold("\(c.shape ?? "") \(c.vitola ?? "")")
        return ["figurado", "torpedo", "torp", "belicoso", "piramide", "pyramid",
                "perfecto", "salomon", "diadema", "campana"].contains { s.contains($0) }
    }

    /// Diakritikk- og størrelses-uavhengig tekst.
    private func fold(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
         .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Finnes vitola-navnet (eller alle betydelige ord i det) i teksten?
    private func textNames(_ vitola: String, in text: String) -> Bool {
        let hay = fold(text), needle = fold(vitola)
        guard needle.count >= 2, !hay.isEmpty else { return false }
        if hay.contains(needle) { return true }
        let toks = needle.split(separator: " ").map(String.init).filter { $0.count > 2 }
        guard !toks.isEmpty else { return false }
        return toks.allSatisfy { hay.contains($0) }
    }

    /// Alle andre treff enn toppen.
    private var others: [ScanResult] { Array(results.dropFirst()) }

    private func norm(_ s: String?) -> String {
        (s ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// Er en sigar fra SAMME merke som toppen?
    private func sameBrandAsTop(_ cigar: Cigar) -> Bool {
        guard let t = top?.cigar else { return false }
        return norm(cigar.brand) == norm(t.brand)
    }

    /// «Andre mulige treff» = treff fra ANDRE merker enn toppen. Samme merke
    /// finner brukeren i «Flere fra …»-kortet, så vi gjentar det ikke her —
    /// ellers blir det mye av det samme.
    private var otherPossibilities: [ScanResult] {
        others.filter { !sameBrandAsTop($0.cigar) }
    }

    /// Alle konkrete rader i samme serie (hver rad = én vitola/dekkblad-kombo).
    private var seriesRows: [Cigar] {
        guard let t = top?.cigar else { return [] }
        let cb = norm(t.brand), cs = norm(t.series)
        var rows = brandCigars.filter {
            $0.isPublic != false && norm($0.brand) == cb && norm($0.series) == cs
        }
        if !rows.contains(where: { $0.id == t.id }) { rows.insert(t, at: 0) }
        return rows
    }

    /// Distinkte størrelser (vitola) — én representant-rad per vitola, sortert på
    /// mål. Driver størrelse-velgeren.
    private var sizeOptions: [Cigar] {
        var seen = Set<String>()
        var out: [Cigar] = []
        for r in seriesRows.sorted(by: { sizeKey($0) < sizeKey($1) }) {
            let key = norm(r.vitola)
            guard !key.isEmpty, !seen.contains(key) else { continue }
            seen.insert(key); out.append(r)
        }
        return out
    }

    /// Dekkbladet som tekst (blad, ellers land). nil om helt tomt.
    private func wrapperLabel(_ c: Cigar) -> String? {
        let leaf = (c.wrapperLeaf ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !leaf.isEmpty { return leaf }
        let country = (c.wrapperCountry ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return country.isEmpty ? nil : country
    }

    /// Distinkte dekkblad for den VISTE størrelsen. Tom/ett → feltet skjules.
    private var wrapperOptions: [String] {
        guard let v = displayCigar?.vitola else { return [] }
        let vn = norm(v)
        var seen = Set<String>()
        var out: [String] = []
        for r in seriesRows where norm(r.vitola) == vn {
            if let w = wrapperLabel(r) {
                let k = w.lowercased()
                if !seen.contains(k) { seen.insert(k); out.append(w) }
            }
        }
        return out
    }

    /// Bytt størrelse — behold dekkbladet hvis den nye størrelsen finnes i det,
    /// ellers størrelsens første. Lander alltid på en ekte rad.
    private func selectVitola(_ vitola: String) {
        let vn = norm(vitola)
        let curW = displayCigar.flatMap(wrapperLabel)?.lowercased()
        let rows = seriesRows.filter { norm($0.vitola) == vn }
        let pick = rows.first(where: { wrapperLabel($0)?.lowercased() == curW }) ?? rows.first
        if let pick { chosenVariant = pick }
    }

    /// Bytt dekkblad innenfor den valgte størrelsen.
    private func selectWrapper(_ wrapper: String) {
        guard let v = displayCigar?.vitola else { return }
        let vn = norm(v), wk = wrapper.lowercased()
        if let pick = seriesRows.first(where: {
            norm($0.vitola) == vn && wrapperLabel($0)?.lowercased() == wk
        }) { chosenVariant = pick }
    }

    private func sizeKey(_ c: Cigar) -> Double {
        (c.lengthInches ?? 0) * 100 + Double(c.ringGauge ?? 0)
    }

    /// Antall sigarer fra samme merke som IKKE er i den viste serien —
    /// tallet på «Flere fra samme merke»-kortet.
    private var brandOthersCount: Int {
        guard let t = top?.cigar else { return 0 }
        let cb = norm(t.brand), cs = norm(t.series)
        return brandCigars.filter {
            $0.isPublic != false && norm($0.brand) == cb && norm($0.series) != cs
        }.count
    }

    /// Binding for humidor-bekreftelsen (avledet av `humidorConfirmCigar`).
    private var humidorConfirmPresented: Binding<Bool> {
        Binding(get: { humidorConfirmCigar != nil },
                set: { if !$0 { humidorConfirmCigar = nil } })
    }

    // Scroll-innholdet er skilt ut fra body så den lange presentasjons-kjeden
    // (ark, alert, navigasjon) type-sjekkes i mindre biter.
    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                if let top, let display = displayCigar {
                    HeroCard(
                        cigar: display,
                        confidence: top.confidence,
                        sizeOptions: sizeOptions,
                        wrapperOptions: wrapperOptions,
                        sizeUnconfirmed: !sizeConfirmed,
                        onSelectVitola: { selectVitola($0) },
                        onSelectWrapper: { selectWrapper($0) },
                        onAddToHumidor: {
                            recordResolution(for: display)
                            if authService.userId == nil {
                                pendingHumidorCigar = display
                                showLoginForHumidor = true
                            } else {
                                humidorCigar = display
                            }
                        },
                        onLogSmoked: {
                            recordResolution(for: display)
                            if authService.userId == nil {
                                pendingLogCigar = display
                                showLoginForLog = true
                            } else {
                                logCigar = display
                            }
                        },
                        onSeeCigar: {
                            openHumidorOnDetail = false
                            openHumidorEntry = nil
                            recordResolution(for: display)
                            selectedCigar = display
                        }
                    )
                    .padding(.top, 10)
                    .padding(.bottom, 4)
                } else {
                    noMatchCard
                }

                // Flere fra samme merke — nav-kort → merkesiden (OVER «andre muligheter»).
                if let brand = displayCigar?.brand, brandOthersCount > 0 {
                    SameBrandCard(brand: brand, count: brandOthersCount) { showBrand = true }
                        .padding(.top, 18)
                }

                // Andre muligheter — kun ANDRE sigarer, alltid «Mindre sikkert».
                if !otherPossibilities.isEmpty {
                    sectionHead("Andre mulige treff", trailing: "hvis det ikke stemmer")
                    VStack(spacing: 10) {
                        ForEach(otherPossibilities) { r in
                            AltRow(cigar: r.cigar, showPill: true) {
                                openHumidorOnDetail = false
                                openHumidorEntry = nil
                                recordResolution(for: r.cigar)
                                selectedCigar = r.cigar
                            }
                        }
                    }
                }

                searchSection
                actionButtons
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 70)
        }
    }

    var body: some View {
        scrollContent
        .background(Color.sederPaper.ignoresSafeArea())
        .navigationTitle("Treff")
        .navigationBarTitleDisplayMode(.inline)
        // Presenteres nå som et modalt dekke (over hvilken som helst skjerm i
        // navigasjonen), så vi trenger en tydelig lukk-knapp øverst til venstre.
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.sederInk)
                }
                .accessibilityLabel("Lukk")
            }
        }
        .sheet(isPresented: $showAddCigar) {
            AddCigarSheet(prefillBrand: searchQuery.trimmingCharacters(in: .whitespaces).isEmpty ? (prefillBrand ?? "") : searchQuery) { cigar in
                openHumidorOnDetail = false
                openHumidorEntry = nil
                recordResolution(for: cigar)
                logManualMissIfNew(cigar)
                selectedCigar = cigar
            }
            .environmentObject(authService)
        }
        // «Legg i humidor» — arket åpnes direkte her på treffsiden.
        .sheet(item: $humidorCigar) { cigar in
            AddToHumidorSheet(cigar: cigar, userId: authService.userId) { chosenCigar, purchasedAt, addedAt, qty, humidorId, store, price, photoData in
                guard let uid = authService.userId else { return }
                Task {
                    do {
                        let entry = try await humidorService.addToHumidor(
                            cigarId: chosenCigar.id, userId: uid, humidorId: humidorId, quantity: qty,
                            purchasedAt: purchasedAt, addedToHumidorAt: addedAt, store: store, purchasePrice: price)
                        humidorHasNew = true
                        // Brukerens valgte bilde vinner; ellers skann-bildet fra båndet.
                        let effectivePhoto = photoData ?? bandImage?.jpegData(compressionQuality: 0.9)
                        if let data = effectivePhoto, (entry.photoURL ?? "").isEmpty {
                            _ = try? await humidorService.uploadPhoto(entryId: entry.id, userId: uid, imageData: data)
                        }
                        // Arket lukker seg selv etter lagring — vis så bekreftelsen
                        // med valg om å bli her eller gå til sigaren i humidoren.
                        humidorConfirmEntry = entry
                        humidorConfirmCigar = chosenCigar
                    } catch { print("Feil ved lagring i humidor: \(error)") }
                }
            }
            .environmentObject(authService)
        }
        // Bekreftelse etter at en sigar er lagt i humidoren.
        .alert("Lagt i humidoren", isPresented: humidorConfirmPresented, presenting: humidorConfirmCigar) { cigar in
            Button("Gå til sigaren") {
                let c = cigar
                // Åpne sigaren SOM oppføring i humidoren — da får brukeren bl.a.
                // legge til bilde, endre antall osv. rett på detaljsiden.
                let entry = humidorConfirmEntry
                humidorConfirmCigar = nil
                humidorConfirmEntry = nil
                openHumidorOnDetail = false
                openHumidorEntry = entry
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { selectedCigar = c }
            }
            Button("Bli her", role: .cancel) { humidorConfirmCigar = nil; humidorConfirmEntry = nil }
        } message: { cigar in
            Text("\(cigar.brand)\(cigar.series.map { " " + $0 } ?? "") er lagt i humidoren din.")
        }
        // Ikke innlogget når man trykker «Legg i humidor» → logg inn, åpne så arket.
        .sheet(isPresented: $showLoginForHumidor) {
            AuthView(onSuccess: {
                if let c = pendingHumidorCigar { pendingHumidorCigar = nil; humidorCigar = c }
            })
            .environmentObject(authService)
        }
        // «Logg sigar» — loggfør en røyking direkte fra treffsiden.
        .sheet(item: $logCigar) { cigar in
            SmokingLogSheet(cigar: cigar, userId: authService.userId) { smokedAt, rating, smokeAgain, draw, burn, flavor, notes, photoData, cutType, store in
                guard let uid = authService.userId else { return }
                Task {
                    do {
                        let logId = try await humidorService.logTastingForCigar(
                            cigarId: cigar.id, userId: uid, smokedAt: smokedAt, rating: rating,
                            smokeAgain: smokeAgain, drawRating: draw, burnRating: burn,
                            flavorRating: flavor, notes: notes, cutType: cutType, store: store)
                        if let data = photoData {
                            let url = try await tastingService.uploadLogPhoto(logId: logId, userId: uid, imageData: data)
                            try await tastingService.updateLog(
                                id: logId, smokedAt: smokedAt, rating: rating, smokeAgain: smokeAgain,
                                drawRating: draw, burnRating: burn, flavorRating: flavor,
                                personalNotes: notes, photoUrl: url)
                        }
                    } catch { print("Feil ved logging av sigar: \(error)") }
                }
            }
            .environmentObject(authService)
        }
        // Ikke innlogget når man trykker «Logg sigar» → logg inn, åpne så arket.
        .sheet(isPresented: $showLoginForLog) {
            AuthView(onSuccess: {
                if let c = pendingLogCigar { pendingLogCigar = nil; logCigar = c }
            })
            .environmentObject(authService)
        }
        .navigationDestination(isPresented: $showBrand) {
            if let brand = displayCigar?.brand {
                BrandCigarsView(brand: brand)
            }
        }
        .navigationDestination(item: $selectedCigar) { cigar in
            CigarDetailViewDesign(cigar: cigar, humidorEntry: openHumidorEntry, onScanNext: onScanNext,
                                  scanImage: bandImage, autoOpenHumidor: openHumidorOnDetail)
        }
        .task(id: results.first?.cigar.id) {
            guard let topCigar = results.first?.cigar else { brandCigars = []; return }
            brandCigars = (try? await cigarService.fetchCigarsByBrand(topCigar.brand)) ?? []
        }
    }

    // MARK: - Seksjoner

    private func sectionHead(_ title: String, trailing: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundColor(.sederInk)
            Spacer()
            if !trailing.isEmpty {
                Text(trailing)
                    .font(.system(size: 12.5))
                    .foregroundColor(.sederMuted)
            }
        }
        .padding(.horizontal, 6)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    private var noMatchCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(ocrText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                 ? "Vi fant ingen tekst å søke på"
                 : "Vi fant ingen sikker match på båndet")
                .font(.system(size: 17, weight: .semibold, design: .serif))
                .foregroundColor(.sederInk)
            Text("Sigaren kan likevel finnes i basen. Søk på merket under, eller legg den inn selv.")
                .font(.subheadline)
                .foregroundColor(.sederMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.sederLine, lineWidth: 1))
        .padding(.top, 8)
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHead("Finner du ikke riktig sigar?", trailing: "")
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundColor(.sederMuted)
                TextField("Søk på merke eller serie…", text: $searchQuery)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.search)
                    .onSubmit { Task { await runSearch() } }
                if isSearching { ProgressView() }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sederLine, lineWidth: 1))

            if let searchError {
                Text(searchError).font(.caption).foregroundColor(.red).padding(.horizontal, 4)
            }
            if hasSearched && searchResults.isEmpty && searchError == nil && !isSearching {
                Text("Ingen sigarer matchet «\(searchQuery)».")
                    .font(.caption).foregroundColor(.sederMuted).padding(.horizontal, 4)
            }
            VStack(spacing: 10) {
                ForEach(searchResults) { cigar in
                    AltRow(cigar: cigar, showPill: false) {
                        openHumidorOnDetail = false
                        recordResolution(for: cigar)
                        selectedCigar = cigar
                    }
                }
            }
        }
    }

    /// Bunn-handlinger som ordentlige knapper: «Skann på nytt» er primær (fylt),
    /// «Legg til sigaren selv» er sekundær (kontur). Full bredde, stablet.
    private var actionButtons: some View {
        VStack(spacing: 10) {
            // Sekundær — legg til sigaren selv
            Button { showAddCigar = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle").font(.system(size: 17, weight: .semibold))
                    Text("Legg til sigaren selv").font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.sederAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sederAccent.opacity(0.35), lineWidth: 1.5))
            }
            .buttonStyle(.plain)

            Text("Blir din med én gang — vi sjekker den mot kilden etterpå")
                .font(.system(size: 12)).foregroundColor(.sederMuted)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 4)

            // Primær — skann på nytt
            Button(action: { if let onScanNext { onScanNext() } else { dismiss() } }) {
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill").font(.system(size: 16, weight: .semibold))
                    Text("Skann på nytt").font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.sederAccent))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 18)
    }


    // MARK: - Handlinger

    private func recordResolution(for cigar: Cigar) {
        let service = TastingService()
        let ocr = ocrText
        let data = bandImage?.jpegData(compressionQuality: 0.8)
        let uid = authService.userId
        let cid = cigar.id
        Task { await service.resolveScan(ocrText: ocr, cigarId: cid, userId: uid, bandImage: data) }
    }

    /// La brukeren inn en sigar vi ikke hadde (privat, nyopprettet rad) etter en
    /// bom? Da logger vi det EKTE navnet brukeren skrev til dekning-lista — det er
    /// dette admin skal se, ikke den rå OCR-teksten. Koblet til en eksisterende
    /// sigar (offentlig) er ikke et hull og logges ikke.
    private func logManualMissIfNew(_ cigar: Cigar) {
        guard cigar.isPrivate else { return }
        var parts = [cigar.brand.trimmingCharacters(in: .whitespacesAndNewlines)]
        if let s = cigar.series?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
            parts.append(s)
        }
        let navn = parts.filter { !$0.isEmpty }.joined(separator: " ")
        guard !navn.isEmpty else { return }
        Task { await TastingService().logManualMiss(name: navn) }
    }

    private func runSearch() async {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { searchResults = []; hasSearched = false; return }
        isSearching = true; searchError = nil; hasSearched = true
        do {
            searchResults = try await cigarService.searchCigars(query: query)
        } catch {
            searchResults = []
            searchError = "Søket feilet. Sjekk internett og prøv igjen."
        }
        isSearching = false
    }
}

// MARK: - Felles: visningstittel (serie + vitola, uten dobbel-ord)
//   «Sobremesa Brûlée» + «Blue»        → «Sobremesa Brûlée Blue»
//   «Sobremesa Brûlée» + «Brûlée Blue» → «Sobremesa Brûlée Blue»  (fjerner overlapp)
private func sederDisplayTitle(_ cigar: Cigar) -> String {
    let s = (cigar.series ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let v = (cigar.vitola ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    if s.isEmpty { return v.isEmpty ? (cigar.commonFormat ?? cigar.brand) : v }
    if v.isEmpty { return s }
    // Er vitola i praksis hele serien igjen? Bruk bare serien.
    if v.range(of: s, options: .caseInsensitive) != nil { return v }
    let sWords = s.split(separator: " ").map(String.init)
    let vWords = v.split(separator: " ").map(String.init)
    var overlap = 0
    let maxK = min(sWords.count, vWords.count)
    var k = maxK
    while k >= 1 {
        let tail = sWords.suffix(k).joined(separator: " ")
        let head = vWords.prefix(k).joined(separator: " ")
        if tail.compare(head, options: .caseInsensitive) == .orderedSame { overlap = k; break }
        k -= 1
    }
    let restV = vWords.dropFirst(overlap).joined(separator: " ")
    return restV.isEmpty ? s : "\(s) \(restV)"
}

// MARK: - Hero (mest sannsynlig)
// Rekkefølgen speiler det brukeren leter etter: MERKE (sort, øverst) →
// SERIE (stor tittel) → STØRRELSE + (evt.) DEKKBLAD som klikkbare felt.
// Dekkblad-feltet vises kun når den valgte størrelsen finnes i flere dekkblad.
private struct HeroCard: View {
    let cigar: Cigar
    let confidence: Double
    let sizeOptions: [Cigar]          // distinkte vitolaer (representant-rad hver)
    let wrapperOptions: [String]      // dekkblad for valgt størrelse (≤1 → skjult)
    let sizeUnconfirmed: Bool         // båndet ga bare serien → flagg størrelse-feltet
    let onSelectVitola: (String) -> Void
    let onSelectWrapper: (String) -> Void
    let onAddToHumidor: () -> Void
    let onLogSmoked: () -> Void
    let onSeeCigar: () -> Void

    /// Serienavn som stor tittel. Faller tilbake til vitola/format om serie mangler.
    private var title: String {
        let s = (cigar.series ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !s.isEmpty { return s }
        let v = (cigar.vitola ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return v.isEmpty ? (cigar.commonFormat ?? cigar.brand) : v
    }

    /// Vitola-navnet alene (bold i feltet).
    private func sizeName(_ c: Cigar) -> String {
        let n = (c.vitola ?? c.commonFormat ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return n.isEmpty ? "Velg størrelse" : n
    }

    /// «Toro · 52 × 6"» — navn + mål (til menyen).
    private func sizeText(_ c: Cigar) -> String {
        let n = sizeName(c)
        let parts = [n == "Velg størrelse" ? nil : n, c.dimensionsLabel].compactMap { $0 }
        return parts.isEmpty ? "Velg størrelse" : parts.joined(separator: " · ")
    }

    /// Dekkbladet på den viste sigaren, som tekst.
    private var wrapperText: String {
        let leaf = (cigar.wrapperLeaf ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !leaf.isEmpty { return leaf }
        let c = (cigar.wrapperCountry ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return c.isEmpty ? "—" : c
    }

    private func eq(_ a: String?, _ b: String?) -> Bool {
        (a ?? "").trimmingCharacters(in: .whitespaces).lowercased()
        == (b ?? "").trimmingCharacters(in: .whitespaces).lowercased()
    }

    private var canChangeSize: Bool { sizeOptions.count > 1 }
    private var canChangeWrapper: Bool { wrapperOptions.count > 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ConfidencePill(confidence: confidence)
                .padding(.bottom, 14)

            // Merke — sort, øverst.
            Text(cigar.brand)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.sederInk)

            // Serie — stor tittel.
            Text(title)
                .font(.system(size: 24, weight: .semibold, design: .serif))
                .foregroundColor(.sederInk)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 3)

            // Gruppe: størrelse + (evt.) dekkblad — tett sammen, luft rundt.
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 0) {
                    sizeSelector
                    if sizeUnconfirmed { hintLine.padding(.top, 7) }
                }
                if canChangeWrapper { wrapperSelector }
            }
            .padding(.top, 16)

            // Tre handlinger: «Legg i humidor» som primær (full bredde), så
            // «Logg sigar» + «Se sigar» som sekundære side om side.
            VStack(spacing: 10) {
                Button(action: onAddToHumidor) {
                    Text("Legg i humidor")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.sederAccent))
                }
                .buttonStyle(.plain)

                HStack(spacing: 10) {
                    Button(action: onLogSmoked) {
                        Text("Logg sigar")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.sederInk)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sederLine, lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    Button(action: onSeeCigar) {
                        Text("Se sigar")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.sederInk)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sederLine, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 18)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 22).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.sederAccent, lineWidth: 2))
        .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 8)
    }

    // Gul hjelpelinje under størrelse-feltet når størrelsen bare er en gjetning.
    private var hintLine: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 11, weight: .semibold))
            Text("Estimert størrelse, endre ved behov")
                .font(.system(size: 10.5, weight: .semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundColor(.sederAmber)
        .padding(.horizontal, 2)
    }

    // — Størrelse/Form-velger (meny når det finnes flere størrelser)
    @ViewBuilder
    private var sizeSelector: some View {
        if canChangeSize {
            Menu {
                ForEach(sizeOptions) { opt in
                    Button { onSelectVitola(opt.vitola ?? "") } label: {
                        if eq(opt.vitola, cigar.vitola) {
                            Label(sizeText(opt), systemImage: "checkmark")
                        } else {
                            Text(sizeText(opt))
                        }
                    }
                }
            } label: {
                selectorChip(lead: "Størrelse / Form", name: sizeName(cigar),
                             dims: cigar.dimensionsLabel, flag: sizeUnconfirmed, interactive: true)
            }
            .buttonStyle(.plain)
        } else {
            selectorChip(lead: "Størrelse / Form", name: sizeName(cigar),
                         dims: cigar.dimensionsLabel, flag: sizeUnconfirmed, interactive: false)
        }
    }

    // — Dekkblad-velger (kun når størrelsen finnes i flere dekkblad)
    @ViewBuilder
    private var wrapperSelector: some View {
        Menu {
            ForEach(wrapperOptions, id: \.self) { w in
                Button { onSelectWrapper(w) } label: {
                    if eq(w, wrapperText) {
                        Label(w, systemImage: "checkmark")
                    } else {
                        Text(w)
                    }
                }
            }
        } label: {
            selectorChip(lead: "Dekkblad", name: wrapperText, dims: nil, flag: false, interactive: true)
        }
        .buttonStyle(.plain)
    }

    // Felles felt: liten label over verdien (navn bold, mål vanlig vekt), chevron
    // i egen boks. Hvitt = bekreftet, gult = størrelse ubekreftet.
    private func selectorChip(lead: String, name: String, dims: String?,
                              flag: Bool, interactive: Bool) -> some View {
        let fieldBg: Color = flag ? .sederAmberSoft : .white
        let border:  Color = flag ? .sederAmber : Color.sederAccent.opacity(0.22)
        let leadCol: Color = flag ? .sederAmber : .sederMuted
        let chevBg:  Color = flag ? .white : .sederAccentSoft
        let chevCol: Color = flag ? .sederAmber : .sederAccent
        return HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(lead)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(leadCol)
                // Navnet 2 px større enn målene: vitolanavnet er det viktigste,
                // mens målene (· 52 × 6") holdes på 15 som før.
                (Text(name).font(.system(size: 17, weight: .semibold))
                 + Text(dims.map { " · \($0)" } ?? "").font(.system(size: 15, weight: .regular)))
                    .monospacedDigit()
                    .foregroundColor(.sederInk)
                    .lineLimit(1)
            }
            Spacer(minLength: 6)
            if interactive {
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(chevCol)
                    .frame(width: 26, height: 26)
                    .background(RoundedRectangle(cornerRadius: 8).fill(chevBg))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 12).fill(fieldBg))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(border, lineWidth: 1))
    }
}

// MARK: - Konfidens-pille (ett konsekvent format overalt)
//   Sikker        4/4  grønn   (≥ 0.85)
//   Ganske sikker 3/4  grønn   (≥ 0.70)
//   Mindre sikkert 2/4 oransje (< 0.70, eller tvunget lav)
private struct ConfidencePill: View {
    let confidence: Double
    var forceLow: Bool = false
    var compact: Bool = false

    private enum Tier { case sikker, ganske, mindre }
    private var tier: Tier {
        if forceLow { return .mindre }
        // Taket er bevisst «Ganske sikker» (3/4). Vi sier aldri «Sikker» / 4-av-4,
        // så det alltid er litt slingringsmonn om treffet ikke er 100 %.
        if confidence >= 0.70 { return .ganske }
        return .mindre
    }
    private var filled: Int {
        switch tier { case .sikker: return 4; case .ganske: return 3; case .mindre: return 2 }
    }
    private var label: String {
        switch tier {
        case .sikker:  return "Sikker"
        case .ganske:  return "Ganske sikker"
        case .mindre:  return "Mindre sikkert"
        }
    }
    private var isAmber: Bool { tier == .mindre }
    private var tint: Color { isAmber ? .sederAmber : .sederGreen }
    private var soft: Color { isAmber ? .sederAmberSoft : .sederGreenSoft }

    var body: some View {
        HStack(spacing: compact ? 6 : 7) {
            HStack(spacing: 2) {
                ForEach(0..<4, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(tint.opacity(i < filled ? 1 : 0.28))
                        .frame(width: 3, height: compact ? 9 : 10)
                }
            }
            Text(label).font(.system(size: compact ? 11.5 : 12.5, weight: .semibold))
        }
        .foregroundColor(tint)
        .padding(.horizontal, compact ? 9 : 11).padding(.vertical, compact ? 4 : 5)
        .background(Capsule().fill(soft))
    }
}

// MARK: - Alternativ-rad (tittel = serie+vitola, merke under)
private struct AltRow: View {
    let cigar: Cigar
    var showPill: Bool = true       // «Andre muligheter» → alltid «Mindre sikkert»; søk/varianter → ingen pille
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    if showPill {
                        ConfidencePill(confidence: 0, forceLow: true, compact: true)
                    }
                    Text(sederDisplayTitle(cigar))
                        .font(.system(size: 16, weight: .semibold)).foregroundColor(.sederInk)
                    Text(cigar.brand)
                        .font(.system(size: 13.5)).foregroundColor(.sederMuted)
                    if let dim = cigar.dimensionsLabel {
                        Text(dim).font(.system(size: 12.5)).monospacedDigit().foregroundColor(.sederMuted)
                    }
                }
                Spacer(minLength: 8)
                if let wrapper = cigar.wrapperLeaf, !wrapper.trimmingCharacters(in: .whitespaces).isEmpty {
                    Text(wrapper)
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(.sederMuted)
                        .padding(.horizontal, 9).padding(.vertical, 4)
                        .background(Capsule().fill(Color.black.opacity(0.05)))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.sederLine, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Nav-kort «Flere fra samme merke» → merkesiden
// Størrelse-bytte skjer nå rett i kortet (vitola-velgeren), så dette kortet
// tar brukeren ett steg ut: andre serier/sigarer fra det samme merket.
private struct SameBrandCard: View {
    let brand: String
    let count: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(Color.sederAccentSoft).frame(width: 36, height: 36)
                    Image(systemName: "square.grid.2x2").font(.system(size: 15)).foregroundColor(.sederAccent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Flere fra \(brand)").font(.system(size: 14.5, weight: .semibold)).foregroundColor(.sederInk)
                    Text("Andre serier fra samme merke")
                        .font(.system(size: 12.5)).foregroundColor(.sederMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 6)
                Text("\(count)")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(.sederAccent)
                    .padding(.horizontal, 9).padding(.vertical, 3)
                    .background(Capsule().fill(Color.sederAccentSoft))
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold)).foregroundColor(.sederMuted)
            }
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.sederLine, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Cigar Row (gjenbrukbar — brukes av HumidorView m.fl.)
// Behold denne: andre skjermer refererer til `CigarRow`.
struct CigarRow: View {

    let cigar: Cigar

    /// «Robustos · 50 × 4.9"» — målene hjelper deg å skille to like sigarer
    /// fra hverandre når du står med den ene i hånden.
    private var metaLine: String? {
        let parts = [cigar.vitola, cigar.dimensionsLabel].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(cigar.brand)
                .font(.headline)
            if let series = cigar.series {
                Text(series)
                    .font(.subheadline)
                    .foregroundColor(Color("TextSecondary"))
            }
            if let metaLine {
                Text(metaLine)
                    .font(.caption)
                    .foregroundColor(Color("TextSecondary"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)   // fyll bredden
        .padding(.vertical, 4)
        .contentShape(Rectangle())   // hele raden trykkbar
    }
}

// MARK: - SEDER-farger (lokale, matcher utkastet)
private extension Color {
    static let sederInk        = Color("TextPrimary")
    static let sederMuted      = Color("TextSecondary")
    static let sederPaper      = Color(red: 0.914, green: 0.890, blue: 0.851) // #E9E3D9
    static let sederLine       = Color(red: 0.918, green: 0.890, blue: 0.847) // #EAE3D8
    static let sederAccent     = Color(red: 0.294, green: 0.247, blue: 0.204) // #4B3F34
    static let sederAccentSoft = Color(red: 0.941, green: 0.914, blue: 0.871) // #F0E9DE
    static let sederGreen      = Color(red: 0.243, green: 0.557, blue: 0.353) // #3E8E5A
    static let sederGreenSoft  = Color(red: 0.906, green: 0.945, blue: 0.918) // #E7F1EA
    static let sederAmber      = Color(red: 0.722, green: 0.525, blue: 0.231) // #B8863B
    static let sederAmberSoft  = Color(red: 0.965, green: 0.933, blue: 0.867) // #F6EEDD
}
