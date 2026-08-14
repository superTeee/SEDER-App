import Foundation
import Vision
import UIKit

// MARK: - ScanService
// Steg 1: Apple Vision OCR (gratis, on-device)
// Steg 2: Supabase-søk basert på tekst
// Steg 3 (fallback): GPT-4o Vision via Supabase Edge Function

@MainActor
class ScanService: ObservableObject {

    @Published var isScanning = false
    @Published var extractedText: String = ""
    @Published var scanResults: [ScanResult] = []
    @Published var errorMessage: String?
    // Satt når skannet fullførte uten treff (ikke en teknisk feil) — UI viser da
    // den vennlige «ingen treff»-skjermen med valg om å prøve på nytt / legge inn manuelt.
    @Published var noMatch = false
    // Satt når båndet/AI-en eksplisitt pekte ut én bestemt variant —
    // da hopper appen rett til detaljskjermen i stedet for en velgerliste.
    @Published var autoSelectedCigar: Cigar?
    // Satt når flere treff deler samme merke (typisk samme bånd, ulik
    // størrelse/form) — UI ber da om ett ekstra bilde av hele sigaren
    // for å avklare formen før vi viser resultatet.
    @Published var needsShapePhoto = false
    // Satt når flere treff deler samme merke OG serie, men skiller seg på
    // wrapper-typen (f.eks. samme "Vintage 1999" i Connecticut vs. Maduro).
    // Båndet viser sjelden wrapper-fargen tydelig, så UI ber om ett ekstra
    // bilde av hele sigaren, akkurat som ved form-avklaring.
    @Published var needsWrapperPhoto = false
    // Utfallet av tekstlesingen på båndet — driver HVORFOR-forklaringen på
    // «ingen treff»-skjermen: var det ingen tekst, uleselig tekst, eller lest
    // tekst uten treff i basen? Tre svært ulike situasjoner for brukeren.
    @Published var bandTextOutcome: BandTextOutcome = .none

    enum BandTextOutcome: Equatable {
        case none      // ingen lesbar tekst funnet (typisk rent grafisk bånd)
        case unclear   // tekst funnet, men for utydelig til å stole på (bøyd/vinklet/gjenskinn)
        case clear     // tekst lest greit, men ingen match i basen
    }

    private let cigarService = CigarService()
    // Kandidatene som deler bånd men kan skilles på form — fylles når
    // needsShapePhoto settes, brukes av resolveShapeAmbiguity for å matche
    // GPT-4o sin form-gjetning mot riktig rad.
    private var shapeAmbiguityCandidates: [Cigar] = []
    // Samme idé, men for wrapper-typen — fylles når needsWrapperPhoto settes,
    // brukes av resolveWrapperAmbiguity.
    private var wrapperAmbiguityCandidates: [Cigar] = []

    // Ordliste med kjente merke/serienavn fra databasen, brukt til å "biase"
    // Apple Vision mot riktig ord når skriften er stilisert (se extractText).
    // Hentes kun én gang per app-sesjon — slår opp på nytt hvis hentingen
    // skulle feile (f.eks. ingen nett ved første scan).
    private var ocrVocabulary: [String]?

    private func loadOcrVocabularyIfNeeded() async {
        guard ocrVocabulary == nil else { return }
        ocrVocabulary = try? await cigarService.fetchOcrVocabulary()
    }

