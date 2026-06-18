import SwiftUI

// MARK: - ResultsView
// Viser 3–5 mulige treff etter scanning

struct ResultsView: View {

    let results: [ScanResult]
    let ocrText: String
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
                Section(header: Text("\(results.count) mulige treff")) {
                    ForEach(results) { result in
                        NavigationLink(destination: CigarDetailView(cigar: result.cigar)) {
                            ResultRow(result: result)
                        }
                    }
                }
            } else {
                Section {
                    Text("Fant ingen treff på bandet. Prøv å søke manuelt under, eller scan på nytt.")
                        .font(.subheadline)
                        .foregroundColor(Color("TextSecondary"))
                }
            }

            // Manuelt søk
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
                    NavigationLink(destination: CigarDetailView(cigar: cigar)) {
                        ManualResultRow(cigar: cigar)
                    }
                }
            }

            // Scan på nytt
            Section {
                Button(action: { dismiss() }) {
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

// MARK: - Result Row
struct ResultRow: View {

    let result: ScanResult

    var body: some View {
        HStack(spacing: 10) {
            // Sigar-ikon — gjort mindre for å gi teksten mer plass
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color("Surface"))
                    .frame(width: 40, height: 40)
                CigarIcon(color: Color("TextPrimary"))
                    .frame(width: 20, height: 20)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(result.cigar.brand)
                    .font(.headline)
                if let series = result.cigar.series {
                    Text(series)
                        .font(.subheadline)
                        .foregroundColor(Color("TextSecondary"))
                }
                if let vitola = result.cigar.vitola {
                    Text(vitola)
                        .font(.caption)
                        .foregroundColor(Color("TextSecondary"))
                }
            }

            Spacer()

            // Konfidens-badge
            ConfidenceBadge(result: result)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Manual Result Row
struct ManualResultRow: View {

    let cigar: Cigar

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color("Surface"))
                    .frame(width: 40, height: 40)
                CigarIcon(color: Color("TextPrimary"))
                    .frame(width: 20, height: 20)
            }

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

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Confidence Badge
struct ConfidenceBadge: View {

    let result: ScanResult

    var color: Color {
        switch result.confidence {
        case 0.8...: return .green
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }

    var body: some View {
        Text(result.confidenceLabel)
            .font(.caption.bold())
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}
