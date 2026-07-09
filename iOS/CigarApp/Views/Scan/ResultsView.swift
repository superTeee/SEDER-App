import SwiftUI

// MARK: - ResultsView
// Viser scan-treff + manuelt søk-fallback

struct ResultsView: View {

    let results: [ScanResult]
    let ocrText: String
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

    // Fant hverken scan eller søk sigaren, legger brukeren den inn selv.
    @State private var showAddCigar = false
    @State private var createdCigar: Cigar?

    var body: some View {
        List {
            // Resultater fra scan
            if !results.isEmpty {
                Section {
                    ForEach(results) { result in
                        NavigationLink(destination: CigarDetailViewDesign(cigar: result.cigar, onScanNext: onScanNext)) {
                            ResultRow(result: result)
                        }
                    }
                }
            } else {
                Section {
                    Text("Fant ingen treff på bandet. Søk manuelt under, eller scan på nytt.")
                        .font(.subheadline)
                        .foregroundColor(Color("TextSecondary"))
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
                    NavigationLink(destination: CigarDetailViewDesign(cigar: cigar, onScanNext: onScanNext)) {
                        CigarRow(cigar: cigar)
                    }
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
        .navigationTitle("Treff")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddCigar) {
            AddCigarSheet(prefillBrand: searchQuery) { cigar in
                createdCigar = cigar
            }
            .environmentObject(authService)
        }
        .navigationDestination(item: $createdCigar) { cigar in
            CigarDetailViewDesign(cigar: cigar, onScanNext: onScanNext)
        }
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
struct ResultRow: View {

    let result: ScanResult

    var body: some View {
        CigarRow(cigar: result.cigar)
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
        .padding(.vertical, 4)
    }
}