    // MARK: - Hovedfunksjon: scan et bilde
    func scanBandImage(_ image: UIImage) async {
        isScanning = true
        scanResults = []
        autoSelectedCigar = nil
        needsShapePhoto = false
        needsWrapperPhoto = false
        shapeAmbiguityCandidates = []
        wrapperAmbiguityCandidates = []
        errorMessage = nil
        noMatch = false
        bandTextOutcome = .none

        // Hent OCR-vokabular (merke-/serienavn fra databasen) før vi kjører
        // Vision, slik at customWords er klar til extractText under.
        await loadOcrVocabularyIfNeeded()

        do {
            // Steg 1: Trekk ut tekst med Apple Vision (OCR)
            let (text, ocrConfidence) = try await extractText(from: image, customWords: ocrVocabulary ?? [])
            extractedText = text
            print("📝 OCR-tekst: \(text) (konfidens: \(ocrConfidence))")

            // Klassifiser tekst-utfallet én gang, uavhengig av match-resultatet.
            // Brukes til å forklare HVORFOR om skanningen ender uten treff.
            let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedText.count < 2 {
                bandTextOutcome = .none
            } else if ocrConfidence < ocrConfidenceThreshold {
                bandTextOutcome = .unclear
            } else {
                bandTextOutcome = .clear
            }

            // Vision er usikker på (deler av) teksten — typisk krumme bånd,
            // vinklet bilde eller stilisert skrift. Da kan søket "treffe" på
            // den tydelige delen av teksten (f.eks. merkenavnet) men gå glipp
            // av den usikre delen (f.eks. en spesifikk variant/serie) — derfor
            // går vi til AI-fallback i stedet for å stole blindt på et delvis
            // riktig DB-treff.
            let isLowConfidence = ocrConfidence < ocrConfidenceThreshold

            // Steg 2: Søk i databasen
            // Rens OCR-teksten for geografiske fraser før søket — "REPUBLICA
            // DOMINICANA" på La Aurora-båndet skal ikke matche La Flor Dominicana.
            let searchText = cleanOcrTextForSearch(text)
            // Prøv ALLTID DB-søket hvis det er tekst å søke på — også ved lav OCR-konfidens.
            // Alias-systemet (f.eks. "VF" → "Vega Fina") er designet for å fange opp nettopp
            // stiliserte logoer/initialforkortelser der Vision gir lav konfidens, men likevel
            // leser riktig tekst. Å hoppe over DB og gå rett til AI ved lav konfidens
            // medfører unødvendige API-kall og heng hvis OpenAI er treg.
            if !searchText.isEmpty {
                let cigars = try await cigarService.searchCigars(query: searchText)

                if !cigars.isEmpty {
                    // Konverter til ScanResult med konfidensberegning
                    scanResults = cigars.enumerated().map { index, cigar in
                        ScanResult(
                            cigar: cigar,
                            confidence: confidenceScore(for: cigar, ocrText: text, rank: index),
                            matchReason: "Tekst: \(text)"
                        )
                    }

                    // Nevner båndet eksplisitt én bestemt serie/variant?
                    // Da slipper brukeren å velge selv.
                    autoSelectedCigar = exactSeriesMatch(in: cigars, ocrText: text)

                    // AI-disambiguering: hvis OCR var trygg nok (høy konfidens) og
                    // vi har flere treff uten eksakt variant, spør GPT om å avgjøre.
                    // Ved lav OCR-konfidens: vis heller DB-treffene som en valgliste —
                    // brukeren kan da velge riktig størrelse uten et ekstra AI-kall.
                    //
                    // MÅLRETTET INNSTRAMMING: et ENKELT DB-treff som båndteksten IKKE
                    // korroborerer (merket/serien står ikke i teksten) er en «skråsikker
                    // gjetning» — nettopp Lampert-formen. Da lar vi panelet avgjøre i
                    // stedet for å stole blindt på det. Korroborerte treff (der båndet
                    // faktisk navngir sigaren) beholdes på hurtig-sporet akkurat som før.
                    let topUncorroborated = cigars.count == 1 &&
                        !ocrTextCorroborates(cigars.first, ocrText: text)
                    if autoSelectedCigar == nil && !isLowConfidence &&
                        (cigars.count > 1 || topUncorroborated) {
                        let dbFallbackResults = scanResults
                        do {
                            scanResults = []
                            try await scanWithAI(image: image)
                            if scanResults.isEmpty {
                                // AI fant ikke noe brukbart — fall tilbake
                                // til DB-treffene i stedet for å miste alt.
                                scanResults = dbFallbackResults
                            }
                        } catch {
                            // AI-kallet feilet (f.eks. nettverk) — degrader
                            // til DB-treffene vi allerede hadde.
                            scanResults = dbFallbackResults
                            print("⚠️ AI-disambiguering feilet, bruker DB-resultater: \(error.localizedDescription)")
                        }
                    }
                } else {
                    // Steg 3: DB fant ingenting — fallback til GPT via Edge Function
                    try await scanWithAI(image: image)
                }
            } else if bandTextOutcome == .none {
                // Apple Vision fant ingen lesbar tekst. Det kan bety to ting:
                // (a) båndet ER rent grafisk (f.eks. Cavalier-hestelogo uten navn),
                // eller (b) teksten FINNES, men bildet er for mørkt/vinklet for
                // Vision (f.eks. et dramatisk pressefoto av et Padrón-bånd — der
                // et menneske lett leser «Padrón», men Vision gir opp).
                //
                // GPT-4o Vision er langt mer robust på (b), og edge-funksjonen er
                // nå instruert til å RETURNERE TOMT når den ikke kan lese noe
                // identifiserende — den blind-gjetter ikke lenger (det var derfor
                // vi tidligere hoppet over den her, som ga La Aurora på bilde 1).
                // Så vi lar GPT prøve å LESE båndet. Klarer den det → riktig treff.
                // Klarer den det ikke → tom liste → scanResults forblir tom, og
                // den visuelle båndmatchen under (lærte bånd) tar over som før.
                print("⚠️ Ingen lesbar OCR-tekst — lar GPT prøve å lese båndet (returnerer tomt om den ikke kan)")
                try await scanWithAI(image: image)
            } else {
                // Det VAR tekst på båndet, men bare fraser vi ikke søker på (geografi
                // e.l.). Da kan GPT fortsatt lese bildet fornuftig — behold AI-fallback.
                print("⚠️ Kun ikke-søkbar tekst (råtekst: '\(text)', konfidens: \(ocrConfidence)) — AI-fallback")
                try await scanWithAI(image: image)
            }

        } catch {
            errorMessage = "Scanning feilet: \(error.localizedDescription)"
        }

        // Visuell båndgjenkjenning (siste utvei): fant vi ingenting via OCR/tekst/
        // GPT, sammenlign selve bånd-bildet mot bånd andre har løst før. Redder
        // grafiske bånd uten tekst (f.eks. Cavalier) som skanneren ellers bommer på.
        if errorMessage == nil && scanResults.isEmpty {
            await visualBandMatch(image: image)
            scanResults.sort { $0.confidence > $1.confidence }
        }

        // Ferdig uten treff, men uten teknisk feil → vis den vennlige «ingen
        // treff»-skjermen i stedet for en tørr feil-alert.
        if errorMessage == nil && scanResults.isEmpty {
            noMatch = true
        }

        // Både DB-søket og AI-fallback bygger scanResults i den rekkefølgen
        // treffene kom tilbake i (FTS-rangering / AI-listeorden) — IKKE
        // nødvendigvis samme orden som konfidensen vi selv har beregnet.
        // Sorter på konfidens nå, slik at det mest sannsynlige treffet alltid
        // vises øverst i listen, uansett hvor det landet i søket.
        scanResults.sort { $0.confidence > $1.confidence }

        // Flere treff på samme bånd? Sjekk om de faktisk kan skilles på form
        // — da ber vi om ett ekstra bilde i stedet for å gjette eller vise
        // en lang liste rett vekk.
        checkForShapeAmbiguity()

        // Ikke begge avklaringer samtidig — formen er den mest synlige
        // forskjellen, så den prioriteres. Trigger ikke hvis den allerede
        // har formen sin avklaring i gang.
        if !needsShapePhoto {
            checkForWrapperAmbiguity()
        }

        // Logg skann-hendelsen for dekning-analyse (treffrate + hvilke sigarer
        // folk skanner som vi ikke har). Fyr og glem — blokkerer aldri UI.
        logScanEvent()

        isScanning = false
    }

