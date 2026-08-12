import SwiftUI
import UIKit

// MARK: - ResultsView
// Viser scan-treff + manuelt søk-fallback

struct ResultsView: View {

    let results: [ScanResult]
    let ocrText: String
    // Bånd-bildet fra skanningen — lastes opp til bildebiblioteket når brukeren
    // løser (velger riktig sigar), og driver bildegjenkjenningen over tid.
    var bandImage: UIImage? = nil
    // Valgfri "scan neste"-handling fra scan-flyten (pop til rot + åpne kamera).
    var onScanNext: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService

    @StateObject private var cigarService = CigarService()
    @State private var searchQuery: String = ""
    @State private var searchResults: [Cigar] = []
    @State private var isSearching = false
    @State private var searchError: String?
    @State private var hasSearched = false

    // Andre varianter (samme merke + serie) — sikkerhetsnett når skann viser
    // feil wrapper/vitola. Lastes for det øverste treffet, uavhengig av data.
    @State private var siblings: [Cigar] = []
    @State private var showSiblings = false

    // Fant hverken scan eller søk sigaren, legger brukeren den inn selv.
    @State private var showAddCigar = false
    // Én felles item-drevet destinasjon for både treff, søketreff og ny sigar.
    // (NavigationLink + simultaneousGesture inne i navigationDestination(isPresented:)
    // pushet ikke — item-drevet navigasjon er robust og virker allerede lenger nede.)
    @State private var selectedCigar: Cigar?

    var body: some View {
        List {
            // Resultater fra scan
            if !results.isEmpty {
                Section {
                    ForEach(results) { result in
                        Button {
                            recordResolution(for: result.cigar)
                            selectedCigar = result.cigar
                        } label: {
                            ResultRow(result: result)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                Section {
                    Text(ocrText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                         ? "Vi fant ingen tekst å søke på — men sigaren kan likevel finnes i basen. Søk på merket under, eller legg den inn selv."
                         : "Vi fant ingen match på båndet — men sigaren kan likevel finnes i basen. Søk under (vi foreslår treff mens du skriver), eller legg den inn selv.")
                        .font(.subheadline)
                        .foregroundColor(Color("TextSecondary"))
                }
            }

            // Andre varianter i samme serie — sikkerhetsnett. Et bånd er likt på
            // tvers av størrelser og ofte på tvers av wrappere (f.eks. Padrón
            // Family Reserve Natural vs Maduro), så skann kjenner igjen SERIEN,
            // ikke nøyaktig vitola/wrapper. Her kan brukeren bytte til riktig
            // variant med ett trykk — uten å skrive et søk.
            if !otherVariants.isEmpty {
                Section {
                    DisclosureGroup(isExpanded: $showSiblings) {
                        ForEach(otherVariants) { sib in
                            Button {
                                recordResolution(for: sib)
                                selectedCigar = sib
                            } label: {
                                SiblingRow(cigar: sib)
                            }
                            .buttonStyle(.plain)
                        }
                    } label: {
                        Label("Ikke riktig? Andre varianter i samme serie",
                              systemImage: "rectangle.stack")
                            .font(.subheadline)
                    }
                }
            }

            // Manuelt søk-fallback
            Section(header: Text("Finner du ikke riktig sigar?")) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color("TextSecondary"))
                    TextField("Søk på merke eller serie...", text: $searchQuery)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.search)
                        .onSubmit { Task { await runSearch() } }
                    if isSearching {
                        ProgressView()
                    }
                }
                .padding(.vertical, 4)

                if let searchError {
                    Text(searchError)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                if hasSearched && searchResults.isEmpty && searchError == nil && !isSearching {
                    Text("Ingen sigarer matchet søket «\(searchQuery)».")
                        .font(.caption)
                        .foregroundColor(Color("TextSecondary"))
                }

                ForEach(searchResults) { cigar in
                    Button {
                        recordResolution(for: cigar)
                        selectedCigar = cigar
                    } label: {
                        CigarRow(cigar: cigar)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Siste utvei. Brukeren står med sigaren i hånden — da skal
            // appen aldri svare "finnes ikke" og stoppe der.
            Section {
                Button {
                    showAddCigar = true
                } label: {
                    Label("Legg til sigaren selv", systemImage: "plus.circle")
                }
            } footer: {
                Text("Sigaren blir din med én gang, og vi sjekker den mot kilden før den eventuelt blir synlig for alle.")
            }

            // Scan på nytt
            Section {
                Button(action: { if let onScanNext { onScanNext() } else { dismiss() } }) {
                    Label("Scan på nytt", systemImage: "camera.fill")
                }
            }
        }
        .contentMargins(.bottom, 60, for: .scrollContent) // klarering for egen tab-bar
        .navigationTitle("Treff")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddCigar) {
            AddCigarSheet(prefillBrand: searchQuery) { cigar in
                recordResolution(for: cigar)
                selectedCigar = cigar
            }
            .environmentObject(authService)
        }
        .navigationDestination(item: $selectedCigar) { cigar in
            // Ta med skann-bildet: legges på DINE egne plasseringer (humidor +
            // journal) dersom du ikke har et bilde fra før — aldri på katalogen.
            CigarDetailViewDesign(cigar: cigar, onScanNext: onScanNext, scanImage: bandImage)
        }
        // Last søsken-varianter for det øverste treffet (kjøres på nytt hvis
        // toppen endrer seg, f.eks. etter wrapper-avklaring).
        .task(id: results.first?.cigar.id) {
            guard let top = results.first?.cigar else { siblings = []; return }
            siblings = await cigarService.siblingVitolas(for: top)
        }
    }

    /// Varianter i samme serie som IKKE allerede står i skann-treffene over —
    /// altså de reelle alternativene brukeren kan bytte til.
    private var otherVariants: [Cigar] {
        let shown = Set(results.map { $0.cigar.id })
        return siblings.filter { !shown.contains($0.id) }
    }

    // Løser skanningen: laster opp bånd-bildet + registrerer koblingen bånd→sigar.
    // Best effort i bakgrunnen — navigasjonen skjer uansett med en gang.
    private func recordResolution(for cigar: Cigar) {
        // resolveScan ligger på TastingService (samme fil som CigarService).
        // Egen lettvekts-instans her, kopiert til lokal konstant før Task-en.
        let service = TastingService()
        let ocr = ocrText
        let data = bandImage?.jpegData(compressionQuality: 0.8)
        let uid = authService.userId
        let cid = cigar.id
        Task { await service.resolveScan(ocrText: ocr, cigarId: cid, userId: uid, bandImage: data) }
    }

    private func runSearch() async {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            hasSearched = false
            return
        }

        isSearching = true
        searchError = nil
        hasSearched = true

        do {
            searchResults = try await cigarService.searchCigars(query: query)
        } catch {
            searchResults = []
            searchError = "Søket feilet. Sjekk internettforbindelsen og prøv igjen."
        }

        isSearching = false
    }
}

// MARK: - Result Row (scan-treff)
// Skann-treff er som regel varianter av SAMME serie (samme bånd), så merke +
// serie gjentar seg nedover lista. Da er det vitolaen/nummeret (No. 45 vs No. 85)
// og wrapperen som skiller dem — derfor leder vi med DET, ikke merket. (Det
// vanlige søket bruker fortsatt CigarRow, som leder med merket.)
struct ResultRow: View {

