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

        // Hent OCR-vokabular (merke-/serienavn fra databasen) før vi kjører
        // Vision, slik at customWords er klar til extractText under.
        await loadOcrVocabularyIfNeeded()

        do {
            // Steg 1: Trekk ut tekst med Apple Vision (OCR)
            let (text, ocrConfidence) = try await extractText(from: image, customWords: ocrVocabulary ?? [])
            extractedText = text
            print("📝 OCR-tekst: \(text) (konfidens: \(ocrConfidence))")

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
                    if autoSelectedCigar == nil && cigars.count > 1 && !isLowConfidence {
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
            } else {
                // OCR-teksten ble tom etter rensing (bare geografiske fraser) —
                // ingen meningsfull tekst å søke på; bruk AI direkte.
                print("⚠️ Tom søketekst etter rensing (råtekst: '\(text)', konfidens: \(ocrConfidence)) — AI-fallback")
                try await scanWithAI(image: image)
            }

        } catch {
            errorMessage = "Scanning feilet: \(error.localizedDescription)"
        }

        if errorMessage == nil && scanResults.isEmpty {
            errorMessage = "Fant ingen treff for denne sigaren. Prøv et tydeligere bilde av båndet, eller søk den opp manuelt."
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

        guard let imageData = image.jpegData(compressionQuality: 0.7) else { return }
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

        guard let imageData = image.jpegData(compressionQuality: 0.7) else { return }
        let base64Image = imageData.base64EncodedString()

        do {
            let wrapperGuess: WrapperGuess = try await supabase.functions
                .invoke(
                    "scan-cigar",
                    options: .init(body: ["image": base64Image, "mode": "wrapper"])
                )

            print("🎨 Wrapper-gjetning: \(wrapperGuess.wrapper ?? "ukjent") (\(wrapperGuess.reason))")

            guard let guessedWrapper = wrapperGuess.wrapper else { return }

            let matches = wrapperAmbiguityCandidates.filter {
                $0.wrapperLeaf?.lowercased() == guessedWrapper.lowercased()
            }

            if matches.count == 1, let match = matches.first {
                autoSelectedCigar = match
                // Flytt den avklarte varianten til toppen av listen — samme
                // logikk som for form-avklaring (se resolveShapeAmbiguity).
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
            // Wrapper-avklaring feilet (f.eks. nettverk) — ikke blokker
            // brukeren, bare degrader til den vanlige valglisten.
            print("⚠️ Wrapper-avklaring feilet: \(error.localizedDescription)")
        }
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
        // Fjern rene tall-tokens (ringmål, lengde) — f.eks. "52", "5.0", "6½"
        // blokkerer AND-søket fordi tall aldri er indexert i search_vector.
        let tokens = cleaned
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .filter { token in
                // Behold token hvis det IKKE er rent numerisk (inkl. desimal og brøkstreker)
                let stripped = token.trimmingCharacters(in: CharacterSet(charactersIn: "0123456789.,½¼¾×x\"'"))
                return !stripped.isEmpty
            }
        return tokens
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
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

    // MARK: - AI Fallback via Supabase Edge Function
    // Edge Function holder OpenAI API-nøkkelen server-side (tryggere)
    private func scanWithAI(image: UIImage) async throws {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
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