    /// Sender skann-resultatet til Supabase (`log_scan_event`) for dekning-datahjulet.
    private func logScanEvent() {
        let hit = !scanResults.isEmpty
        let matchedId = scanResults.first?.cigar.id.uuidString
        let confidence = scanResults.first?.confidence
        let ocr = extractedText
        Task.detached {
            struct Params: Encodable {
                let p_ocr_text: String
                let p_hit: Bool
                let p_matched_cigar_id: String?
                let p_confidence: Double?
            }
            _ = try? await supabase
                .rpc("log_scan_event", params: Params(
                    p_ocr_text: ocr,
                    p_hit: hit,
                    p_matched_cigar_id: matchedId,
                    p_confidence: confidence
                ))
                .execute()
        }
    }

    // MARK: - Adaptiv form-avklaring
    // Trigger: samme bånd matchet flere rader i databasen (typisk samme
    // serie i flere størrelser/former — f.eks. Robusto vs. Torpedo av
    // samme merke), og ingen av dem ble eksakt valgt fra OCR-teksten.
    // Da ber vi brukeren om ett bilde av HELE sigaren for å avklare formen,
    // i stedet for alltid å kreve flere bilder (de ~86% standard Parejo-
    // sigarene går rett til resultat som i dag).
    private func checkForShapeAmbiguity() {
        guard autoSelectedCigar == nil, scanResults.count > 1 else { return }

        let brands = Set(scanResults.map { $0.cigar.brand.lowercased() })
        guard brands.count == 1 else { return }

        // Gir ingen mening å be om et form-bilde hvis kandidatene ikke har
        // forskjellig body_type å skille på (da hjelper ikke bildet uansett).
        let bodyTypes = Set(scanResults.compactMap { $0.cigar.bodyType?.lowercased() })
        guard bodyTypes.count > 1 else { return }

        shapeAmbiguityCandidates = scanResults.map { $0.cigar }
        needsShapePhoto = true
    }

    // Kalles fra UI når brukeren har tatt bilde av hele sigaren.
    // Matcher GPT-4o sin form-gjetning mot kandidatlisten — hvis nøyaktig
    // én kandidat har samme body_type, velger vi den automatisk. Klarer vi
    // ikke å avgjøre det (0 eller flere treff), faller vi tilbake til den
    // vanlige valglisten i stedet for å blokkere brukeren.
    func resolveShapeAmbiguity(with image: UIImage) async {
        defer { needsShapePhoto = false }

        guard !shapeAmbiguityCandidates.isEmpty else { return }
        isScanning = true
        defer { isScanning = false }

        guard let imageData = downscaled(image).jpegData(compressionQuality: 0.7) else { return }
        let base64Image = imageData.base64EncodedString()

        do {
            let shapeGuess: ShapeGuess = try await supabase.functions
                .invoke(
                    "scan-cigar",
                    options: .init(body: ["image": base64Image, "mode": "shape"])
                )

            print("📐 Form-gjetning: \(shapeGuess.bodyType) (\(shapeGuess.reason))")

            let matches = shapeAmbiguityCandidates.filter {
                $0.bodyType?.lowercased() == shapeGuess.bodyType.lowercased()
            }

            if matches.count == 1, let match = matches.first {
                autoSelectedCigar = match
                // Flytt den avklarte varianten til toppen av listen — scanResults
                // ble sortert etter konfidens i scanBandImage, men form-avklaring
                // skjer etter den sorteringen og endrer ikke rekkefølgen automatisk.
                if let idx = scanResults.firstIndex(where: { $0.cigar.id == match.id }) {
                    let resolved = scanResults.remove(at: idx)
                    scanResults.insert(
                        ScanResult(cigar: resolved.cigar, confidence: 1.0, matchReason: resolved.matchReason),
                        at: 0
                    )
                }
            }
            // 0 eller flere treff fortsatt — la brukeren velge fra listen som vanlig.
        } catch {
            // Form-avklaring feilet (f.eks. nettverk) — ikke blokker brukeren,
            // bare degrader til den vanlige valglisten.
            print("⚠️ Form-avklaring feilet: \(error.localizedDescription)")
        }
    }