    let result: ScanResult
    private var cigar: Cigar { result.cigar }

    // Ankeret: det som faktisk skiller treffene. Vitola/nummer først; faller
    // tilbake til form/serie/merke om vitola mangler.
    private var title: String {
        cigar.vitola ?? cigar.commonFormat ?? cigar.series ?? cigar.brand
    }
    // Delt kontekst under: «Merke · Serie».
    private var context: String {
        [cigar.brand, cigar.series].compactMap { $0 }.joined(separator: " · ")
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color("TextPrimary"))
                if !context.isEmpty {
                    Text(context)
                        .font(.subheadline)
                        .foregroundColor(Color("TextSecondary"))
                }
                if let dim = cigar.dimensionsLabel {
                    Text(dim)
                        .font(.caption)
                        .foregroundColor(Color("TextSecondary"))
                        .monospacedDigit()
                }
            }
            Spacer(minLength: 8)
            if let wrapper = cigar.wrapperLeaf,
               !wrapper.trimmingCharacters(in: .whitespaces).isEmpty {
                Text(wrapper)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color("TextSecondary").opacity(0.12)))
                    .foregroundColor(Color("TextSecondary"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

// MARK: - Sibling Row (annen variant i samme serie)
// Fremhever det som skiller variantene: vitola + wrapper. Merke/serie er likt
// for alle radene her, så vi gjentar dem ikke — da ser du «No. 44 · Maduro» vs
// «No. 44 · Natural» med én gang.
struct SiblingRow: View {

    let cigar: Cigar

    private var title: String {
        cigar.vitola ?? cigar.series ?? cigar.brand
    }

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if let dim = cigar.dimensionsLabel {
                    Text(dim)
                        .font(.caption)
                        .foregroundColor(Color("TextSecondary"))
                }
            }
            Spacer(minLength: 8)
            if let wrapper = cigar.wrapperLeaf,
               !wrapper.trimmingCharacters(in: .whitespaces).isEmpty {
                Text(wrapper)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color("TextSecondary").opacity(0.12)))
                    .foregroundColor(Color("TextSecondary"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

// MARK: - Cigar Row (gjenbrukbar — brukes både for scan-treff og manuelt søk)
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
