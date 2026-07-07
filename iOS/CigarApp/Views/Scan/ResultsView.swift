import SwiftUI

// MARK: - ResultsView
// Viser scan-treff + manuelt søk-fallback

struct ResultsView: View {

    let results: [ScanResult]
    let ocrText: String
    // Valgfri "scan neste"-handling fra scan-flyten (pop til rot + åpne kamera).
    var onScanNext: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    @StateObject private var cigarService = CigarService()
    @State private var searchQuery: String = ""
    @State private var searchResults: [Cigar] = []
    @State private var isSearching = false
    @State private var searchError: String?
    @State private var hasSearched = false

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

            // Scan på nytt
            Section {
                Button(action: { if let onScanNext { onScanNext() } else { dismiss() } }) {
                    Label("Scan på nytt", systemImage: "camera.fill")
                }
            }
        }
        .navigationTitle("Treff")
        .navigationBarTitleDisplayMode(.inline)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(cigar.brand)
                .font(.headline)
            if let series = cigar.series {
                Text(series)
                    .font(.subheadline)
                    .foregroundColor(Color("TextSecondary"))
            }
            if let vitola = cigar.vitola {
                Text(vitola)
                    .font(.caption)
                    .foregroundColor(Color("TextSecondary"))
            }
        }
        .padding(.vertical, 4)
    }
}