    // MARK: - Adaptiv wrapper-avklaring
    // Trigger: samme bånd matchet flere rader med SAMME serie, men ulik
    // wrapper-type (f.eks. "Vintage 1999" i Connecticut vs. Maduro). Dette
    // er en annen ambiguitet enn formen — to varianter kan ha identisk form
    // og likevel skilles kun på wrapper-fargen. Båndet alene viser ofte ikke
    // denne fargen tydelig (det er fargen på sigarkroppen, ikke på båndet,
    // som avgjør), så vi ber om ett ekstra bilde av hele sigaren — akkurat
    // som ved form-avklaring, men for et annet kjennetegn.
    private func checkForWrapperAmbiguity() {
        guard autoSelectedCigar == nil, scanResults.count > 1 else { return }

        let brands = Set(scanResults.map { $0.cigar.brand.lowercased() })
        guard brands.count == 1 else { return }

        // Wrapper-avklaring gir bare mening når kandidatene deler samme serie
        // (det er da serienavnet alene ikke er nok til å skille dem) OG har
        // faktisk ulik wrapper_leaf å skille på.
        let seriesValues = Set(scanResults.compactMap { $0.cigar.series?.lowercased() })
        guard seriesValues.count == 1 else { return }

        let wrapperLeaves = Set(scanResults.compactMap { $0.cigar.wrapperLeaf?.lowercased() })
        guard wrapperLeaves.count > 1 else { return }

        wrapperAmbiguityCandidates = scanResults.map { $0.cigar }
        needsWrapperPhoto = true
    }

    // Kalles fra UI når brukeren har tatt bilde av hele sigaren for å avklare
    // wrapper-typen. Matcher GPT-4o sin wrapper-gjetning mot kandidatlisten —
    // hvis nøyaktig én kandidat har samme wrapper_leaf, velger vi den
    // automatisk. Usikkert (0 eller flere treff) faller vi tilbake til den
    // vanlige valglisten i stedet for å blokkere brukeren.
    func resolveWrapperAmbiguity(with image: UIImage) async {
        defer { needsWrapperPhoto = false }

        guard !wrapperAmbiguityCandidates.isEmpty else { return }
        isScanning = true
        defer { isScanning = false }

        guard let imageData = downscaled(image).jpegData(compressionQuality: 0.7) else { return }
        let base64Image = imageData.base64EncodedString()

        do {
            let wrapperGuess: WrapperGuess = try await supabase.functions
                .invoke(
                    "scan-cigar",
                    options: .init(body: ["image": base64Image, "mode": "wrapper"])
                )

            print("🎨 Wrapper-gjetning: \(wrapperGuess.wrapper ?? "ukjent") (\(wrapperGuess.reason))")

            guard let guessedWrapper = wrapperGuess.wrapper else { return }
            let g = guessedWrapper.lowercased()

            // Steg 1: eksakt blad-treff. Steg 2: samme farge-nyanse (lys/medium/
            // mørk) som mykt fallback — farge forteller nyansen pålitelig, men
            // ikke alltid eksakt type, så vi lar nyansen telle når bladet ikke
            // matcher ord-for-ord.
            var matches = wrapperAmbiguityCandidates.filter {
                ($0.wrapperLeaf?.lowercased() ?? "") == g
            }
            if matches.isEmpty, let gShade = Self.wrapperShade(g) {
                matches = wrapperAmbiguityCandidates.filter {
                    Self.wrapperShade($0.wrapperLeaf?.lowercased() ?? "") == gShade
                }
            }

            if matches.count == 1, let match = matches.first {
                // Entydig: velg automatisk og løft til topp.
                autoSelectedCigar = match
                boostToTop(ids: [match.id])
            } else if matches.count > 1 {
                // Myk booster: wrapper-fargen peker på en delmengde, ikke én rad.
                // Løft de sannsynlige kandidatene øverst, men behold resten under
                // så brukeren fortsatt kan velge fritt.
                boostToTop(ids: Set(matches.map { $0.id }))
            }
            // 0 treff: la rekkefølgen stå — fargen ga ingen nyttig pekepinn.
        } catch {
            // Wrapper-avklaring feilet (f.eks. nettverk) — ikke blokker
            // brukeren, bare degrader til den vanlige valglisten.
            print("⚠️ Wrapper-avklaring feilet: \(error.localizedDescription)")
        }
    }

