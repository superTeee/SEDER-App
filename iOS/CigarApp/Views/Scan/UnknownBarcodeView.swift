import SwiftUI

// MARK: - UnknownBarcodeView
// Vises når strekkoden ikke finnes i Supabase og ikke kan matches via UPCitemdb.
// Lar brukeren søke manuelt og koble strekkoden til riktig sigar.

struct UnknownBarcodeView: View {

    let barcode: String
    let barcodeService: BarcodeService
    var onLinked: (Cigar) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService
    @StateObject private var cigarService = CigarService()

    @State private var searchQuery    = ""
    @State private var searchResults: [Cigar] = []
    @State private var isSearching    = false
    @State private var selectedCigar: Cigar?
    @State private var isSaving       = false
    @State private var saveError:     String?
    @State private var searchTask: Task<Void, Never>?
    @State private var showAddCigar   = false

    var body: some View {
        VStack(spacing: 0) {
            // ─── Header ───
            VStack(spacing: 6) {
                Capsule()
                    .fill(Color(.separator))
                    .frame(width: 36, height: 4)
                    .padding(.top, 10)

                Text("Ukjent strekkode")
                    .font(.headline)
                    .padding(.top, 14)

                Text(barcode)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(Color(.secondaryLabel))
                    .padding(.bottom, 14)
            }

            Divider()

            // ─── Instruksjon ───
            Text("Søk etter sigaren og koble strekkoden til den — neste gang vil den bli gjenkjent automatisk.")
                .font(.subheadline)
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)

            // ─── Søkefelt ───
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color(.secondaryLabel))
                TextField("Søk etter sigar eller merke…", text: $searchQuery)
                    .submitLabel(.search)
                    .onSubmit { runSearch() }
                if isSearching {
                    ProgressView().scaleEffect(0.85)
                } else if !searchQuery.isEmpty {
                    Button {
                        searchQuery   = ""
                        searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(.secondaryLabel))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.horizontal, 16)
            .onChange(of: searchQuery) { query in
                searchTask?.cancel()
                guard !query.isEmpty else {
                    searchResults = []
                    return
                }
                searchTask = Task {
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    guard !Task.isCancelled else { return }
                    runSearch()
                }
            }

            // ─── Legg til selv ───
            // Sigaren finnes ikke i basen. Da skal ikke skanningen ende blindt —
            // brukeren legger den inn, og strekkoden kobles til den nye raden.
            if selectedCigar == nil {
                Button {
                    showAddCigar = true
                } label: {
                    Label("Sigaren finnes ikke — legg den inn selv", systemImage: "plus.circle")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(Color("Accent"))
                }
                .padding(.top, 14)
            }

            // ─── Resultatliste ───
            ScrollView {
                LazyVStack(spacing: 0) {
                    if searchResults.isEmpty && !isSearching && !searchQuery.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 28))
                                .foregroundColor(Color(.tertiaryLabel))
                            Text("Ingen treff")
                                .foregroundColor(Color(.secondaryLabel))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }

                    ForEach(searchResults) { cigar in
                        Button {
                            selectedCigar = cigar
                        } label: {
                            resultRow(cigar: cigar, selected: selectedCigar?.id == cigar.id)
                        }
                        .buttonStyle(.plain)

                        if cigar.id != searchResults.last?.id {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
                .padding(.top, 8)
            }

            // ─── Bekreft-knapp ───
            if let cigar = selectedCigar {
                Divider()
                VStack(spacing: 8) {
                    Text("Koble «\(cigar.brand)\(cigar.series.map { " \($0)" } ?? "")» til strekkoden?")
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    if let error = saveError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    Button {
                        saveLink(cigar: cigar)
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView().tint(.white).scaleEffect(0.85)
                            }
                            Text("Bekreft kobling")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color("Accent"))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .disabled(isSaving)
                    .padding(.horizontal, 16)
                }
                .padding(.top, 12)
                .padding(.bottom, 32)
                .background(Color("Card"))
            }
        }
        .background(Color("Card"))
        .sheet(isPresented: $showAddCigar) {
            AddCigarSheet(prefillBrand: searchQuery) { cigar in
                // Sigaren er ny og privat. Strekkoden knyttes til den med det
                // samme, så neste skann treffer — også før forslaget er godkjent.
                saveLink(cigar: cigar)
            }
            .environmentObject(authService)
        }
    }

    // MARK: - Hjelpere

    private func resultRow(cigar: Cigar, selected: Bool) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(cigar.brand)
                    .font(.subheadline.bold())
                    .foregroundColor(Color(.label))
                if let series = cigar.series {
                    Text(series)
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                }
                if let vitola = cigar.vitola {
                    Text(vitola)
                        .font(.caption)
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
            Spacer()
            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color("Accent"))
                    .font(.system(size: 20))
            } else {
                Image(systemName: "circle")
                    .foregroundColor(Color(.tertiaryLabel))
                    .font(.system(size: 20))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func runSearch() {
        isSearching = true
        Task {
            defer { isSearching = false }
            do {
                searchResults = try await cigarService.searchCigars(query: searchQuery)
            } catch {
                searchResults = []
            }
        }
    }

    private func saveLink(cigar: Cigar) {
        isSaving   = true
        saveError  = nil
        Task {
            do {
                try await barcodeService.saveBarcode(barcode, cigarID: cigar.id, source: "user")
                onLinked(cigar)
            } catch {
                isSaving  = false
                saveError = "Kunne ikke lagre kobling — prøv igjen"
                print("saveBarcode feilet for \(barcode) → \(cigar.id): \(error)")
            }
        }
    }
}