    // Løft de angitte kandidatene øverst i resultatlisten uten å fjerne noen,
    // og behold intern rekkefølge. Grunnlaget for den myke wrapper-boosteren.
    private func boostToTop(ids: Set<UUID>) {
        guard !ids.isEmpty else { return }
        let boosted = scanResults.filter { ids.contains($0.cigar.id) }
        let rest = scanResults.filter { !ids.contains($0.cigar.id) }
        scanResults = boosted + rest
    }

    // Grov nyanse-bøtte for et dekkblad: lys / medium / mørk. Farge fra et bilde
    // forteller nyansen ganske pålitelig, men ikke eksakt type — derfor brukes
    // dette kun som et mykt fallback-signal i wrapper-boosteren.
    static func wrapperShade(_ leaf: String) -> String? {
        let s = leaf.lowercased()
        let lys = ["connecticut shade", "ecuador connecticut", "shade", "candela", "claro", "connecticut"]
        let mork = ["maduro", "broadleaf", "oscuro", "san andrés", "san andres"]
        let medium = ["habano", "corojo", "sumatra", "cameroon", "colorado", "sungrown", "rosado", "ecuadorian", "havana"]
        if mork.contains(where: { s.contains($0) })   { return "mørk" }
        if lys.contains(where: { s.contains($0) })    { return "lys" }
        if medium.contains(where: { s.contains($0) }) { return "medium" }
        return nil
    }

    // MARK: - OCR-tekst-rensing
    // Sigarbånd inneholder standard geografiske og produksjonsfraser (f.eks.
    // "REPUBLICA DOMINICANA", "HECHO A MANO") som ALDRI er merke- eller
    // serienavn. Disse frasene lager falske treff i OR-basert fulltekst-søk —
    // f.eks. matcher "DOMINICANA" mot "La Flor Dominicana" selv om det er en
    // La Aurora som skannes. Vi fjerner dem fra søketeksten (men beholder
    // den umodifiserte OCR-teksten for AI-kallet og visning).
    private func cleanOcrTextForSearch(_ rawText: String) -> String {
        // Fjerner geografiske og produksjonsmessige fraser som ikke finnes i
        // brand/series/vitola-feltene i databasen. Disse ville ellers ende opp
        // i AND-søket og blokkere alle treff fordi ingen sigarre har
        // f.eks. "republica" eller "dominicana" i sitt serienavn.
        //
        // Merk: "CAMEROON" strippes IKKE — det er en del av serienavnet
        // "1903 Cameroon" og hjelper AND-søket å finne riktig La Aurora-serie
        // uten å matche LFD Cameroon Cabinet (som ikke har "aurora" i sin rad).
        //
        // "1875" strippes IKKE — det er serienavnet til Romeo y Julieta 1875
        // (klassisk kubansk linje), og hjelper søket å skille den fra andre R&J-serier.
        // "Desde" (spansk for "siden") strippes — det er del av årstall-frasen
        // "Desde 1875" på kubanske R&J-bånd og er ikke et merke- eller serienavn.
        // "HABANA" og "CUBA" strippes — geografiske betegnelser som aldri er serienavn.
        let phrasesToStrip: [String] = [
            "REPUBLICA DOMINICANA", "REPÚBLICA DOMINICANA",
            "HECHO A MANO", "HECHO EN COSTA RICA", "HECHO EN NICARAGUA",
            "HECHO EN HONDURAS", "HECHO EN CUBA", "HECHO EN DOMINICANA", "HECHO EN",
            "MADE BY HAND", "HAND MADE", "HANDMADE", "HANDROLLED", "HAND ROLLED",
            "MADE IN USA", "MADE IN COSTA RICA", "MADE IN NICARAGUA", "MADE IN HONDURAS",
            "HABANA · CUBA", "HABANA-CUBA", "HABANA CUBA",
            "HABANA", "CUBA",
            "COSTA RICA", "COSTA-RICA",
            "NICARAGUA", "HONDURAS", "PANAMA", "ECUADOR",
            "DOMINICAN REPUBLIC", "DOMINICANA",
            "JALAPA", "ESTELÍ", "ESTELI", "JALAPA NICARAGUA",
            "SANTIAGO", "SANTIAGO DE LOS CABALLEROS",
            "DANLI", "DANLÍ", "TAMBORIL",
            "NAVARETTE", "VILLA GONZALEZ",
            "PREMIUM", "HANDCRAFTED", "HAND CRAFTED",
            "SINCE", "FOUNDED",
            "Desde", "DESDE",
        ]
        var cleaned = rawText
        for phrase in phrasesToStrip {
            cleaned = cleaned.replacingOccurrences(
                of: phrase, with: " ",
                options: [.caseInsensitive, .diacriticInsensitive]
            )
        }
        // Fjern MÅL-tokens (ringmål, lengde, dimensjon) — f.eks. "52", "5.0",
        // "6½", "6x52" — som blokkerer AND-søket. MEN behold modell-/serietall
        // som "1.4", "No. 4" eller "1964": de er ofte det mest identifiserende
        // på båndet. Å strippe "1.4" gjorde at "LIMITED 1.4" ble til bare
        // "LIMITED", som via engelsk stemming (limit:*) feilaktig matchet hele
        // "Limitada"-familien og rangerte Lampert Limitada 2025 øverst.
        let tokens = cleaned
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .filter { !isMeasurementToken($0) }
            .filter { token in
                // Dropp rene skilletegn-tokens (f.eks. "-", "·", "×").
                !token.trimmingCharacters(in: CharacterSet.alphanumerics.inverted).isEmpty
            }
        return tokens
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
    }

    /// Er tokenet et fysisk MÅL (ringmål/lengde/dimensjon) som skal fjernes fra
    /// søket? Skiller mål fra modell-/serietall: "52", "5.0", "6½", "6x52" er
    /// mål; "1.4", "1964", "No. 4" er navn og beholdes.
    private func isMeasurementToken(_ token: String) -> Bool {
        let t = token.trimmingCharacters(in: CharacterSet(charactersIn: "\"'”’"))
        if t.isEmpty { return false }
        // Brøk-/dimensjonstegn → mål
        if t.contains("½") || t.contains("¼") || t.contains("¾") || t.contains("×") { return true }
        // "6x52" / "52x6"
        if t.range(of: "^[0-9]+[x×][0-9]+$", options: .regularExpression) != nil { return true }
        // Rent heltall i ringmål-området 30–80
        if let n = Int(t) { return n >= 30 && n <= 80 }
        // Desimal med heltallsdel 3–9 = lengde i tommer (5.0, 6.5). "1.4" faller utenfor.
        if t.range(of: "^[0-9]+[.,][0-9]+$", options: .regularExpression) != nil {
            let whole = Int(t.prefix { $0.isNumber }) ?? 0
            return whole >= 3 && whole <= 9
        }
        return false
    }

    // MARK: - Apple Vision OCR
    // Terskel for når vi anser Vision sin egen lesning som for usikker til å
    // stole på (selv om søket teknisk sett finner treff på den). Krumme bånd,
    // vinklede bilder og stiliserte fonter gir typisk lavere konfidens enn
    // flat, rettvendt tekst. Justert empirisk — senk hvis AI-fallback
    // trigges for ofte på gode bilder, øk hvis dårlige bånd fortsatt går
    // gjennom uten fallback.
    private let ocrConfidenceThreshold: Double = 0.5

    // Returnerer den gjenkjente teksten + et konfidenstall (0–1) for HELE
    // lesningen. Vi bruker MINSTE konfidens blant linjer med substans
    // (>2 tegn) i stedet for gjennomsnitt — en enkelt utydelig, avgjørende
    // ordlinje (f.eks. en variant-navn som "Edmundo" på den krummede delen
    // av båndet) skal ikke drukne i at resten av båndet var lett å lese.
    // customWords: kjente merke-/serienavn fra databasen (se ocrVocabulary
    // i scanBandImage). Vision bruker disse til å "biase" gjetningene sine
    // mot et kjent vokabular — viktig for stilisert kursiv/skrift-font
    // (f.eks. "Blue" på My Father-bånd) som ellers lett blir feillest eller
    // hoppet over helt, uten at det nødvendigvis slår ut som lav konfidens.
    private func extractText(from image: UIImage, customWords: [String] = []) async throws -> (text: String, confidence: Double) {
        guard let cgImage = image.cgImage else {
            throw ScanError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let candidates = observations.compactMap { $0.topCandidates(1).first }

                let text = candidates
                    .map { $0.string }
                    .joined(separator: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                let substantialConfidences = candidates
                    .filter { $0.string.trimmingCharacters(in: .whitespaces).count > 2 }
                    .map { Double($0.confidence) }

                // Ingen substansielle linjer funnet — behandl som lav konfidens
                // (samme effekt som tom tekst, trigger AI-fallback).
                let confidence = substantialConfidences.min() ?? 0.0

                continuation.resume(returning: (text, confidence))
            }

            // Høy nøyaktighet — tregere men bedre for sigarbelt-tekst
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US", "es-ES"]
            request.usesLanguageCorrection = true
            // Biaser Vision mot kjente merke-/serienavn fra databasen —
            // hjelper mest på stilisert kursiv/skrift-font (se kommentar
            // på funksjonssignaturen over).
            request.customWords = customWords

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Nedskalering før opplasting
    // iPhone-bilder er 12 MP. Sendt i full oppløsning kan de sprenge minnet i
    // edge-funksjonens bilde-avkoding (→ 546 «worker limit»). 1600 px er rikelig
    // for tekst, Lens og fingeravtrykk, men trygt under grensa. scale = 1 gjør at
    // resultatet er piksler = punkter (ikke @2x/@3x), så vi faktisk kutter data.
    private func downscaled(_ image: UIImage, maxDimension: CGFloat = 1600) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxDimension else { return image }
        let factor = maxDimension / longest
        let newSize = CGSize(width: image.size.width * factor, height: image.size.height * factor)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // MARK: - AI Fallback via Supabase Edge Function
    // Edge Function holder OpenAI API-nøkkelen server-side (tryggere)
    private func scanWithAI(image: UIImage) async throws {
        guard let imageData = downscaled(image).jpegData(compressionQuality: 0.7) else {
            throw ScanError.invalidImage
        }

        let base64Image = imageData.base64EncodedString()

        // Kall Supabase Edge Function "scan-cigar" — dekoder responsen direkte til [AICigarMatch]
        let aiResults: [AICigarMatch] = try await supabase.functions
            .invoke(
                "scan-cigar",
                options: .init(
                    body: ["image": base64Image, "ocr_text": extractedText]
                )
            )

        // Hent fulle cigar-objekter for hvert AI-treff
        var exactMatches: [Cigar] = []
        for match in aiResults {
            if let cigar = try? await cigarService.fetchCigar(id: match.cigarId) {
                scanResults.append(ScanResult(
                    cigar: cigar,
                    confidence: match.confidence,
                    matchReason: match.reason
                ))
                if match.exactMatch {
                    exactMatches.append(cigar)
                }
            }
        }

        // AI-en/båndet pekte eksplisitt på akkurat én variant — velg den
        // automatisk. Er det flere eksakte treff (usikkert), la brukeren velge.
        if exactMatches.count == 1 {
            autoSelectedCigar = exactMatches.first
        }
    }

    // MARK: - Visuell båndgjenkjenning (siste utvei)
    // Sender bånd-bildet til edge-funksjonen embed-band, som lager et 512-d
    // "visuelt fingeravtrykk" og finner sigarer med lignende bånd blant alt
    // som andre brukere har løst før. Fanger bånd uten (lesbar) tekst.
    private func visualBandMatch(image: UIImage) async {
        guard let data = downscaled(image).jpegData(compressionQuality: 0.7) else { return }
        let base64 = data.base64EncodedString()
        do {
            let res: BandMatchResponse = try await supabase.functions
                .invoke("embed-band", options: .init(body: ["image": base64]))
            for s in (res.suggestions ?? []) {
                if scanResults.contains(where: { $0.cigar.id == s.cigarId }) { continue }
                if let cigar = try? await cigarService.fetchCigar(id: s.cigarId) {
                    scanResults.append(ScanResult(
                        cigar: cigar,
                        confidence: min(s.similarity, 0.95),
                        matchReason: "Ligner et bånd andre har skannet"
                    ))
                }
            }
            // Server-sidens konfidensvurdering (match_cigar_decision) styrer
            // HVORDAN treffet presenteres — se applyBandDecision.
            await applyBandDecision(res.decision)
        } catch {
            print("⚠️ Visuell båndmatch feilet: \(error.localizedDescription)")
        }
    }

    // MARK: - Konfidensvurdering fra bånd-embedding (match_cigar_decision)
    // Bruker `decision` fra edge-funksjonen til å avgjøre presentasjonen:
    //   confident → ett klart treff: hopp rett til detalj.
    //   brand     → delt bånd (f.eks. Montecristo): merket er sikkert, men
    //               ikke linjen. Vis HELE merket som valgliste, så brukeren
    //               plukker riktig linje/størrelse selv. Den eksisterende
    //               form-avklaringen (needsShapePhoto) trigges automatisk
    //               etterpå hvis kandidatene har ulik form.
    //   ellers    → uncertain/ambiguous/none: behold dagens oppførsel.
    private func applyBandDecision(_ decision: BandDecision?) async {
        guard let d = decision else { return }
        switch d.decision {
        case "confident":
            if let id = d.topCigarId,
               let cigar = try? await cigarService.fetchCigar(id: id) {
                if !scanResults.contains(where: { $0.cigar.id == cigar.id }) {
                    scanResults.append(ScanResult(
                        cigar: cigar, confidence: 0.95,
                        matchReason: "Tydelig båndtreff"))
                }
                autoSelectedCigar = cigar
                boostToTop(ids: Set([cigar.id]))
            }
        case "brand":
            guard let brand = d.topBrand else { return }
            let brandCigars = (try? await cigarService.fetchCigarsByBrand(brand)) ?? []
            for c in brandCigars where c.isPublic != false {
                if scanResults.contains(where: { $0.cigar.id == c.id }) { continue }
                scanResults.append(ScanResult(
                    cigar: c, confidence: 0.5,
                    matchReason: "Samme merke — velg riktig linje"))
            }
            // Delt bånd: aldri auto-velg én linje. La brukeren plukke.
            autoSelectedCigar = nil
        default:
            break   // uncertain / ambiguous / none — uendret
        }
    }

    // MARK: - Eksplisitt variant-gjenkjenning fra OCR-tekst
    // Returnerer cigaren hvis AKKURAT ÉN av treffene har en serie som
    // faktisk står skrevet i OCR-teksten fra båndet.
    //
    // Mange serier (f.eks. "Vintage 1999") finnes i flere wrapper-varianter
    // (Connecticut/Maduro/Sun Grown/Habano...) — da er IKKE serien alene nok
    // til å velge automatisk, selv om OCR leste hele båndet perfekt. Båndet
    // nevner som regel wrapper-typen rett under serienavnet, så vi bruker
    // den til å skille når serien i seg selv gir flere treff. Dette er en
    // gratis, deterministisk vinn — billigere og sikrere enn AI-fallback
    // når teksten allerede er fullt lesbar.
    private func exactSeriesMatch(in cigars: [Cigar], ocrText: String) -> Cigar? {
        let text = ocrText.lowercased()

        let seriesCandidates = cigars.filter { cigar in
            guard let series = cigar.series, series.count > 2 else { return false }
            return text.contains(series.lowercased())
        }

        guard seriesCandidates.count > 1 else {
            return seriesCandidates.count == 1 ? seriesCandidates.first : nil
        }

        let wrapperCandidates = seriesCandidates.filter { cigar in
            guard let wrapper = cigar.wrapperLeaf, wrapper.count > 2 else { return false }
            return text.contains(wrapper.lowercased())
        }
        return wrapperCandidates.count == 1 ? wrapperCandidates.first : nil
    }

    // MARK: - Korroborering (band-tekst støtter treffet?)
    // Sjekker om OCR-teksten faktisk NAVNGIR sigaren — dvs. inneholder merket
    // eller serien (aksent-uavhengig). Speiler serverens korroborering, og
    // skiller «lest» (trygt) fra «gjettet» (send til panelet). Token-basert på
    // serien, så en OCR-skrivefeil i ett ord ikke velter hele korroboreringen.
    private func ocrTextCorroborates(_ cigar: Cigar?, ocrText: String) -> Bool {
        guard let cigar else { return false }
        func norm(_ s: String) -> String {
            s.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        }
        let t = norm(ocrText)
        let brand = norm(cigar.brand)
        if brand.count >= 3 && t.contains(brand) { return true }
        if let series = cigar.series {
            let s = norm(series)
            if s.count >= 3 && t.contains(s) { return true }
            let words = s.split(separator: " ").map(String.init).filter { $0.count >= 2 }
            if !words.isEmpty {
                let hits = words.filter { t.contains($0) }.count
                if hits >= Int(ceil(Double(words.count) * 0.6)) { return true }
            }
        }
        return false
    }

    // MARK: - Konfidensberegning (enkel heuristikk)
    private func confidenceScore(for cigar: Cigar, ocrText: String, rank: Int) -> Double {
        let text = ocrText.lowercased()
        var score = 1.0 - (Double(rank) * 0.15) // Lavere rank = høyere konfidensgrunnlag

        // Boost hvis merket finnes eksplisitt i OCR-teksten
        if text.contains(cigar.brand.lowercased()) {
            score += 0.2
        }
        if let series = cigar.series, text.contains(series.lowercased()) {
            score += 0.15
        }
        // Wrapper-typen (Connecticut/Maduro/...) står ofte rett under
        // serienavnet på båndet — boost ranking når den faktisk er lest,
        // slik at riktig variant ikke drukner sist i listen.
        if let wrapper = cigar.wrapperLeaf, text.contains(wrapper.lowercased()) {
            score += 0.1
        }

        return min(max(score, 0.0), 1.0)
    }
}

// MARK: - Visuell båndmatch (respons fra embed-band edge function)
struct BandSuggestion: Decodable {
    let cigarId: UUID
    let similarity: Double
    let nSamples: Int
    enum CodingKeys: String, CodingKey {
        case cigarId   = "cigar_id"
        case similarity
        case nSamples  = "n_samples"
    }
}

// Konfidensvurdering fra match_cigar_decision (via embed-band).
// decision ∈ { confident, brand, ambiguous, uncertain, none }.
struct BandDecision: Decodable {
    let decision: String
    let topBrand: String?
    let topCigarId: UUID?
    let topSimilarity: Double?
    enum CodingKeys: String, CodingKey {
        case decision
        case topBrand      = "top_brand"
        case topCigarId    = "top_cigar_id"
        case topSimilarity = "top_similarity"
    }
}

struct BandMatchResponse: Decodable {
    let signature: String?
    let suggestions: [BandSuggestion]?
    let decision: BandDecision?
}

// MARK: - AI Match (respons fra Edge Function)
struct AICigarMatch: Decodable {
    let cigarId: UUID
    let confidence: Double
    let reason: String
    let exactMatch: Bool

    enum CodingKeys: String, CodingKey {
        case cigarId    = "cigar_id"
        case confidence
        case reason
        case exactMatch = "exact_match"
    }
}

// MARK: - Form-gjetning (respons fra Edge Function, mode "shape")
struct ShapeGuess: Decodable {
    let bodyType: String
    let headType: String
    let footType: String
    let confidence: Double
    let reason: String

    enum CodingKeys: String, CodingKey {
        case bodyType  = "body_type"
        case headType  = "head_type"
        case footType  = "foot_type"
        case confidence
        case reason
    }
}

// MARK: - Wrapper-gjetning (respons fra Edge Function, mode "wrapper")
struct WrapperGuess: Decodable {
    let wrapper: String?
    let confidence: Double
    let reason: String
}

// MARK: - Feil
enum ScanError: LocalizedError {
    case invalidImage
    case noTextFound
    case noMatchFound

    var errorDescription: String? {
        switch self {
        case .invalidImage:     return "Bildet kunne ikke behandles. Prøv igjen."
        case .noTextFound:      return "Ingen tekst funnet på bandet."
        case .noMatchFound:     return "Fant ingen matchende sigarer."
        }
    }
}
